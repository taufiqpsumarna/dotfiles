# ==============================================================================
# Powerlevel10k Instant Prompt — must stay near top
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# Path & Core Exports
# ==============================================================================
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
export EDITOR="vim"
export VISUAL="vim"
export PAGER="less"
export LESS="-R --quit-if-one-screen"
export MANPAGER="less -X"

# Colorize terminal output
export TERM="xterm-256color"
export CLICOLOR=1

# ==============================================================================
# Oh-My-Zsh Theme
# ==============================================================================
ZSH_THEME="powerlevel10k/powerlevel10k"

# ==============================================================================
# Oh-My-Zsh Settings
# ==============================================================================
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
DISABLE_AUTO_UPDATE="false"
DISABLE_UPDATE_PROMPT="false"
export UPDATE_ZSH_DAYS=7
DISABLE_MAGIC_FUNCTIONS="false"
ENABLE_CORRECTION="false"          # avoid correction annoyance in devsecops cmds
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"

# ==============================================================================
# Plugins
# ==============================================================================
plugins=(
  # Core
  git
  git-extras
  gitignore
  sudo                        # ESC ESC prepends sudo to previous command

  # Container / Orchestration
  docker
  docker-compose
  kubectl
  helm

  # Infrastructure / Cloud
  terraform
  ansible
  aws

  # Shell UX
  history-substring-search    # UP/DOWN arrow searches history by prefix
  colored-man-pages
  command-not-found
  dotenv                      # auto-load .env files per directory

  # Language runtimes (lazy-safe)
  nvm
  node
  npm
  python
  pip

  # Productivity
  aliases
  common-aliases
  copypath
  copyfile
  zsh-autosuggestions
  zsh-syntax-highlighting     # must be last
)

source $ZSH/oh-my-zsh.sh

# ==============================================================================
# History Configuration
# ==============================================================================
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"

setopt HIST_EXPIRE_DUPS_FIRST  # expire duplicates first when trimming
setopt HIST_IGNORE_DUPS        # don't record duplicate consecutive commands
setopt HIST_IGNORE_SPACE       # commands starting with space are not saved
setopt HIST_VERIFY             # show history expansion before running
setopt SHARE_HISTORY           # share history across all sessions
setopt EXTENDED_HISTORY        # save timestamp and duration

# ==============================================================================
# Zsh Options
# ==============================================================================
setopt AUTO_CD                 # cd by typing directory name
setopt CORRECT_ALL             # offer spelling correction
setopt NO_BEEP                 # silence beep
setopt GLOB_DOTS               # include dotfiles in globs
setopt EXTENDED_GLOB           # extended globbing patterns
setopt NULL_GLOB               # no error when glob returns nothing
setopt PUSHD_IGNORE_DUPS       # don't add duplicates to dir stack
setopt PUSHD_SILENT            # don't print dir stack on pushd/popd

# ==============================================================================
# Completion
# ==============================================================================
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/.zcompdump-${ZSH_VERSION}"
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# ==============================================================================
# FZF Configuration
# Install: git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
# ==============================================================================
if command -v fzf &>/dev/null; then
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline \
    --bind 'ctrl-/:toggle-preview'"
  # Use fd for fzf if available, otherwise find
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  else
    export FZF_DEFAULT_COMMAND="find . -type f -not -path '*/.git/*'"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  export FZF_CTRL_R_OPTS="--sort --exact --preview 'echo {}' --preview-window=down:3:wrap"
  export FZF_ALT_C_OPTS="--preview 'ls -la {}'"
  # Source fzf keybindings if installed via git
  [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
elif [[ -f ~/.fzf.zsh ]]; then
  # fzf installed but not in PATH yet
  source ~/.fzf.zsh
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
fi

# ==============================================================================
# NVM — Lazy Loading (faster shell startup)
# ==============================================================================
export NVM_DIR="$HOME/.nvm"
# Lazy-load nvm: only source it when node/npm/nvm is first called
_nvm_lazy_load() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
}
nvm()  { _nvm_lazy_load; nvm "$@"; }
node() { _nvm_lazy_load; node "$@"; }
npm()  { _nvm_lazy_load; npm "$@"; }
npx()  { _nvm_lazy_load; npx "$@"; }

