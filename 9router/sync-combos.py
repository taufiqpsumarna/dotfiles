#!/usr/bin/env python3
"""
Sync 3-Tier Combos to 9Router

Prioritizes:
- Tier 1: Subscription providers (CC first, then AG premium) to maximize ROI.
- Tier 2: Cheap providers (AG Gemini Flash, GPT-OSS) when subscriptions exhausted.
- Tier 3: Free providers (OpenCode Free, Mimo Free) as zero-downtime safety net.
- devsecops-router: Full cascade Tier 1 -> Tier 2 -> Tier 3.
- paid-tier: Maintained identical to devsecops-router for backward compatibility.
"""

import hashlib
import json
import os
import sys
import urllib.request
import urllib.error

DEFAULT_PORT = 20128
HOST = "localhost"

# Target combo definitions
TARGET_COMBOS = {
    "tier1-subscription": [
        "cc/claude-sonnet-5",
        "cc/claude-opus-5",
        "cc/claude-fable-5-1",
        "cc/claude-fable-5",
        "ag/claude-sonnet-4-6",
        "ag/claude-opus-4-6-thinking",
    ],
    "tier2-cheap": [
        "ag/gemini-3.8-flash-high",
        "ag/gemini-3.8-flash",
        "ag/gemini-3.7-flash-high",
        "ag/gemini-3.6-flash-high",
        "ag/gpt-oss-120b-medium",
        "ag/gemini-3.7-flash-low",
    ],
    "tier3-free": [
        "oc/deepseek-v4-flash-free",
        "oc/nemotron-3-ultra-free",
        "mmf/mimo-auto",
        "oc/ling-3.0-flash-free",
        "oc/big-pickle",
        "oc/mimo-v2.5-free",
    ],
    "devsecops-router": [
        "cc/claude-sonnet-5",
        "cc/claude-opus-5",
        "cc/claude-fable-5-1",
        "cc/claude-fable-5",
        "ag/claude-sonnet-4-6",
        "ag/claude-opus-4-6-thinking",
        "tier2-cheap",
        "tier3-free",
    ],
    "paid-tier": [
        "cc/claude-sonnet-5",
        "cc/claude-opus-5",
        "cc/claude-fable-5-1",
        "cc/claude-fable-5",
        "ag/claude-sonnet-4-6",
        "ag/claude-opus-4-6-thinking",
        "tier2-cheap",
        "tier3-free",
    ],
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
    headers = {
        "Content-Type": "application/json",
    }
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


def sync_combos():
    token = get_cli_token()
    print("Obtained 9Router CLI token.")

    status, resp = make_api_call("GET", "/api/combos", token=token)
    if status != 200:
        print(f"Error fetching combos: HTTP {status} {resp}", file=sys.stderr)
        sys.exit(1)

    existing_combos = {c["name"]: c for c in resp.get("combos", [])}
    print(f"Found {len(existing_combos)} existing combos in 9Router.")

    changes = 0

    for name, models in TARGET_COMBOS.items():
        if name in existing_combos:
            current = existing_combos[name]
            current_models = current.get("models", [])
            if current_models == models:
                print(f"[OK] Combo '{name}' already matches target definition.")
            else:
                print(f"[UPDATE] Combo '{name}' models changed. Updating...")
                put_status, put_resp = make_api_call(
                    "PUT",
                    f"/api/combos/{current['id']}",
                    {"name": name, "models": models},
                    token=token,
                )
                if put_status in (200, 204) or put_resp.get("success"):
                    print(f"  -> Successfully updated combo '{name}'.")
                    changes += 1
                else:
                    print(f"  -> Failed to update '{name}': {put_resp}", file=sys.stderr)
        else:
            print(f"[CREATE] Combo '{name}' does not exist. Creating...")
            post_status, post_resp = make_api_call(
                "POST",
                "/api/combos",
                {"name": name, "models": models},
                token=token,
            )
            if post_status in (200, 201) or post_resp.get("success"):
                print(f"  -> Successfully created combo '{name}'.")
                changes += 1
            else:
                print(f"  -> Failed to create '{name}': {post_resp}", file=sys.stderr)

    print(f"\nSync complete: {changes} combo(s) created or updated.")


if __name__ == "__main__":
    sync_combos()
