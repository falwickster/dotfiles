# 'dotfiles' is intentionally locked down to read-only / sync operations.
# It exists purely to pull changes made elsewhere (e.g. by an AI agent in a
# separate clone) into this home directory checkout - never to author or
# push changes directly from here. Use a plain clone of the repo for that.
function dotfiles {
    $allowed = @('pull', 'fetch', 'merge', 'status', 'log', 'diff')
    if ($args.Count -eq 0 -or $allowed -notcontains $args[0]) {
        Write-Error "dotfiles: only these subcommands are allowed: $($allowed -join ', ')"
        return
    }
    git --git-dir="$env:USERPROFILE\.dotfiles.git" --work-tree="$env:USERPROFILE" $args
}

Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
