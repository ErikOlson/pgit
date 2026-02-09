# pgit-commit.sh — smart commit with nudging and pp commit

pgit_commit() {
    _auto=$(pgit_config_get "pp.auto-commit")

    if [ "$_auto" = "true" ]; then
        pgit_product_git_run commit "$@" || true
        pgit_process_git_run commit "$@" || true
        return
    fi

    # Normal commit: product repo, then nudge about process
    _exit=0
    pgit_product_git_run commit "$@" || _exit=$?

    if pgit_process_has_staged; then
        echo "pgit: process layer has staged changes. Run 'pgit -p commit' or 'pnp commit'." >&2
    fi

    exit $_exit
}

pgit_pp_commit() {
    # Extract -m message for sync default
    _msg=""
    _skip_next=false
    for _arg in "$@"; do
        if $_skip_next; then
            _msg="$_arg"
            _skip_next=false
            continue
        fi
        case "$_arg" in
            -m) _skip_next=true ;;
            -m*) _msg="${_arg#-m}" ;;
        esac
    done

    # Commit product (may fail if nothing to commit — that's OK)
    _product_exit=0
    pgit_product_git_run commit "$@" || _product_exit=$?

    # Check if process has anything to commit
    if ! pgit_process_has_staged; then
        exit $_product_exit
    fi

    # Commit process with sync message
    if [ -n "$_msg" ]; then
        _process_msg="sync: $_msg"
    else
        _process_msg="sync: process update"
    fi
    pgit_process_git_run commit -m "$_process_msg"

    # Success if either repo committed
    exit 0
}
