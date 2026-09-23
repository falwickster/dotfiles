function dotfiles {
    git --git-dir="$env:USERPROFILE\.dotfiles.git" --work-tree="$env:USERPROFILE" $args
}

Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