# ==============================================================================
# WSL2 Helpers
# ==============================================================================
if grep -qi microsoft /proc/version 2>/dev/null; then
  # Open current directory in Windows Explorer
  alias open="explorer.exe"
  alias exp="explorer.exe ."

  # Clipboard: pipe to/from Windows clipboard
  alias pbcopy="clip.exe"
  alias pbpaste="powershell.exe -command 'Get-Clipboard' 2>/dev/null | tr -d '\r'"

  # Launch VS Code from WSL
  alias code="code-insiders 2>/dev/null || code"

  # Quick access to Windows user home
  export WINHOME="/mnt/c/Users/$(cmd.exe /c echo %USERNAME% 2>/dev/null | tr -d '\r\n')"
  alias cdwin="cd '$WINHOME'"

  # Zed editor (Windows install, accessible from WSL2)
  export PATH="$PATH:$WINHOME/AppData/Local/Programs/Zed/bin"
  alias ze="zed ."       # open current dir in Zed
  alias zed.="zed ."

  # Fix interop for running Windows executables
  export PATH="$PATH:/mnt/c/Windows/System32:/mnt/c/Windows"
fi

# ==============================================================================
# Safety Aliases
# ==============================================================================
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"
alias ln="ln -i"

# ==============================================================================
# Navigation Aliases
# ==============================================================================
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

# ==============================================================================
# Listing Aliases (use eza if available, fallback to ls)
# ==============================================================================
if command -v eza &>/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -alF --icons --group-directories-first --git"
  alias la="eza -a --icons --group-directories-first"
  alias lt="eza --tree --level=2 --icons"
  alias llt="eza --tree --level=3 --icons --git"
else
  alias ls="ls --color=auto -h"
  alias ll="ls -alF --color=auto"
  alias la="ls -A --color=auto"
fi

# ==============================================================================
# Git Shortcuts
# ==============================================================================
alias g="git"
alias gs="git status -s"
alias ga="git add"
alias gaa="git add -A"
alias gc="git commit -m"
alias gca="git commit --amend --no-edit"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gpl="git pull --rebase"
alias gl="git log --oneline --graph --decorate -n 20"
alias gla="git log --oneline --graph --decorate --all"
alias gdiff="git diff"
alias gds="git diff --staged"
alias gb="git branch -vv"
alias gba="git branch -a"
alias gsw="git switch"
alias gco="git checkout"
alias gst="git stash"
alias gstp="git stash pop"
alias gclean="git clean -fd"

# Interactive git log with fzf (requires fzf)
gli() {
  git log --oneline --color | fzf --ansi --preview 'git show {1}' --bind 'enter:execute(git show {1} | less)'
}

# ==============================================================================
# Docker / Container Shortcuts
# ==============================================================================
alias d="docker"
alias dps="docker ps --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dpsa="docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dimg="docker images"
alias dlogs="docker logs -f"
alias dexec="docker exec -it"
alias dc="docker compose"
alias dcu="docker compose up -d"
alias dcd="docker compose down"
alias dcl="docker compose logs -f"
alias dcr="docker compose restart"

# Stop and remove all containers
dclean() {
  echo "Stopping all containers..."
  docker stop $(docker ps -q) 2>/dev/null
  echo "Removing stopped containers..."
  docker rm $(docker ps -aq) 2>/dev/null
  echo "Done."
}

# Remove dangling images and unused volumes
dprune() {
  docker system prune -f
  docker volume prune -f
}

# Run a throwaway container interactively
drun() {
  local img="${1:-ubuntu:latest}"
  docker run --rm -it "$img" /bin/bash
}

