# Linux shell config, checked out to $HOME/.zshrc by the dotfiles bare-repo
# workflow (see README.md). Mirrors the Windows PowerShell profile's
# feature set: fzf-powered Ctrl+R history search, ghost-text history
# autosuggestions, and the same locked-down `dotfiles` sync helper.

# --- History -----------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# --- tmux: auto-start a new session on every interactive login shell ----
# Guarded so it only fires for interactive shells, never re-enters when
# already inside tmux (e.g. a pane spawning a nested shell), and never
# fires for non-interactive contexts (scp, VS Code remote exec, etc.).
if [[ -z "$TMUX" && -o interactive ]] && command -v tmux >/dev/null 2>&1; then
    exec tmux
fi

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
