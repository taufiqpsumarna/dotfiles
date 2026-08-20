# dotfiles

Personal ZSH configuration for daily DevSecOps and coding work.
Designed for **Ubuntu / WSL2** with oh-my-zsh + Powerlevel10k.

---

## Quick Start

```bash
git clone https://github.com/taufiqpsumarna/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash bootstrap.sh
source ~/.zshrc
```

Run `bash bootstrap.sh --dry-run` first to preview what will be installed.

---

## What's Included

### `zshrc`
Full ZSH configuration covering:

| Section | Details |
|---|---|
| **Shell UX** | history-substring-search, fzf, colored-man-pages, autosuggestions, syntax-highlighting |
| **History** | 50k entries, shared across sessions, deduped, timestamped |
| **Completion** | Case-insensitive, menu-driven, colored, kill/process aware |
| **Listing** | `eza` with icons + git status (fallback to plain `ls`), `lt` tree view |
| **Git** | Aliases `g gs ga gaa gc gca gp gpl gl gds gsw gst` + `gli` fzf log browser |
| **Docker** | Aliases `d dps dpsa dlogs dexec dc dcu dcd` + `dclean dprune drun` helpers |
| **Kubernetes** | Aliases `k kg kd kgp kgpa kge ktop kaf kns` + `klogs kexec kwatch` functions |
| **Terraform** | Aliases `tf tfi tfp tfa tfaa tfd tfdaa tfv tff tfs tfo` + `tfws` workspace helper |
| **Ansible** | Aliases `ans ansp ansv ansl ansi` |
| **Security** | `sec-scan sec-secrets sec-dockerfile sec-git-history sec-deps sbom sec-iac sec-k8s sec-compose sec-fs sec-quick ssl-check` |
| **WSL2** | `pbcopy pbpaste exp cdwin`, Windows PATH integration |
| **Python** | `py pip venv activate` |
| **NVM** | Lazy-loaded (faster shell startup) |
| **Productivity** | `mkcd bak extract serve timer ducks myip ports reload` |

### `bootstrap.sh`
Installs every tool referenced in `zshrc`. Idempotent — safe to re-run.

**Installs:**
- System packages: `git curl jq vim zsh ripgrep fd-find bat direnv openssl iproute2`
- `fzf` (fuzzy finder)
- `eza` (modern `ls` with icons and git status)
- `kubectl` + `kubectx` + `kubens`
- `helm`
- `k9s` (Kubernetes TUI)
- `lazydocker` (Docker TUI)
- `dive` (Docker image layer analyzer)
- `terraform`
- `trivy` (vuln/secret/IaC scanner — replaces tfsec)
- `hadolint` (Dockerfile linter)
- `trufflehog` (secret scanner — replaces gitleaks)
- `checkov` (IaC security scanner)
- `kube-score` (Kubernetes manifest linter)
- `gh` (GitHub CLI) + `glab` (GitLab CLI)
- `aws-cli` + `gcloud` CLI
- `ansible`
- `nvm` + Node LTS
- `oh-my-zsh` + plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`)
- `powerlevel10k`

---

## Key Keybindings

| Shortcut | Action |
|---|---|
| `Ctrl+R` | fzf fuzzy history search |
| `Ctrl+T` | fzf file picker |
| `Ctrl+F` | fzf file widget |
| `Alt+C` | fzf cd to directory |
| `UP / DOWN` | History search by prefix |
| `ESC ESC` | Prepend `sudo` to last command |

---

## Security Functions Quick Reference

```bash
sec-scan nginx:latest        # Trivy vuln scan (MEDIUM+, --ignore-unfixed)
sec-scan ./myapp             # Trivy fs scan
sec-secrets                  # Trivy secret + config scan (current dir)
sec-dockerfile Dockerfile    # hadolint lint
sec-git-history              # trufflehog git history scan
sec-deps                     # Audit pip/npm/gem deps (--ignore-unfixed)
sbom nginx:latest            # Generate CycloneDX SBOM
sec-iac                      # trivy config + checkov + kube-score
sec-k8s ./manifests          # Scan k8s manifests (trivy + kube-score)
sec-compose                  # Scan docker-compose.yml
sec-fs                       # Trivy combined vuln + secret + misconfig scan
sec-quick                    # One-shot security posture check on current dir
ssl-check example.com        # TLS certificate details
ports                        # Show listening ports
```

> **Note:** All trivy-based scans use `--ignore-unfixed` to suppress noise from vulnerabilities without available patches.

---

## Tools Not Auto-Installed

Some tools require manual setup or are environment-specific:

| Tool | Install |
|---|---|
| VS Code (WSL) | Install [VS Code](https://code.visualstudio.com/) on Windows + WSL extension |

---

## Manual Steps After Bootstrap

```bash
# 1. Configure Powerlevel10k prompt
p10k configure

# 2. Install Node LTS
nvm install --lts
nvm alias default lts/*

# 3. Authenticate GitHub CLI
gh auth login

# 4. Configure AWS CLI
aws configure

# 5. Log into a k8s cluster
# (copy kubeconfig or use cloud provider CLI)
```

---

## File Structure

```
dotfiles/
├── CLAUDE.md      → project instructions for AI agents
├── zshrc          → ~/.zshrc
├── p10k.zsh       → ~/.p10k.zsh
├── bootstrap.sh   → install all tools
└── README.md
```

---

## Updating

```bash
cd ~/dotfiles
# Edit zshrc here; symlink makes edits live immediately.
source ~/.zshrc
git add -A && git commit -m "update zshrc"
```
