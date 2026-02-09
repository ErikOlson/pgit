# pgit-add.sh — smart add with pattern-based routing

pgit_add() {
    pgit_sync_excludes

    # Check if any arg is a specific file (not a directory, flag, or ".")
    _needs_routing=false
    for _arg in "$@"; do
        case "$_arg" in
            -*|.) continue ;;
            *)
                if ! [ -d "$_arg" ]; then
                    _needs_routing=true
                    break
                fi
                ;;
        esac
    done

    if ! $_needs_routing; then
        # Broad add (., dirs, flags only) — pass to both repos, excludes handle routing
        pgit_product_git_run add "$@" || true
        pgit_process_git_run add "$@" || true
        return
    fi

    # Has specific files — classify and route
    pgit_load_patterns
    _subdir=$(pgit_get_subdir)

    # Collect flags
    _flags=""
    for _arg in "$@"; do
        case "$_arg" in
            -*) _flags="$_flags $_arg" ;;
        esac
    done

    _any_product=false
    _any_process=false

    for _arg in "$@"; do
        case "$_arg" in
            -*) continue ;;
            .)
                pgit_product_git_run add $_flags . || true
                pgit_process_git_run add $_flags . || true
                ;;
            *)
                if [ -d "$_arg" ]; then
                    pgit_product_git_run add $_flags "$_arg" || true
                    pgit_process_git_run add $_flags "$_arg" || true
                else
                    _relfile="$_arg"
                    if [ -n "$_subdir" ]; then
                        _relfile="$_subdir/$_arg"
                    fi
                    _layer=$(pgit_classify_file "$_relfile")
                    if [ "$_layer" = "process" ]; then
                        pgit_process_git_run add $_flags "$_arg"
                        _any_process=true
                    else
                        pgit_product_git_run add $_flags "$_arg"
                        _any_product=true
                    fi
                fi
                ;;
        esac
    done

    if $_any_product && $_any_process; then
        echo "pgit: files staged in both product and process layers" >&2
    fi
}