# ==============================================================================
# Kubernetes Shortcuts
# ==============================================================================
alias k="kubectl"
alias kx="kubectx"
alias kn="kubens"
alias kg="kubectl get"
alias kd="kubectl describe"
alias kdel="kubectl delete"
alias kgp="kubectl get pods -o wide"
alias kgpa="kubectl get pods -A -o wide"
alias kgs="kubectl get svc -o wide"
alias kgn="kubectl get nodes -o wide"
alias kge="kubectl get events --sort-by='.lastTimestamp'"
alias ktop="kubectl top pods"
alias ktopn="kubectl top nodes"
alias kaf="kubectl apply -f"
alias kdf="kubectl delete -f"
alias kctx="kubectl config get-contexts"
alias kns="kubectl config set-context --current --namespace"

# Get pod logs with fuzzy selector
klogs() {
  local ns="${2:-default}"
  if [ -z "$1" ]; then
    echo "Usage: klogs <pod-name-prefix> [namespace]"
    return 1
  fi
  local pod
  pod=$(kubectl get pods -n "$ns" --no-headers -o custom-columns=":metadata.name" | grep "$1" | head -n 1)
  if [ -z "$pod" ]; then
    echo "No pod matching '$1' in namespace '$ns'"
    return 1
  fi
  echo "Tailing logs for: $pod"
  kubectl logs -n "$ns" -f "$pod"
}

# Exec into a pod (interactive)
kexec() {
  local ns="${2:-default}"
  if [ -z "$1" ]; then
    echo "Usage: kexec <pod-name-prefix> [namespace]"
    return 1
  fi
  local pod
  pod=$(kubectl get pods -n "$ns" --no-headers -o custom-columns=":metadata.name" | grep "$1" | head -n 1)
  kubectl exec -n "$ns" -it "$pod" -- /bin/bash || kubectl exec -n "$ns" -it "$pod" -- /bin/sh
}

# Watch all resources in namespace
kwatch() {
  local ns="${1:-default}"
  watch -n 2 "kubectl get pods,svc,deploy,ingress -n $ns -o wide"
}

# ==============================================================================
# Terraform Shortcuts
# ==============================================================================
alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"
alias tfaa="terraform apply -auto-approve"
alias tfd="terraform destroy"
alias tfdaa="terraform destroy -auto-approve"
alias tfv="terraform validate"
alias tff="terraform fmt -recursive"
alias tfs="terraform show"
alias tfo="terraform output"

# Terraform workspace helper
# Rename to avoid conflict with 'tf' alias prefix being interpreted by zsh
tf-ws() {
  case "$1" in
    ls)   terraform workspace list ;;
    new)  terraform workspace new "$2" ;;
    sel)  terraform workspace select "$2" ;;
    *)    terraform workspace show ;;
  esac
}
alias tfws="tf-ws"

# ==============================================================================
# Security / DevSecOps Functions
# ==============================================================================

# Trivy: scan image or directory
sec-scan() {
  if [ -z "$1" ]; then
    echo "Usage: sec-scan <image-or-dir>"
    return 1
  fi
  if [ -d "$1" ]; then
    trivy fs --severity MEDIUM,HIGH,CRITICAL "$1"
  else
    trivy image --severity MEDIUM,HIGH,CRITICAL "$1"
  fi
}

# Trivy: scan for secret leaks and misconfigs in a git repo
sec-secrets() {
  trivy repository --scanners config,secret "${1:-.}"
}

# Scan a Dockerfile with hadolint
sec-dockerfile() {
  local file="${1:-Dockerfile}"
  if command -v hadolint &>/dev/null; then
    hadolint "$file"
  else
    echo "hadolint not installed. Install: https://github.com/hadolint/hadolint"
    return 1
  fi
}

# Check for exposed secrets in git history (gitleaks)
sec-git-history() {
  if command -v gitleaks &>/dev/null; then
    gitleaks detect --source="${1:-.}" --verbose
  else
    echo "gitleaks not installed. Install: https://github.com/gitleaks/gitleaks"
    return 1
  fi
}

