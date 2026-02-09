# pgit fish completion
# Install to ~/.config/fish/completions/ or eval (pgit completions fish)

# Helper: true when no subcommand given yet
function __pgit_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

# Helper: true when current subcommand matches
function __pgit_using_command
    set -l cmd (commandline -opc)
    test (count $cmd) -gt 1; and test "$cmd[2]" = "$argv[1]"
end

# Helper: true when pp subcommand is given
function __pgit_pp_needs_subcmd
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 2; and test "$cmd[2]" = "pp"
end

# Helper: true when pp registry needs subcmd
function __pgit_pp_registry_needs_subcmd
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 3; and test "$cmd[2]" = "pp"; and test "$cmd[3]" = "registry"
end

# Helper: true when -p needs a git command
function __pgit_p_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 2; and test "$cmd[2]" = "-p"
end

# Disable file completions by default
complete -c pgit -f

# Top-level pgit commands
complete -c pgit -n '__pgit_needs_command' -a 'init' -d 'Initialize pgit in current directory'
complete -c pgit -n '__pgit_needs_command' -a 'adopt' -d 'Adopt pgit in an existing repo'
complete -c pgit -n '__pgit_needs_command' -a 'add-to-process' -d 'Move file(s) from product to process'
complete -c pgit -n '__pgit_needs_command' -a 'pp' -d 'P&P multiplexer commands'
complete -c pgit -n '__pgit_needs_command' -a 'completions' -d 'Print shell completion script'
complete -c pgit -n '__pgit_needs_command' -a '-p' -d 'Run git against the process repo'
complete -c pgit -n '__pgit_needs_command' -l version -s V -d 'Show version'
complete -c pgit -n '__pgit_needs_command' -l help -s h -d 'Show help'

# Add git commands at top level
complete -c pgit -n '__pgit_needs_command' -a '(git help -a 2>/dev/null | string match -r "^  \\S+" | string trim)' -d 'git command'

# pgit adopt
complete -c pgit -n '__pgit_using_command adopt' -s y -l yes -d 'Skip confirmation prompt'

# pgit completions
complete -c pgit -n '__pgit_using_command completions' -a 'bash zsh fish'

# pgit add-to-process: complete files
complete -c pgit -n '__pgit_using_command add-to-process' -F

# pgit pp subcommands
complete -c pgit -n '__pgit_pp_needs_subcmd' -a 'commit' -d 'Commit across both repos'
complete -c pgit -n '__pgit_pp_needs_subcmd' -a 'registry' -d 'Manage pattern registry'
complete -c pgit -n '__pgit_pp_needs_subcmd' -a 'remotes' -d 'Show remotes for both repos'

# pgit pp registry subcommands
complete -c pgit -n '__pgit_pp_registry_needs_subcmd' -a 'list' -d 'List all registry pattern sets'
complete -c pgit -n '__pgit_pp_registry_needs_subcmd' -a 'add' -d 'Add pattern to registry'
complete -c pgit -n '__pgit_pp_registry_needs_subcmd' -a 'remove' -d 'Remove pattern from registry'

# pgit -p: offer git commands
complete -c pgit -n '__pgit_p_needs_command' -a '(git help -a 2>/dev/null | string match -r "^  \\S+" | string trim)' -d 'git command'

# pnp completions (alias for pgit pp)
complete -c pnp -f
complete -c pnp -n '__fish_use_subcommand' -a 'commit' -d 'Commit across both repos'
complete -c pnp -n '__fish_use_subcommand' -a 'registry' -d 'Manage pattern registry'
complete -c pnp -n '__fish_use_subcommand' -a 'remotes' -d 'Show remotes for both repos'

function __pnp_using_command
    set -l cmd (commandline -opc)
    test (count $cmd) -gt 1; and test "$cmd[2]" = "$argv[1]"
end

complete -c pnp -n '__pnp_using_command registry' -a 'list' -d 'List all registry pattern sets'
complete -c pnp -n '__pnp_using_command registry' -a 'add' -d 'Add pattern to registry'
complete -c pnp -n '__pnp_using_command registry' -a 'remove' -d 'Remove pattern from registry'
