# pgit-core.sh — walk-up discovery, git helpers, utilities

# Find .pgit/ directory by walking up from cwd.
# Sets PGIT_DIR (path to .pgit/) and PGIT_ROOT (project root).
pgit_find_root() {
    _dir="$PWD"
    while true; do
        if [ -d "$_dir/.pgit" ]; then
            PGIT_ROOT="$_dir"
            PGIT_DIR="$_dir/.pgit"
            return 0
        fi
        _parent="$(dirname "$_dir")"
        if [ "$_parent" = "$_dir" ]; then
            return 1
        fi
        _dir="$_parent"
    done
}

pgit_die() {
    echo "pgit: $*" >&2
    exit 1
}

# exec variants (terminal — script does not continue)
pgit_product_git() {
    GIT_DIR="$PGIT_ROOT/.git" GIT_WORK_TREE="$PGIT_ROOT" exec git "$@"
}

pgit_process_git() {
    GIT_DIR="$PGIT_DIR/layers/process/.git" GIT_WORK_TREE="$PGIT_ROOT" exec git "$@"
}

# Non-exec variants (script continues after git returns)
pgit_product_git_run() {
    GIT_DIR="$PGIT_ROOT/.git" GIT_WORK_TREE="$PGIT_ROOT" git "$@"
}

pgit_process_git_run() {
    GIT_DIR="$PGIT_DIR/layers/process/.git" GIT_WORK_TREE="$PGIT_ROOT" git "$@"
}

pgit_get_subdir() {
    case "$PWD" in
        "$PGIT_ROOT") ;;
        "$PGIT_ROOT"/*) echo "${PWD#"$PGIT_ROOT"/}" ;;
        *) pgit_die "current directory is outside project root" ;;
    esac
}

# Check if the process repo has staged changes.
# Returns 0 if there ARE staged changes, 1 if there are none.
pgit_process_has_staged() {
    if GIT_DIR="$PGIT_DIR/layers/process/.git" git rev-parse HEAD >/dev/null 2>&1; then
        ! GIT_DIR="$PGIT_DIR/layers/process/.git" GIT_WORK_TREE="$PGIT_ROOT" \
            git diff-index --cached --quiet HEAD -- 2>/dev/null
    else
        _files=$(GIT_DIR="$PGIT_DIR/layers/process/.git" GIT_WORK_TREE="$PGIT_ROOT" \
            git ls-files --cached 2>/dev/null)
        [ -n "$_files" ]
    fi
}