# Check CVEs in a requirements.txt or package.json
sec-deps() {
  if [ -f "requirements.txt" ]; then
    echo "=== Python dependencies (trivy) ==="
    trivy fs --scanners vuln requirements.txt
  fi
  if [ -f "package.json" ]; then
    echo "=== Node.js dependencies (npm audit) ==="
    npm audit
  fi
  if [ -f "Gemfile.lock" ]; then
    echo "=== Ruby dependencies (trivy) ==="
    trivy fs --scanners vuln Gemfile.lock
  fi
}

# Generate SBOM for a container image
sbom() {
  if [ -z "$1" ]; then
    echo "Usage: sbom <image>"
    return 1
  fi
  trivy image --format cyclonedx --output "sbom-${1//\//_}.json" "$1"
  echo "SBOM written to sbom-${1//\//_}.json"
}

# Lint IaC files in current directory
sec-iac() {
  if command -v tfsec &>/dev/null; then
    echo "=== tfsec ==="
    tfsec .
  fi
  if command -v checkov &>/dev/null; then
    echo "=== checkov ==="
    checkov -d .
  fi
  if command -v kube-score &>/dev/null && ls *.yaml >/dev/null 2>&1; then
    echo "=== kube-score ==="
    kube-score score *.yaml
  fi
}

# Quick port check (what's listening)
ports() {
  ss -tulpn 2>/dev/null || netstat -tulpn 2>/dev/null
}

# Check SSL certificate for a domain
ssl-check() {
  if [ -z "$1" ]; then
    echo "Usage: ssl-check <domain>"
    return 1
  fi
  echo | openssl s_client -connect "$1:443" -servername "$1" 2>/dev/null \
    | openssl x509 -noout -subject -issuer -dates
}

# ==============================================================================
# Python / Virtualenv
# ==============================================================================
alias py="python3"
alias pip="pip3"
alias venv="python3 -m venv .venv && source .venv/bin/activate"
alias activate="source .venv/bin/activate 2>/dev/null || source venv/bin/activate 2>/dev/null || echo 'No venv found'"

# ==============================================================================
# General Productivity
# ==============================================================================
# Quick file search (ripgrep if available, fallback to grep)
if command -v rg &>/dev/null; then
  alias grep="rg"
  alias search="rg"
else
  alias grep="grep --color=auto"
fi

# bat for syntax-highlighted file viewing
if command -v bat &>/dev/null; then
  alias cat="bat --style=numbers,changes"
fi

# Disk usage
alias df="df -h"
alias du="du -sh"
alias ducks="du -sh * | sort -rh | head -20"

# Network
alias myip="curl -s https://ipinfo.io/ip"
alias myips="ip addr | grep 'inet ' | awk '{print \$2}'"
alias pingg="ping -c 4 8.8.8.8"

# Reload shell config
alias reload="source ~/.zshrc && echo 'Config reloaded'"
alias zshrc="$EDITOR ~/.zshrc"

# Tool launchers
alias hd="herdr"
alias jc="jcode"
alias top="htop"   # prefer htop over plain top

# ==============================================================================
# RTK — CLI proxy that reduces LLM token consumption 60-90%
# Docs: https://github.com/rtk-ai/rtk
# Full mode: --ultra-compact (Level 2 optimizations, ASCII icons, inline format)
# ==============================================================================
if command -v rtk &>/dev/null; then
  # Core rtk aliases in ultra-compact (full) mode
  alias rgit="rtk --ultra-compact git"
  alias rgh="rtk --ultra-compact gh"
  alias raws="rtk --ultra-compact aws"
  alias rdocker="rtk --ultra-compact docker"
  alias rkubectl="rtk --ultra-compact kubectl"
  alias rls="rtk --ultra-compact ls"
  alias rtree="rtk --ultra-compact tree"
  alias rdiff="rtk --ultra-compact diff"
  alias rlog="rtk --ultra-compact log"
  alias rerr="rtk --ultra-compact err"
  alias rtest="rtk --ultra-compact test"
  alias rjson="rtk --ultra-compact json"
  alias rdeps="rtk --ultra-compact deps"
  alias renv="rtk --ultra-compact env"
  alias rgrep="rtk --ultra-compact grep"
  alias rrg="rtk --ultra-compact rg"
  alias rsummary="rtk --ultra-compact summary"

  # Quick wrapper: pipe any command through rtk smart summary
  rsmart() { rtk --ultra-compact smart "$@"; }

  # RTK_MODE env var for hook-based integrations (jcode, Claude Code, etc.)
  export RTK_MODE="full"
