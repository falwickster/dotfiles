# Linux shell config, checked out to $HOME/.zshrc by the dotfiles bare-repo
# workflow (see README.md). Mirrors the Windows PowerShell profile's
# feature set: fzf-powered Ctrl+R history search, ghost-text history
# autosuggestions, and the same locked-down `dotfiles` sync helper.

# --- PATH ----------------------------------------------------------------
# User-local binaries (e.g. the standalone GitHub Copilot CLI installed by
# install-copilot-cli.sh) land in ~/.local/bin, which isn't on PATH by
# default on every distro/shell-init combo.
if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi

# --- History -----------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# --- Welcome banner + manual-setup reminders -----------------------------
# Defined as a function (rather than run inline here) so it's easy to
# re-invoke manually if needed. Called once below for every interactive
# login shell.
__print_login_banner() {
    # Nags for the handful of one-time, interactive steps nothing in
    # Ubuntu-Setup can safely automate (they need credentials, network, or
    # a TTY). Every check is live (no "dismiss once" flag file), so a
    # reminder disappears for good the moment its underlying condition is
    # actually fixed. Each remote check is capped with `timeout` so a
    # flaky/offline network never hangs shell startup.
    local __login_reminders=()

    if command -v gh >/dev/null 2>&1; then
        if ! timeout 3 gh auth status >/dev/null 2>&1; then
            __login_reminders+=("GitHub CLI not authenticated -- run: gh auth login")
        fi
    fi

    if command -v az >/dev/null 2>&1; then
        if ! timeout 3 az account show >/dev/null 2>&1; then
            __login_reminders+=("Azure CLI not authenticated -- run: az login")
        fi
    fi

    if command -v copilot >/dev/null 2>&1 || [[ -x "$HOME/.local/bin/copilot" ]]; then
        if [[ ! -f "$HOME/.azure-devops.local" ]]; then
            __login_reminders+=("Azure DevOps org(s) not configured for the Copilot MCP server -- run: cp ~/dotfiles/.azure-devops.local.example ~/.azure-devops.local && hx ~/.azure-devops.local, then re-run scripts/install-azure-devops-mcp.sh")
        else
            # File exists, but may still be an unedited copy of the
            # example (only placeholder org names, or no org lines at
            # all) -- catch that case too, not just a missing file.
            local __ado_orgs
            __ado_orgs="$(grep -v -E '^[[:space:]]*(#|$)' "$HOME/.azure-devops.local" 2>/dev/null \
                | grep -v -E '^[[:space:]]*your-(ado|first-ado|second-ado|third-ado)-org-name[[:space:]]*$')"
            if [[ -z "$__ado_orgs" ]]; then
                __login_reminders+=("Azure DevOps org(s) left as placeholder in ~/.azure-devops.local -- edit it with your real org name(s), then re-run scripts/install-azure-devops-mcp.sh")
            fi
        fi
    fi

    if command -v podman >/dev/null 2>&1; then
        if [[ ! -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock" ]]; then
            if [[ ! -d "/run/user/$(id -u)" ]]; then
                # No user systemd instance/D-Bus session yet -- `brew
                # services start podman` fails with "Failed to connect to
                # user scope bus via local transport" until lingering is
                # enabled *and* WSL has been fully restarted (a new
                # terminal/shell isn't enough).
                __login_reminders+=("Podman API service not running (no systemd user session) -- run: sudo loginctl enable-linger \$(whoami), then from Windows PowerShell: wsl --shutdown, then reopen this terminal and run: brew services start podman")
            else
                __login_reminders+=("Podman API service not running -- run: brew services start podman")
            fi
        elif ! podman secret inspect azure-devops-pat >/dev/null 2>&1; then
            # No automated setup for this one on purpose - the PAT is
            # pasted straight into Podman's secret store, by hand, so it
            # never touches a dotfile, env var, or shell history. Stored
            # for future use by whatever custom container image ends up
            # consuming it (no copilot_here/MCP-specific encoding assumed).
            __login_reminders+=("Azure DevOps PAT not stored -- run: podman secret create azure-devops-pat - (paste the PAT, then Ctrl-D)")
        fi
    fi

    if [[ ! -f "$HOME/.gitconfig.local" ]]; then
        __login_reminders+=("Git identity not set -- run: cp ~/.gitconfig.local.example ~/.gitconfig.local && hx ~/.gitconfig.local")
    fi

    # WSL-only: scripts/install-azure-devops-git-credentials.sh skips
    # itself (rather than failing bootstrap) if Git for Windows/standalone
    # GCM for Windows wasn't found yet on the Windows side. Non-WSL Linux
    # needs no reminder here -- that branch just installs its own local
    # brew cask, no external manual dependency.
    if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
        if [[ -z "$(git config --global --get credential.https://dev.azure.com.helper 2>/dev/null)" ]]; then
            __login_reminders+=("Azure DevOps git credentials not configured -- install Git for Windows (or standalone GCM for Windows), then re-run: ./scripts/install-azure-devops-git-credentials.sh")
        fi
    fi

    if (( ${#__login_reminders[@]} > 0 )); then
        echo ""
        echo "⚠️  Manual setup still needed:"
        for __login_reminder in "${__login_reminders[@]}"; do
            echo "   - $__login_reminder"
        done
    fi
}

# --- Login banner: print once per interactive shell ----------------------
# tmux is installed but not auto-started - run it manually (`tmux`) when
# you want it. Skipped for non-interactive contexts (scp, VS Code remote
# exec, etc.).
if [[ -o interactive ]]; then
    __print_login_banner
fi

# --- Word-jump keybindings (Ctrl+Left/Right) -----------------------------
# Without these, xterm-compatible terminals (e.g. WezTerm) send an
# escape sequence for Ctrl+Left/Right that zsh doesn't bind to anything by
# default, so it gets inserted into the prompt as literal text instead of
# moving the cursor a word at a time. Covers the handful of encodings
# actually seen in practice (tmux's `xterm-keys on`, set in tmux.conf,
# ensures the first/most common form below reaches zsh unmangled even
# through tmux).
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[5C'   forward-word
bindkey '^[[5D'   backward-word
bindkey '^[Oc'    forward-word
bindkey '^[Od'    backward-word

# --- Completion ----------------------------------------------------------
autoload -Uz compinit
compinit

# --- fzf: Ctrl+R fuzzy reverse-history search ---------------------------
# Matches the Windows profile's `Set-PsFzfOption
# -PSReadlineChordReverseHistory 'Ctrl+r'` key-for-key. Modern fzf (>=0.48,
# what Homebrew ships) can generate its own shell integration on the fly
# via `fzf --zsh` - no need to hunt for distro-specific static file paths
# (which has proven unreliable: Ubuntu 24.04's old apt fzf package lists
# completion.zsh/key-bindings.zsh in its manifest but doesn't actually ship
# them). Fall back to known static paths for older fzf, then to a
# dependency-free hand-rolled widget as a last resort, so Ctrl+R always
# works regardless of how fzf ended up installed.
# Use fd (when installed) as fzf's file source: respects .gitignore, includes
# hidden files, and powers Ctrl+T (file picker) and Alt+C (cd into dir).
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
if command -v fzf >/dev/null 2>&1; then
    if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh)
    else
        for fzf_integration in \
            "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" \
            "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" \
            /usr/share/doc/fzf/examples/completion.zsh \
            /usr/share/fzf/completion.zsh \
            /usr/share/doc/fzf/examples/key-bindings.zsh \
            /usr/share/fzf/key-bindings.zsh
        do
            [[ -n "$fzf_integration" && -f "$fzf_integration" ]] && source "$fzf_integration"
        done
    fi
fi

if command -v fzf >/dev/null 2>&1 && ! (( ${+widgets[fzf-history-widget]} )); then
    fzf-history-widget() {
        local selected
        selected="$(fc -rl 1 | fzf --tac --no-sort -q "$LBUFFER" | sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//')"
        if [[ -n "$selected" ]]; then
            LBUFFER="$selected"
        fi
        zle reset-prompt
    }
    zle -N fzf-history-widget
fi
if command -v fzf >/dev/null 2>&1 && (( ${+widgets[fzf-history-widget]} )); then
    bindkey '^R' fzf-history-widget
fi

# --- zsh-autosuggestions: ghost-text history suggestions ----------------
for autosuggestions_init in \
    "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
    "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
do
    if [[ -n "$autosuggestions_init" && -f "$autosuggestions_init" ]]; then
        source "$autosuggestions_init"
        break
    fi
done
ZSH_AUTOSUGGEST_STRATEGY=(history)

# --- zsh-syntax-highlighting (must be sourced near the end of the file) -
for syntax_highlighting_init in \
    "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
do
    if [[ -n "$syntax_highlighting_init" && -f "$syntax_highlighting_init" ]]; then
        source "$syntax_highlighting_init"
        break
    fi
done

# --- eza: prettier `ls` --------------------------------------------------
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias lt='eza --tree --icons --group-directories-first'
fi

# --- yazi: terminal file manager, cd-on-quit wrapper ---------------------
# Standard yazi shell integration: `y` opens yazi, and on quit changes the
# shell's cwd to whatever directory yazi was last in (via a temp
# --cwd-file), instead of leaving you back where you started.
if command -v yazi >/dev/null 2>&1; then
    function y() {
        local tmp
        tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        local cwd
        if cwd="$(cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
            cd -- "$cwd"
        fi
        rm -f -- "$tmp"
    }
fi

# --- dotfiles sync helper -------------------------------------------------
# Intentionally locked down to read-only / sync operations, mirroring the
# PowerShell profile's `dotfiles` function. It exists purely to pull
# changes made elsewhere (e.g. by an AI agent in a separate clone) into
# this home directory checkout - never to author or push changes directly
# from here. Use a plain clone of the repo for that.
dotfiles() {
    local allowed=(pull fetch merge status log diff)
    if (( $# == 0 )) || [[ -z "${allowed[(r)$1]}" ]]; then
        echo "dotfiles: only these subcommands are allowed: ${(j:, :)allowed}" >&2
        return 1
    fi
    git --git-dir="$HOME/.dotfiles.git" --work-tree="$HOME" "$@"
}
