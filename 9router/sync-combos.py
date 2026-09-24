#!/usr/bin/env python3
"""
Sync 3-Tier Combos to 9Router

Prioritizes:
- Tier 1: Subscription providers (CC first, then AG premium) to maximize ROI.
- Tier 2: Cheap providers (AG Gemini Flash, GPT-OSS) when subscriptions exhausted.
- Tier 3: Free providers (OpenCode Free, Mimo Free) — round-robin for load balance.
- paid-tier: Full cascade Tier 1 -> Tier 2 -> Tier 3.

Also configures:
- Vision Adapter: round-robin across CC + AG vision-capable models.
"""

import hashlib
import json
import os
import sys
import urllib.request
import urllib.error

DEFAULT_PORT = 20128
HOST = "localhost"

# Target combo definitions:
# - paid-tier: Unified cascade (Tier 1: CC -> CU -> AG, Tier 2: Cheap AG, Tier 3: Free OC/MMF) using fallback.
# - free-tier: Round-robin load-balanced pool across free models.
PAID_TIER_MODELS = [
    # Tier 1: Subscriptions (CC first -> CU second -> AG third)
    "cc/claude-sonnet-5",
    "cc/claude-opus-5",
    "cc/claude-fable-5-1",
    "cc/claude-fable-5",
    "cu/default",
    "ag/claude-sonnet-4-6",
    "ag/claude-opus-4-6-thinking",
    # Tier 2: Cheap (Fast / Low-cost AG)
    "ag/gemini-3.8-flash-high",
    "ag/gemini-3.8-flash",
    "ag/gemini-3.7-flash-high",
    "ag/gemini-3.6-flash-high",
    "ag/gpt-oss-120b-medium",
    "ag/gemini-3.7-flash-low",
    # Tier 3: Free (Zero-downtime safety net)
    "oc/deepseek-v4-flash-free",
    "oc/nemotron-3-ultra-free",
    "mmf/mimo-auto",
    "oc/ling-3.0-flash-free",
    "oc/big-pickle",
    "oc/mimo-v2.5-free",
]

FREE_TIER_MODELS = [
    "oc/deepseek-v4-flash-free",
    "oc/nemotron-3-ultra-free",
    "mmf/mimo-auto",
    "oc/ling-3.0-flash-free",
    "oc/big-pickle",
    "oc/mimo-v2.5-free",
    "oc/ling-3.0-tiny-free",
    "oc/muse-spark-1.2-contributor-free",
]

TARGET_COMBOS = {
    "paid-tier": {
        "models": PAID_TIER_MODELS,
        "kind": None,
    },
    "free-tier": {
        "models": FREE_TIER_MODELS,
        "kind": None,
    },
}

# Combos that should be removed if present
OBSOLETE_COMBOS = {
    "devsecops-router",
    "tier1-subscription",
    "tier2-cheap",
    "tier3-free",
}

COMBO_STRATEGIES = {
    "free-tier": {"fallbackStrategy": "round-robin"},
    "paid-tier": {"fallbackStrategy": "fallback"},
}

# Vision Adapter: round-robin across vision-capable models (CC first, then CU, then AG).
VISION_ADAPTER = {
    "vision": {
        "enabled": True,
        "roundRobin": True,
        "models": [
            "cc/claude-sonnet-5",
            "cc/claude-opus-5",
            "cc/claude-fable-5-1",
            "cc/claude-fable-5",
            "cu/claude-4.6-sonnet-medium-thinking",
            "cu/claude-4.5-sonnet",
            "ag/gemini-3.8-flash-high",
            "ag/gemini-3.7-flash-high",
            "ag/claude-sonnet-4-6",
            "ag/claude-opus-4-6-thinking",
        ],
    },
    "audioInput": {"enabled": False, "roundRobin": False, "models": []},
}


def get_data_dir():
    if "DATA_DIR" in os.environ:
        return os.environ["DATA_DIR"]
    return os.path.expanduser("~/.9router")


def get_cli_token():
    data_dir = get_data_dir()
    machine_id_file = os.path.join(data_dir, "machine-id")
    cli_secret_file = os.path.join(data_dir, "auth", "cli-secret")

    with open(machine_id_file, "r") as f:
        raw_machine_id = f.read().strip()

    with open(cli_secret_file, "r") as f:
        cli_secret = f.read().strip()

    salt = "9r-cli-auth"
    token = (
        hashlib.sha256((raw_machine_id + salt + cli_secret).encode("utf-8"))
        .hexdigest()[:16]
    )
    return token