fi

# ==============================================================================
# Caveman — token-efficient AI communication (full mode by default)
# Docs: https://github.com/JuliusBrussee/caveman
# Installed via: curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh | bash
# Invoke in any AI session: /caveman   (defaults to full mode)
# Modes: lite | full | ultra | wenyan-lite | wenyan-full | wenyan-ultra
# ==============================================================================
export CAVEMAN_MODE="full"   # default intensity for all AI agent sessions

# Make directory and cd into it
mkcd() { mkdir -p "$@" && cd "$_"; }

# Create a dated backup of a file
bak() { cp "$1" "${1}.bak.$(date +%Y%m%d_%H%M%S)"; echo "Backed up to ${1}.bak.$(date +%Y%m%d_%H%M%S)"; }

# Extract any archive
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)  tar xjf "$1"    ;;
      *.tar.gz)   tar xzf "$1"    ;;
      *.tar.xz)   tar xJf "$1"    ;;
      *.bz2)      bunzip2 "$1"    ;;
      *.rar)      unrar x "$1"    ;;
      *.gz)       gunzip "$1"     ;;
      *.tar)      tar xf "$1"     ;;
      *.tbz2)     tar xjf "$1"    ;;
      *.tgz)      tar xzf "$1"    ;;
      *.zip)      unzip "$1"      ;;
      *.Z)        uncompress "$1" ;;
      *.7z)       7z x "$1"       ;;
      *)          echo "Unknown archive format: $1" ;;
    esac
  else
    echo "'$1' is not a file"
  fi
}

# HTTP server in current directory
serve() {
  local port="${1:-8000}"
  echo "Serving on http://localhost:$port"
  python3 -m http.server "$port"
}

# Timer in terminal
timer() {
  local start="$SECONDS"
  "$@"
  local end="$SECONDS"
  echo "Time elapsed: $((end - start))s"
}

# ==============================================================================
# Completions & Tool Integrations
# ==============================================================================
# kubectl
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh)
  compdef k=kubectl
fi

# helm
if command -v helm &>/dev/null; then
  source <(helm completion zsh)
fi

# terraform (hashicorp's native completion via complete command)
if command -v terraform &>/dev/null; then
  complete -o nospace -C terraform terraform
fi

# GitHub CLI
if command -v gh &>/dev/null; then
  source <(gh completion -s zsh)
fi

# AWS CLI
if command -v aws_completer &>/dev/null; then
  complete -C "$(which aws_completer)" aws
fi

# Google Cloud SDK
[[ -f "$HOME/.local/share/google-cloud-sdk/completion.zsh.inc" ]] && \
  source "$HOME/.local/share/google-cloud-sdk/completion.zsh.inc"

# direnv hook (install: sudo apt install direnv)
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# ==============================================================================
# Key Bindings
# ==============================================================================
bindkey '^[[A' history-substring-search-up   # UP arrow
bindkey '^[[B' history-substring-search-down # DOWN arrow
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[H' beginning-of-line             # Home key
bindkey '^[[F' end-of-line                   # End key
bindkey '^[[3~' delete-char                  # Delete key
bindkey '^R' history-incremental-search-backward
# Ctrl+F: fzf file picker (only if fzf is installed)
command -v fzf &>/dev/null && bindkey '^F' fzf-file-widget

# ==============================================================================
# Autosuggestion & Syntax Highlighting Config
# ==============================================================================
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666,italic"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# ==============================================================================
# Powerlevel10k Theme (must be last)
# ==============================================================================
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
