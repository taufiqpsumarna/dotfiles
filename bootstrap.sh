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
  software-properties-common  # software-properties-common
  build-essential procps curl file git # Brew
  git curl wget zip unzip jq # git: version control
  fzf              # fzf: A command-line fuzzy finder
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
  sudo apt-get update
  sudo apt-get install -y "${APT_PACKAGES[@]}" 2>&1 | grep -E "^(Setting up|Unpacking|Get:)" || true
fi

# ------------------------------------------------------------------------------
# Homebrew for Linux
# ------------------------------------------------------------------------------
BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
if installed brew || [[ -x "$BREW_BIN" ]]; then
  warn "Homebrew already installed"
else
  info "Installing Homebrew..."
  run "NONINTERACTIVE=1 /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
  success "Homebrew installed"
fi

if [[ -x "$BREW_BIN" ]]; then
  eval "$($BREW_BIN shellenv)"
  for shell_rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if ! grep -Fq 'linuxbrew/.linuxbrew/bin/brew shellenv' "$shell_rc" 2>/dev/null; then
      printf '%s\n' 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$shell_rc"
    fi
  done
fi

# ------------------------------------------------------------------------------
# uv (Python package and project manager)
# ------------------------------------------------------------------------------
if installed uv; then
  warn "uv already installed ($(uv --version 2>/dev/null))"
else
  info "Installing uv..."
  run "curl -LsSf https://astral.sh/uv/install.sh | sh"
  export PATH="$LOCAL_BIN:$PATH"
  success "uv installed"
fi

# -----------------------------------------------------------------------------
# aws-cli
# ------------------------------------------------------------------------------
if installed aws; then
  warn "aws already installed ($(aws --version 2>/dev/null | head -1))"
else
  info "Installing aws-cli..."
  curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash
  success "aws-cli installed"
fi

# ------------------------------------------------------------------------------
# gcloud
# ------------------------------------------------------------------------------
if installed gcloud; then
  warn "gcloud already installed ($(gcloud version 2>/dev/null | head -1))"
else
  info "Installing gcloud..."
  sudo apt-get install apt-transport-https ca-certificates gnupg curl -y && \
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
  sudo apt-get update -y && sudo apt-get install google-cloud-cli -y
  gcloud components install gke-gcloud-auth-plugin
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
# LazyDocker
# ------------------------------------------------------------------------------

if installed lazydocker; then
  warn "lazydocker already installed"
else
  info "Installing lazydocker..."
  run "curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
  success "lazydocker installed"
fi

# ------------------------------------------------------------------------------
# helm
# ------------------------------------------------------------------------------
if installed helm; then
  warn "helm already installed ($(helm version --short 2>/dev/null))"
else
  info "Installing helm..."
  run "curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash"
  success "helm installed"
fi

# ------------------------------------------------------------------------------
# dive
# ------------------------------------------------------------------------------
if installed dive; then
  warn "dive already installed"
