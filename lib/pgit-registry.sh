# pgit-registry.sh — pattern registry CRUD and built-in pattern management

# Ensure registry dir exists and install built-in patterns if missing.
pgit_ensure_registry() {
    mkdir -p "$PGIT_REGISTRY_DIR"
    if [ ! -f "$PGIT_REGISTRY_DIR/claude-code.json" ]; then
        cat > "$PGIT_REGISTRY_DIR/claude-code.json" << 'BUILTIN'
{
  "name": "claude-code",
  "description": "Claude Code process files",
  "patterns": [
    "CLAUDE.md",
    ".claude/",
    "AGENTS.md",
    "PLAN.md",
    "TASKS.md"
  ]
}
BUILTIN
    fi
    if [ ! -f "$PGIT_REGISTRY_DIR/agent-logs.json" ]; then
        cat > "$PGIT_REGISTRY_DIR/agent-logs.json" << 'BUILTIN'
{
  "name": "agent-logs",
  "description": "Agent log files",
  "patterns": [
    "*.agent-log"
  ]
}
BUILTIN
    fi
}

# Collect all patterns from registry into a newline-separated list.
# Sets PGIT_REGISTRY_PATTERNS.
pgit_load_registry_patterns() {
    pgit_ensure_registry
    PGIT_REGISTRY_PATTERNS=""
    for _f in "$PGIT_REGISTRY_DIR"/*.json; do
        [ -f "$_f" ] || continue
        _pats=$(pgit_read_registry_file "$_f")
        _old_ifs="$IFS"
        IFS='
'
        for _p in $_pats; do
            [ -z "$_p" ] && continue
            case "$PGIT_REGISTRY_PATTERNS" in
                *"$_p"*) ;;
                *) PGIT_REGISTRY_PATTERNS="${PGIT_REGISTRY_PATTERNS}${_p}
" ;;
            esac
        done
        IFS="$_old_ifs"
    done
}

# List all registry pattern sets.
pgit_registry_list() {
    pgit_ensure_registry
    for _f in "$PGIT_REGISTRY_DIR"/*.json; do
        [ -f "$_f" ] || continue
        _name=$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$_f")
        _desc=$(sed -n 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$_f")
        _pats=$(pgit_read_registry_file "$_f")
        _display=""
        _old_ifs="$IFS"
        IFS='
'
        for _p in $_pats; do
            [ -n "$_p" ] && _display="$_display $_p"
        done
        IFS="$_old_ifs"
        echo "$_name — $_desc"
        echo "  patterns:$_display"
    done
}

# Read patterns from a registry JSON file (one per line to stdout).
pgit_read_registry_file() {
    _rf="$1"
    _in_pat=0
    while IFS= read -r _line; do
        case "$_line" in
            *'"patterns"'*) _in_pat=1; continue ;;
        esac
        if [ "$_in_pat" -eq 1 ]; then
            case "$_line" in
                *']'*) _in_pat=0; continue ;;
                *)
                    _p=$(echo "$_line" | sed -n 's/.*"\([^"]*\)".*/\1/p')
                    [ -n "$_p" ] && echo "$_p"
                    ;;
            esac
        fi
    done < "$_rf"
}

# Write a registry JSON file from name, description, and patterns (one per line on stdin).
pgit_write_registry_file() {
    _wf="$1"
    _wname="$2"
    _wdesc="$3"
    _wpats=""
    _wfirst=true
    while IFS= read -r _wp; do
        [ -z "$_wp" ] && continue
        if $_wfirst; then
            _wpats="    \"$_wp\""
            _wfirst=false
        else
            _wpats="$_wpats,
    \"$_wp\""
        fi
    done
    cat > "$_wf" << EOF
{
  "name": "$_wname",
  "description": "$_wdesc",
  "patterns": [
$_wpats
  ]
}
EOF
}

# Add a pattern to a registry set.
pgit_registry_add() {
    _pattern="$1"
    _set="${2:-custom}"
    _file="$PGIT_REGISTRY_DIR/$_set.json"

    pgit_ensure_registry

    if [ -f "$_file" ]; then
        if grep -q "\"$_pattern\"" "$_file" 2>/dev/null; then
            echo "pgit: pattern '$_pattern' already in set '$_set'" >&2
            return 0
        fi
        _existing=$(pgit_read_registry_file "$_file")
        _name=$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$_file")
        _desc=$(sed -n 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$_file")
        { echo "$_existing"; echo "$_pattern"; } | pgit_write_registry_file "$_file" "$_name" "$_desc"
    else
        echo "$_pattern" | pgit_write_registry_file "$_file" "$_set" "Custom patterns"
    fi
    echo "pgit: added '$_pattern' to registry set '$_set'"
}

# Remove a pattern from registry.
pgit_registry_remove() {
    _pattern="$1"

    pgit_ensure_registry

    _found=false
    for _f in "$PGIT_REGISTRY_DIR"/*.json; do
        [ -f "$_f" ] || continue
        if grep -q "\"$_pattern\"" "$_f" 2>/dev/null; then
            _existing=$(pgit_read_registry_file "$_f")
            _name=$(sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$_f")
            _desc=$(sed -n 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$_f")
            echo "$_existing" | grep -v "^${_pattern}$" | \
                pgit_write_registry_file "$_f" "$_name" "$_desc"
            echo "pgit: removed '$_pattern' from registry set '$_name'"
            _found=true
        fi
    done

    if ! $_found; then
        pgit_die "pattern '$_pattern' not found in registry"
    fi
}

# pp registry dispatch
pgit_pp_registry() {
    if [ $# -eq 0 ]; then
        pgit_registry_list
        return
    fi

    case "$1" in
        list)
            pgit_registry_list
            ;;
        add)
            shift
            [ $# -eq 0 ] && pgit_die "usage: pnp registry add <pattern> [set-name]"
            pgit_registry_add "$@"
            ;;
        remove)
            shift
            [ $# -eq 0 ] && pgit_die "usage: pnp registry remove <pattern>"
            pgit_registry_remove "$1"
            ;;
        *)
            pgit_die "unknown registry command: $1. Use list, add, or remove."
            ;;
    esac
}