def make_api_call(method, path, body=None, token=None):
    url = f"http://{HOST}:{DEFAULT_PORT}{path}"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["x-9r-cli-token"] = token

    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req) as resp:
            resp_body = resp.read().decode("utf-8")
            return resp.status, json.loads(resp_body) if resp_body else {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            parsed = json.loads(err_body)
            return e.code, parsed
        except Exception:
            return e.code, {"error": err_body}


def sync_combos(token):
    status, resp = make_api_call("GET", "/api/combos", token=token)
    if status != 200:
        print(f"Error fetching combos: HTTP {status} {resp}", file=sys.stderr)
        sys.exit(1)

    existing_combos = {c["name"]: c for c in resp.get("combos", [])}
    print(f"Found {len(existing_combos)} existing combos in 9Router.")

    changes = 0

    # Clean up obsolete combos
    for obs_name in OBSOLETE_COMBOS:
        if obs_name in existing_combos:
            combo_id = existing_combos[obs_name]["id"]
            print(f"[DELETE] Obsolete combo '{obs_name}' ({combo_id}). Deleting...")
            del_status, del_resp = make_api_call(
                "DELETE", f"/api/combos/{combo_id}", token=token,
            )
            if del_status in (200, 204) or del_resp.get("success"):
                print(f"  -> Deleted combo '{obs_name}'.")
                changes += 1
                del existing_combos[obs_name]
            else:
                print(f"  -> Failed to delete '{obs_name}': {del_resp}", file=sys.stderr)

    for name, spec in TARGET_COMBOS.items():
        models = spec["models"]
        kind = spec["kind"]
        payload = {"name": name, "models": models}
        if kind:
            payload["kind"] = kind

        if name in existing_combos:
            current = existing_combos[name]
            current_models = current.get("models", [])
            current_kind = current.get("kind")
            if current_models == models and current_kind == kind:
                print(f"[OK] Combo '{name}' already matches target definition.")
            else:
                print(f"[UPDATE] Combo '{name}' changed. Updating...")
                put_status, put_resp = make_api_call(
                    "PUT", f"/api/combos/{current['id']}", payload, token=token,
                )
                if put_status in (200, 204) or put_resp.get("success"):
                    print(f"  -> Updated combo '{name}'.")
                    changes += 1
                else:
                    print(f"  -> Failed: {put_resp}", file=sys.stderr)
        else:
            print(f"[CREATE] Combo '{name}'. Creating...")
            post_status, post_resp = make_api_call(
                "POST", "/api/combos", payload, token=token,
            )
            if post_status in (200, 201) or post_resp.get("success"):
                print(f"  -> Created combo '{name}'.")
                changes += 1
            else:
                print(f"  -> Failed: {post_resp}", file=sys.stderr)

    print(f"\nCombo sync: {changes} combo(s) created, updated, or removed.")
    return changes


def sync_combo_strategies(token):
    status, resp = make_api_call("GET", "/api/settings", token=token)
    if status != 200:
        print(f"Error fetching settings: HTTP {status} {resp}", file=sys.stderr)
        return 0

    current = resp.get("comboStrategies", {})
    # Check if COMBO_STRATEGIES are present
    needs_update = False
    updated_strategies = dict(current)
    # Remove obsolete combos from comboStrategies
    for obs in OBSOLETE_COMBOS:
        if obs in updated_strategies:
            del updated_strategies[obs]
            needs_update = True

    for name, strat in COMBO_STRATEGIES.items():
        if updated_strategies.get(name) != strat:
            updated_strategies[name] = strat
            needs_update = True

    if not needs_update:
        print("[OK] Combo strategies already match target.")
        return 0

    print("[UPDATE] Combo strategies changed. Updating...")
    patch_status, patch_resp = make_api_call(
        "PATCH", "/api/settings", {"comboStrategies": updated_strategies}, token=token,
    )
    if patch_status == 200:
        print("  -> Combo strategies updated.")
        return 1

    print(f"  -> Failed: {patch_resp}", file=sys.stderr)
    return 0


def sync_vision_adapter(token):
    status, resp = make_api_call("GET", "/api/settings", token=token)
    if status != 200:
        print(f"Error fetching settings: HTTP {status} {resp}", file=sys.stderr)
        return 0

    current = resp.get("capacityAdapter", {})
    if current == VISION_ADAPTER:
        print("[OK] Vision adapter already matches target.")
        return 0

    print("[UPDATE] Vision adapter models changed. Updating...")
    patch_status, patch_resp = make_api_call(
        "PATCH", "/api/settings", {"capacityAdapter": VISION_ADAPTER}, token=token,
    )
    if patch_status == 200:
        print("  -> Vision adapter updated.")
        return 1

    print(f"  -> Failed: {patch_resp}", file=sys.stderr)
    return 0


def main():
    token = get_cli_token()
    print("Obtained 9Router CLI token.\n")

    combo_changes = sync_combos(token)

    print()
    strat_changes = sync_combo_strategies(token)

    print()
    vision_changes = sync_vision_adapter(token)

    total = combo_changes + strat_changes + vision_changes
    print(f"\nSync complete: {total} total change(s).")


if __name__ == "__main__":
    main()
