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

# --- Completion ----------------------------------------------------------
autoload -Uz compinit
compinit

# --- fzf: Ctrl+R fuzzy reverse-history search ---------------------------
# Matches the Windows profile's `Set-PsFzfOption
# -PSReadlineChordReverseHistory 'Ctrl+r'` key-for-key: source fzf's own
# shell integration for completion, then explicitly (re-)bind Ctrl+R to
# the fzf history widget rather than relying on fzf's own default.
for fzf_integration in \
    /usr/share/doc/fzf/examples/completion.zsh \
    /usr/share/fzf/completion.zsh \
    /usr/share/doc/fzf/examples/key-bindings.zsh \
    /usr/share/fzf/key-bindings.zsh
do
    [[ -f "$fzf_integration" ]] && source "$fzf_integration"
done
if command -v fzf >/dev/null 2>&1 && (( $+widgets[fzf-history-widget] )); then
    bindkey '^R' fzf-history-widget
fi

# --- zsh-autosuggestions: ghost-text history suggestions ----------------
for autosuggestions_init in \
    /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
    "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
do
    if [[ -f "$autosuggestions_init" ]]; then
        source "$autosuggestions_init"
        break
    fi
done
ZSH_AUTOSUGGEST_STRATEGY=(history)

# --- zsh-syntax-highlighting (must be sourced near the end of the file) -
for syntax_highlighting_init in \
    /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
    "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
do
    if [[ -f "$syntax_highlighting_init" ]]; then
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