else
  info "Installing dive..."
  DIVE_VERSION=$(curl -sL "https://api.github.com/repos/wagoodman/dive/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
  sudo curl -fOL "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb"
  sudo apt install ./dive_${DIVE_VERSION}_linux_amd64.deb
  sudo rm -f ./dive_${DIVE_VERSION}_linux_amd64.deb
fi

# ------------------------------------------------------------------------------
# k9s
# ------------------------------------------------------------------------------
if installed k9s; then
  warn "k9s already installed k9s ($(k9s version))"
else
  info "Installing k9s..."
  curl -sS https://webi.sh/k9s | sh;
  success "k9s installed"
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
# trufflehog (secret scanner)
# ------------------------------------------------------------------------------
if installed trufflehog; then
  warn "trufflehog already installed"
else
  info "Installing trufflehog..."
  run "curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b $LOCAL_BIN"
  success "trufflehog installed"
fi

# ------------------------------------------------------------------------------
# kube-score (Kubernetes manifest linter)
# ------------------------------------------------------------------------------
if installed kube-score; then
  warn "kube-score already installed"
else
  info "Installing kube-score..."
  KS_VER=$(latest_github_release "zegl/kube-score")
  KS_VER_NUM="${KS_VER#v}"
  run "curl -fsSL 'https://github.com/zegl/kube-score/releases/download/${KS_VER}/kube-score_${KS_VER_NUM}_linux_amd64.tar.gz' | tar -xz -C $LOCAL_BIN kube-score"
  run "chmod +x $LOCAL_BIN/kube-score"
  success "kube-score ${KS_VER} installed"
fi

# ------------------------------------------------------------------------------
# eza (modern ls replacement)
# ------------------------------------------------------------------------------
if installed eza; then
  warn "eza already installed"
else
  info "Installing eza..."
  EZA_VER=$(latest_github_release "eza-community/eza")
  EZA_VER_NUM="${EZA_VER#v}"
  run "curl -fsSL 'https://github.com/eza-community/eza/releases/download/${EZA_VER}/eza_x86_64-unknown-linux-gnu.tar.gz' | tar -xz -C $LOCAL_BIN"
  run "chmod +x $LOCAL_BIN/eza"
  success "eza ${EZA_VER} installed"
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
  brew install glab
fi

# ------------------------------------------------------------------------------
# ansible
# ------------------------------------------------------------------------------
if installed ansible; then
  warn "ansible already installed ($(ansible --version))"
else
  info "Installing ansible..."
  sudo add-apt-repository --yes --update ppa:ansible/ansible
  sudo apt install -y ansible
  success "ansible installed"
fi

# ------------------------------------------------------------------------------
# nvm
# ------------------------------------------------------------------------------
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
NVM_SYSTEM_DIR="/usr/local/share/nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" && -s "$NVM_SYSTEM_DIR/nvm.sh" ]]; then
  NVM_DIR="$NVM_SYSTEM_DIR"
fi
export NVM_DIR

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  warn "nvm already installed"
else
  info "Installing nvm..."
  NVM_VER=$(latest_github_release "nvm-sh/nvm")
  run "curl -o- 'https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VER}/install.sh' | bash"
fi

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # nvm is a shell function, so load it into this bootstrap process.
  . "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"
else
  err "nvm installation did not create $NVM_DIR/nvm.sh"
  exit 1
fi

# nvm's shell implementation is not compatible with Bash nounset mode.
set +u
nvm install --lts
nvm use --lts
set -u
success "nvm available with $(node -v) and $(npm -v)"

# ------------------------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------------------------
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  warn "oh-my-zsh already installed"
else
  info "Installing oh-my-zsh..."
  run "RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  success "oh-my-zsh installed with powerlevel10k theme"
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
link_file p10k.zsh p10k.zsh

# ------------------------------------------------------------------------------
# Set zsh as default shell
# ------------------------------------------------------------------------------
ZSH_PATH="$(command -v zsh)"
LOGIN_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [[ "$LOGIN_SHELL" != "$ZSH_PATH" ]]; then
  if [[ "${CODESPACES:-false}" == "true" && "${BOOTSTRAP_CHANGE_SHELL:-false}" != "true" ]]; then
    warn "Skipping default shell change in Codespaces"
  elif $DRY_RUN; then
    run "chsh -s '$ZSH_PATH' '$USER'"
  elif chsh -s "$ZSH_PATH" "$USER"; then
    success "Default shell changed to zsh (re-login to take effect)"
  else
    warn "Could not change the default shell; run 'chsh -s $ZSH_PATH' manually"
  fi
else
  warn "zsh is already the default shell"
fi

# ------------------------------------------------------------------------------
# Zed Editor
# ------------------------------------------------------------------------------
if installed zed; then
  warn "zed already installed"
else
  info "Installing Zed..."
  run "curl -f https://zed.dev/install.sh | sh"
  success "zed installed"
fi

# ------------------------------------------------------------------------------
# Agentic CLI
# ------------------------------------------------------------------------------
export NPM_CONFIG_ALLOW_GIT=all
curl -fsSL https://herdr.dev/install.sh | sh
curl -fsSL https://jcode.sh/install | bash
curl -fsSL https://claude.ai/install.sh | bash
curl -fsSL https://opencode.ai/install | bash
curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | bash && rtk init --global
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash

# ------------------------------------------------------------------------------
# Agent Skills
# ------------------------------------------------------------------------------
npx skills add getsentry/skills --skill security-review -g
npx skills add https://github.com/vercel-labs/skills --skill find-skills -g
npx skills add https://github.com/openai/skills --skill security-best-practices -g
npx skills add google/skills -g
npx skills add https://github.com/jeffallan/claude-skills --skill devops-engineer -g
npx skills add https://github.com/jeffallan/claude-skills --skill cloud-architect -g


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
