# Dotfiles — Project Instructions

DevSecOps shell configuration repo for Ubuntu/WSL2.

## Rules
- Never commit secrets, credentials, API keys, or tokens
- Run `zsh -n zshrc` before committing zshrc changes
- Run `bash -n bootstrap.sh` before committing bootstrap changes
- Keep bootstrap.sh idempotent (safe to re-run)
- Keep README.md in sync with any alias, function, or tool changes
- All security scan functions use `--ignore-unfixed` flag
- tfsec is deprecated; use `trivy config` instead
- `eza` is the maintained fork of `exa`; use eza

## Conventions
- zshrc sections separated by `# ====` comment blocks
- bootstrap.sh sections separated by `# ----` comment blocks
- Each tool install block: check `installed`, skip with warn, else install
- Security functions prefixed with `sec-`
- Aliases follow short mnemonic patterns: `k`=kubectl, `tf`=terraform, `d`=docker, `ans`=ansible
