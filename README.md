# dotfiles

Personal ZSH configuration for daily DevSecOps and coding work.
Designed for **Ubuntu / WSL2** with oh-my-zsh + Powerlevel10k.

---

## Quick Start

```bash
git clone https://github.com/yuurei/dotfiles.git ~/dotfiles
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
| **Git** | Aliases `g gs ga gaa gc gca gp gpl gl gds gsw gst` + `gli` fzf log browser |
| **Docker** | Aliases `d dps dpsa dlogs dexec dc dcu dcd` + `dclean dprune drun` helpers |
| **Kubernetes** | Aliases `k kg kd kgp kgpa kge ktop kaf kns` + `klogs kexec kwatch` functions |
| **Terraform** | Aliases `tf tfi tfp tfa tfaa tfd tfdaa tfv tff tfs tfo` + `tfws` workspace helper |
| **Security** | `sec-scan sec-secrets sec-dockerfile sec-git-history sec-deps sbom sec-iac ssl-check` |
| **WSL2** | `pbcopy pbpaste exp cdwin`, Windows PATH integration |
| **Python** | `py pip venv activate` |
| **NVM** | Lazy-loaded (faster shell startup) |
| **Productivity** | `mkcd bak extract serve timer ducks myip ports reload` |

### `bootstrap.sh`
Installs every tool referenced in `zshrc`. Idempotent — safe to re-run.

**Installs:**
- System packages: `git curl jq vim zsh ripgrep fd-find bat direnv openssl iproute2`
- `fzf` (fuzzy finder)
- `eza` (modern `ls`)
- `kubectl` + `kubectx` + `kubens`
- `helm`
- `terraform`
- `trivy` (vuln/secret/IaC scanner)
- `hadolint` (Dockerfile linter)
- `gitleaks` (git secret scanner)
- `tfsec` (Terraform security scanner)
- `checkov` (IaC security scanner)
- `gh` (GitHub CLI)
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
sec-scan nginx:latest        # Trivy vuln scan (MEDIUM+)
sec-scan ./myapp             # Trivy fs scan
sec-secrets                  # Trivy secret + config scan (current dir)
sec-dockerfile Dockerfile    # hadolint lint
sec-git-history              # gitleaks git history scan
sec-deps                     # Audit pip/npm/gem deps
sbom nginx:latest            # Generate CycloneDX SBOM
sec-iac                      # tfsec + checkov + kube-score
ssl-check example.com        # TLS certificate details
ports                        # Show listening ports
```

---

## Tools Not Auto-Installed

Some tools require manual setup or are environment-specific:

| Tool | Install |
|---|---|
| `kube-score` | `curl -fsSL https://github.com/zegl/kube-score/releases/latest/download/kube-score_linux_amd64.tar.gz \| tar -xz -C ~/.local/bin` |
| AWS CLI | `curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/aws.zip && unzip /tmp/aws.zip -d /tmp && sudo /tmp/aws/install` |
| Google Cloud SDK | `curl https://sdk.cloud.google.com \| bash` |
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
├── zshrc          → ~/.zshrc
├── bootstrap.sh   → install all tools
└── README.md
```

---

## Updating

```bash
cd ~/dotfiles
# Edit zshrc here, then sync back to home:
cp ~/dotfiles/zshrc ~/.zshrc
# Or if using symlink (bootstrap.sh default), edits are live immediately.
source ~/.zshrc
git add -A && git commit -m "update zshrc"
```
