#!/usr/bin/env bash
# ==============================================================================
# DevSecOps Toolchain Bootstrap
# Installs all tools referenced in ~/.zshrc on Ubuntu/Debian (WSL2 compatible)
# Usage: bash bootstrap.sh [--dry-run]
# ==============================================================================

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[SKIP]${NC} $*"; }
err()     { echo -e "${RED}[ERR]${NC}  $*"; }

run() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    eval "$@"
  fi
}

installed() { command -v "$1" &>/dev/null; }

latest_github_release() {
  # $1 = owner/repo  → prints latest tag like v1.2.3
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/'
}

echo ""
echo "======================================================"
echo "  DevSecOps Toolchain Bootstrap"
echo "======================================================"
echo ""

# ------------------------------------------------------------------------------
# APT packages
# ------------------------------------------------------------------------------
APT_PACKAGES=(
  git curl wget unzip jq # git: version control
  zsh              # zsh: shell
  vim              # vim: text editor
  build-essential  # build-essential: essential build tools
  htop             # interactive process viewer
  direnv           # per-directory env loading
  ripgrep          # rg: fast grep
  fd-find          # fd: fast find
  bat              # batcat: syntax-highlighted cat
  openssl          # ssl-check function
  net-tools        # netstat for ports() fallback
  iproute2         # ss for ports()
  dnsutils         # dnsutils: DNS lookup utilities
  netcat-openbsd   # netcat-openbsd: TCP/IP swiss army knife
  python3          # python3: Python 3 interpreter
  python3-pip      # python3-pip: Python package installer
  python3-venv     # python3-venv: Python virtual environment
)

info "Installing APT packages..."
if ! $DRY_RUN; then
  sudo apt-get update -qq
  sudo apt-get install -y "${APT_PACKAGES[@]}" 2>&1 | grep -E "^(Setting up|Unpacking|Get:)" || true
  sudo curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Symlink batcat → bat if needed
if installed batcat && ! installed bat; then
  run "ln -sf $(which batcat) $LOCAL_BIN/bat"
  success "bat symlinked"
fi

# Symlink fdfind → fd if needed
if installed fdfind && ! installed fd; then
  run "ln -sf $(which fdfind) $LOCAL_BIN/fd"
  success "fd symlinked"
fi

# ------------------------------------------------------------------------------
# kubectl
# ------------------------------------------------------------------------------
if installed kubectl; then
  warn "kubectl already installed ($(kubectl version --client --short 2>/dev/null | head -1))"
else
  info "Installing kubectl..."
  KUBE_VER=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  run "curl -fsSL 'https://dl.k8s.io/release/${KUBE_VER}/bin/linux/amd64/kubectl' -o $LOCAL_BIN/kubectl"
  run "chmod +x $LOCAL_BIN/kubectl"
  success "kubectl ${KUBE_VER} installed"
fi

# ------------------------------------------------------------------------------
# kubectx + kubens
# ------------------------------------------------------------------------------
if installed kubectx; then
  warn "kubectx already installed"
else
  info "Installing kubectx + kubens..."
  KUBECTX_VER=$(latest_github_release "ahmetb/kubectx")
  run "curl -fsSL 'https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VER}/kubectx_${KUBECTX_VER}_linux_x86_64.tar.gz' | tar -xz -C $LOCAL_BIN kubectx"
  run "curl -fsSL 'https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VER}/kubens_${KUBECTX_VER}_linux_x86_64.tar.gz' | tar -xz -C $LOCAL_BIN kubens"
  run "chmod +x $LOCAL_BIN/kubectx $LOCAL_BIN/kubens"
  success "kubectx + kubens ${KUBECTX_VER} installed"
fi

# ------------------------------------------------------------------------------
# helm
# ------------------------------------------------------------------------------
if installed helm; then
  warn "helm already installed ($(helm version --short 2>/dev/null))"
else
  info "Installing helm..."
  run "curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
  success "helm installed"
fi

# ------------------------------------------------------------------------------
# terraform
# ------------------------------------------------------------------------------
if installed terraform; then
  warn "terraform already installed ($(terraform version -json 2>/dev/null | jq -r .terraform_version 2>/dev/null || terraform version | head -1))"
else
  info "Installing terraform..."
  TF_VER=$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)
  run "curl -fsSL 'https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip' -o /tmp/terraform.zip"
  run "unzip -o /tmp/terraform.zip -d $LOCAL_BIN"
  run "chmod +x $LOCAL_BIN/terraform"
  run "rm -f /tmp/terraform.zip"
  success "terraform ${TF_VER} installed"
fi

# ------------------------------------------------------------------------------
# trivy (vuln/secret/IaC scanner)
# ------------------------------------------------------------------------------
if installed trivy; then
  warn "trivy already installed ($(trivy --version 2>/dev/null | head -1))"
else
  info "Installing trivy..."
  run "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b $LOCAL_BIN"
  success "trivy installed"
fi

# ------------------------------------------------------------------------------
# hadolint (Dockerfile linter)
# ------------------------------------------------------------------------------
if installed hadolint; then
  warn "hadolint already installed"
else
  info "Installing hadolint..."
  HADOLINT_VER=$(latest_github_release "hadolint/hadolint")
  run "curl -fsSL 'https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VER}/hadolint-Linux-x86_64' -o $LOCAL_BIN/hadolint"
  run "chmod +x $LOCAL_BIN/hadolint"
  success "hadolint ${HADOLINT_VER} installed"
