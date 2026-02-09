# pgit-pp.sh — pp dispatch, overview, and remotes

pgit_pp() {
    if [ $# -eq 0 ]; then
        pgit_pp_overview
        return
    fi

    case "$1" in
        commit)
            shift
            pgit_pp_commit "$@"
            ;;
        registry)
            shift
            pgit_pp_registry "$@"
            ;;
        remotes)
            pgit_pp_remotes
            ;;
        *)
            pgit_die "unknown pp command: $1"
            ;;
    esac
}

pgit_pp_remotes() {
    if ! pgit_find_root; then
        pgit_die "not a pgit directory (no .pgit/ found)."
    fi

    echo "product remotes:"
    _product_remotes=$(pgit_product_git_run remote -v 2>/dev/null) || true
    if [ -n "$_product_remotes" ]; then
        echo "$_product_remotes" | sed 's/^/  /'
    else
        echo "  (none)"
    fi

    echo "process remotes:"
    _process_remotes=$(pgit_process_git_run remote -v 2>/dev/null) || true
    if [ -n "$_process_remotes" ]; then
        echo "$_process_remotes" | sed 's/^/  /'
    else
        echo "  (none)"
    fi
}

pgit_pp_overview() {
    if ! pgit_find_root; then
        pgit_die "not a pgit directory (no .pgit/ found)."
    fi

    _product_branch=$(git --git-dir="$PGIT_ROOT/.git" --work-tree="$PGIT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "(no commits)")
    _process_branch=$(git --git-dir="$PGIT_DIR/layers/process/.git" --work-tree="$PGIT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "(no commits)")

    if git --git-dir="$PGIT_ROOT/.git" --work-tree="$PGIT_ROOT" diff --quiet 2>/dev/null && \
       git --git-dir="$PGIT_ROOT/.git" --work-tree="$PGIT_ROOT" diff --cached --quiet 2>/dev/null; then
        _product_status="clean"
    else
        _product_status="dirty"
    fi

    if git --git-dir="$PGIT_DIR/layers/process/.git" --work-tree="$PGIT_ROOT" diff --quiet 2>/dev/null && \
       git --git-dir="$PGIT_DIR/layers/process/.git" --work-tree="$PGIT_ROOT" diff --cached --quiet 2>/dev/null; then
        _process_status="clean"
    else
        _process_status="dirty"
    fi

    _product_commit=$(git --git-dir="$PGIT_ROOT/.git" log --oneline -1 2>/dev/null || echo "(no commits)")
    _process_commit=$(git --git-dir="$PGIT_DIR/layers/process/.git" log --oneline -1 2>/dev/null || echo "(no commits)")

    # Remote tracking info
    _product_remote=""
    if git --git-dir="$PGIT_ROOT/.git" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
        _ahead=$(git --git-dir="$PGIT_ROOT/.git" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
        _behind=$(git --git-dir="$PGIT_ROOT/.git" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
        if [ "$_ahead" -gt 0 ] && [ "$_behind" -gt 0 ]; then
            _product_remote=" ↑$_ahead ↓$_behind"
        elif [ "$_ahead" -gt 0 ]; then
            _product_remote=" ↑$_ahead"
        elif [ "$_behind" -gt 0 ]; then
            _product_remote=" ↓$_behind"
        fi
    fi

    _process_remote=""
    if git --git-dir="$PGIT_DIR/layers/process/.git" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
        _ahead=$(git --git-dir="$PGIT_DIR/layers/process/.git" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
        _behind=$(git --git-dir="$PGIT_DIR/layers/process/.git" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
        if [ "$_ahead" -gt 0 ] && [ "$_behind" -gt 0 ]; then
            _process_remote=" ↑$_ahead ↓$_behind"
        elif [ "$_ahead" -gt 0 ]; then
            _process_remote=" ↑$_ahead"
        elif [ "$_behind" -gt 0 ]; then
            _process_remote=" ↓$_behind"
        fi
    fi

    echo "product  [$_product_branch] $_product_status$_product_remote"
    echo "  $_product_commit"
    echo "process  [$_process_branch] $_process_status$_process_remote"
    echo "  $_process_commit"
}
