# pgit bash completion
# Source this from .bashrc or install to /etc/bash_completion.d/

# Try to load git's completion if not already present
if ! declare -F __git_main >/dev/null 2>&1; then
    _pgit_git_completion_locations="
        /usr/share/bash-completion/completions/git
        /usr/local/share/bash-completion/completions/git
        /opt/homebrew/share/bash-completion/completions/git
        /Library/Developer/CommandLineTools/usr/share/git-core/git-completion.bash
        /Applications/Xcode.app/Contents/Developer/usr/share/git-core/git-completion.bash
    "
    for _f in $_pgit_git_completion_locations; do
        if [ -f "$_f" ]; then
            . "$_f"
            break
        fi
    done
    unset _pgit_git_completion_locations _f
fi

_pgit_commands="init adopt add-to-process pp completions"

_pgit() {
    local cur prev words cword
    _init_completion || return

    # Position 1: pgit <cmd>
    if [ "$cword" -eq 1 ]; then
        local pgit_cmds="$_pgit_commands"
        pgit_cmds="$pgit_cmds -p --version --help"

        # Add git commands if available
        local git_cmds
        git_cmds=$(git --list-cmds=main,others 2>/dev/null)
        if [ -n "$git_cmds" ]; then
            pgit_cmds="$pgit_cmds $git_cmds"
        fi

        COMPREPLY=($(compgen -W "$pgit_cmds" -- "$cur"))
        return
    fi

    # pgit -p <git-cmd> — complete like git
    if [ "${words[1]}" = "-p" ]; then
        if [ "$cword" -eq 2 ]; then
            local git_cmds
            git_cmds=$(git --list-cmds=main,others 2>/dev/null)
            COMPREPLY=($(compgen -W "${git_cmds:-}" -- "$cur"))
            return
        fi
        # Delegate deeper args to git completion
        if declare -F __git_main >/dev/null 2>&1; then
            COMP_WORDS=("git" "${COMP_WORDS[@]:2}")
            COMP_CWORD=$((COMP_CWORD - 1))
            __git_main
        fi
        return
    fi

    # pgit pp <subcmd>
    if [ "${words[1]}" = "pp" ]; then
        if [ "$cword" -eq 2 ]; then
            COMPREPLY=($(compgen -W "commit registry remotes" -- "$cur"))
            return
        fi
        # pgit pp registry <subcmd>
        if [ "${words[2]}" = "registry" ] && [ "$cword" -eq 3 ]; then
            COMPREPLY=($(compgen -W "list add remove" -- "$cur"))
            return
        fi
        return
    fi

    # pgit adopt
    if [ "${words[1]}" = "adopt" ]; then
        COMPREPLY=($(compgen -W "-y --yes" -- "$cur"))
        return
    fi

    # pgit completions
    if [ "${words[1]}" = "completions" ]; then
        if [ "$cword" -eq 2 ]; then
            COMPREPLY=($(compgen -W "bash zsh fish" -- "$cur"))
        fi
        return
    fi

    # pgit add-to-process: complete files
    if [ "${words[1]}" = "add-to-process" ]; then
        _filedir
        return
    fi

    # Everything else: delegate to git completion
    if declare -F __git_main >/dev/null 2>&1; then
        COMP_WORDS=("git" "${COMP_WORDS[@]:1}")
        COMP_CWORD=$((COMP_CWORD))
        __git_main
    fi
}

_pnp() {
    local cur prev words cword
    _init_completion || return

    # Position 1: pnp <pp-subcmd>
    if [ "$cword" -eq 1 ]; then
        COMPREPLY=($(compgen -W "commit registry remotes" -- "$cur"))
        return
    fi

    # pnp registry <subcmd>
    if [ "${words[1]}" = "registry" ] && [ "$cword" -eq 2 ]; then
        COMPREPLY=($(compgen -W "list add remove" -- "$cur"))
        return
    fi
}

complete -F _pgit pgit
complete -F _pnp pnp