fi

# ------------------------------------------------------------------------------
# gitleaks (git secret scanner)
# ------------------------------------------------------------------------------
if installed gitleaks; then
  warn "gitleaks already installed"
else
  info "Installing gitleaks..."
  GL_VER=$(latest_github_release "gitleaks/gitleaks")
  GL_VER_NUM="${GL_VER#v}"
  run "curl -fsSL 'https://github.com/gitleaks/gitleaks/releases/download/${GL_VER}/gitleaks_${GL_VER_NUM}_linux_x64.tar.gz' | tar -xz -C $LOCAL_BIN gitleaks"
  run "chmod +x $LOCAL_BIN/gitleaks"
  success "gitleaks ${GL_VER} installed"
fi

# ------------------------------------------------------------------------------
# GitHub CLI (gh)
# ------------------------------------------------------------------------------
if installed gh; then
  warn "gh already installed ($(gh --version | head -1))"
else
  info "Installing GitHub CLI..."
  GH_VER=$(latest_github_release "cli/cli")
  GH_VER_NUM="${GH_VER#v}"
  run "curl -fsSL 'https://github.com/cli/cli/releases/download/${GH_VER}/gh_${GH_VER_NUM}_linux_amd64.tar.gz' | tar -xz -C /tmp"
  run "mv /tmp/gh_${GH_VER_NUM}_linux_amd64/bin/gh $LOCAL_BIN/gh"
  run "chmod +x $LOCAL_BIN/gh"
  run "rm -rf /tmp/gh_${GH_VER_NUM}_linux_amd64"
  success "gh ${GH_VER} installed"
fi

# ------------------------------------------------------------------------------
# glab-cli (Gitlab CLI for GitLab)
# ------------------------------------------------------------------------------
if installed glab; then
  warn "glab already installed"
else
  info "Installing glab..."
  wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg > /dev/null
  echo "deb [arch=all,$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
  sudo apt update
  sudo apt install glab
  success "glab installed"
fi

# ------------------------------------------------------------------------------
# ansible
# ------------------------------------------------------------------------------
if installed ansible; then
  warn "ansible already installed"
else
  info "Installing ansible..."
  run "uv install --quiet ansible"
  success "ansible installed"
fi

# ------------------------------------------------------------------------------
# nvm
# ------------------------------------------------------------------------------
if [[ -d "$HOME/.nvm" ]]; then
  warn "nvm already installed"
else
  info "Installing nvm..."
  NVM_VER=$(latest_github_release "nvm-sh/nvm")
  run "curl -o- 'https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VER}/install.sh' | bash"
  success "nvm ${NVM_VER} installed"
fi

# ------------------------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------------------------
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  warn "oh-my-zsh already installed"
else
  info "Installing oh-my-zsh..."
  run "RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  success "oh-my-zsh installed"
fi

# ------------------------------------------------------------------------------
# OMZ custom plugins: zsh-autosuggestions + zsh-syntax-highlighting
# ------------------------------------------------------------------------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  warn "zsh-autosuggestions already installed"
else
  info "Installing zsh-autosuggestions..."
  run "git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions"
  success "zsh-autosuggestions installed"
fi

if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  warn "zsh-syntax-highlighting already installed"
else
  info "Installing zsh-syntax-highlighting..."
  run "git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  success "zsh-syntax-highlighting installed"
fi

# ------------------------------------------------------------------------------
# Powerlevel10k
# ------------------------------------------------------------------------------
if [[ -d "$HOME/powerlevel10k" ]]; then
  warn "powerlevel10k already installed"
else
  info "Installing powerlevel10k..."
  run "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/powerlevel10k"
  success "powerlevel10k installed"
fi

# ------------------------------------------------------------------------------
# Symlink dotfiles
# ------------------------------------------------------------------------------
info "Symlinking dotfiles..."
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link_file() {
  local src="$DOTFILES_DIR/$1"
  local dst="$HOME/.$2"
  if [[ -f "$src" ]]; then
    if [[ -f "$dst" && ! -L "$dst" ]]; then
      run "mv '$dst' '${dst}.bak.$(date +%Y%m%d_%H%M%S)'"
      warn "Backed up existing $dst"
    fi
    run "ln -sf '$src' '$dst'"
    success "Linked $src → $dst"
  fi
}

link_file zshrc zshrc

# ------------------------------------------------------------------------------
# Set zsh as default shell
# ------------------------------------------------------------------------------
if [[ "$SHELL" != "$(which zsh)" ]]; then
  info "Setting zsh as default shell..."
  run "chsh -s $(which zsh)"
  success "Default shell changed to zsh (re-login to take effect)"
else
  warn "zsh is already the default shell"
fi

# ------------------------------------------------------------------------------
# Done
# ------------------------------------------------------------------------------
echo ""
echo "======================================================"
echo -e "  ${GREEN}Bootstrap complete!${NC}"
echo "======================================================"
echo ""
echo "Next steps:"
echo "  1. source ~/.zshrc   (or open a new terminal)"
echo "  2. p10k configure    (configure your prompt)"
echo "  3. nvm install --lts (install latest Node LTS)"
echo ""
