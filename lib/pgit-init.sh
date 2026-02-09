# pgit-init.sh — pgit init, adopt, and add-to-process

pgit_init() {
    if [ ! -d ".git" ]; then
        pgit_die "not a git repository. Run 'git init' first."
    fi

    if [ -d ".pgit" ]; then
        pgit_die "already initialized (.pgit/ exists)."
    fi

    _root="$PWD"

    # Load patterns from registry
    pgit_load_registry_patterns

    # Build patterns list: registry patterns + .pgit/ (always included)
    _patterns="$PGIT_REGISTRY_PATTERNS"
    case "$_patterns" in
        *".pgit/"*) ;;
        *) _patterns="${_patterns}.pgit/
" ;;
    esac

    # Create directory structure
    mkdir -p ".pgit/layers/process"

    # Write config.json with registry-sourced patterns
    _old_ifs="$IFS"
    IFS='
'
    _json_patterns=""
    _display_patterns=""
    for _pat in $_patterns; do
        [ -z "$_pat" ] && continue
        if [ -n "$_json_patterns" ]; then
            _json_patterns="$_json_patterns,
        \"$_pat\""
        else
            _json_patterns="\"$_pat\""
        fi
        _display_patterns="$_display_patterns $_pat"
    done
    IFS="$_old_ifs"

    cat > ".pgit/config.json" << EOF
{
  "version": 1,
  "default_layer": "product",
  "layers": {
    "product": {
      "git_dir": ".git"
    },
    "process": {
      "git_dir": ".pgit/layers/process/.git",
      "patterns": [
        $_json_patterns
      ]
    }
  }
}
EOF

    # Initialize process repo
    git init --bare ".pgit/layers/process/.git" >/dev/null 2>&1
    git --git-dir=".pgit/layers/process/.git" config core.bare false
    git --git-dir=".pgit/layers/process/.git" config core.worktree "$_root"

    # Set PGIT_DIR/PGIT_ROOT so pgit_sync_excludes works
    PGIT_DIR="$_root/.pgit"
    PGIT_ROOT="$_root"

    # Generate info/exclude for both repos
    mkdir -p ".git/info"
    mkdir -p ".pgit/layers/process/.git/info"

    _exclude=".git/info/exclude"
    if [ -f "$_exclude" ]; then
        if grep -q "# pgit: process layer" "$_exclude" 2>/dev/null; then
            pgit_die "info/exclude already has pgit entries — this shouldn't happen."
        fi
    fi

    pgit_sync_excludes

    echo "pgit: initialized process layer in .pgit/"
    echo "  process patterns:$_display_patterns"
    echo "  product repo info/exclude updated"
    echo ""
    echo "Use 'pgit' for product, 'pgit -p' for process."
}

pgit_adopt() {
    if [ ! -d ".git" ]; then
        pgit_die "not a git repository. Run 'git init' first."
    fi
    if [ -d ".pgit" ]; then
        pgit_die "already initialized (.pgit/ exists). Use 'pgit add-to-process' to move individual files."
    fi

    _root="$PWD"

    # Load registry patterns
    pgit_load_registry_patterns

    # Build patterns list (same logic as init)
    _patterns="$PGIT_REGISTRY_PATTERNS"
    case "$_patterns" in
        *".pgit/"*) ;;
        *) _patterns="${_patterns}.pgit/
" ;;
    esac

    # Temporarily set globals for pgit_classify_file
    PGIT_PROCESS_PATTERNS="$_patterns"

    # Find tracked files that match process patterns
    _tracked=$(git ls-files)
    _process_files=""
    _process_count=0

    _old_ifs="$IFS"
    IFS='
'
    for _file in $_tracked; do
        [ -z "$_file" ] && continue
        _layer=$(pgit_classify_file "$_file")
        if [ "$_layer" = "process" ]; then
            _process_files="$_process_files$_file
"
            _process_count=$((_process_count + 1))
        fi
    done
    IFS="$_old_ifs"

    if [ "$_process_count" -eq 0 ]; then
        echo "pgit: no tracked files match process patterns."
        echo "Initializing pgit anyway (use 'pgit add-to-process' to move files later)."
        pgit_init
        return
    fi

    # Show proposed classification
    echo "pgit adopt: found $_process_count process file(s) tracked in product repo:"
    echo ""
    _old_ifs="$IFS"
    IFS='
'
    for _file in $_process_files; do
        [ -z "$_file" ] && continue
        echo "  $_file"
    done
    IFS="$_old_ifs"
    echo ""
    echo "These files will be:"
    echo "  1. Removed from product repo tracking (git rm --cached)"
    echo "  2. Added to the new process repo"
    echo "  3. Left on disk (not deleted)"
    echo ""

    # Check for --yes flag
    _confirmed=false
    for _arg in "$@"; do
        case "$_arg" in
            -y|--yes) _confirmed=true ;;
        esac
    done

    if ! $_confirmed; then
        printf "Proceed? [y/N] "
        read -r _answer
        case "$_answer" in
            [yY]|[yY][eE][sS]) ;;
            *) echo "pgit: adopt cancelled."; exit 0 ;;
        esac
    fi

    # Run init to set up .pgit/
    pgit_init

    # Now move process files: git rm --cached from product, git add to process
    _old_ifs="$IFS"
    IFS='
'
    for _file in $_process_files; do
        [ -z "$_file" ] && continue
        GIT_DIR="$_root/.git" GIT_WORK_TREE="$_root" git rm --cached -q "$_file" 2>/dev/null || true
        GIT_DIR="$_root/.pgit/layers/process/.git" GIT_WORK_TREE="$_root" git add -f "$_file" 2>/dev/null || true
    done
    IFS="$_old_ifs"

    echo ""
    echo "pgit adopt: moved $_process_count file(s) to process layer."
    echo "  Product repo has staged removals — commit with: pgit commit -m 'adopt: move process files'"
    echo "  Process repo has staged additions — commit with: pgit -p commit -m 'adopt: initial process tracking'"
    echo "  Or use: pnp commit -m 'adopt pgit'"
}

pgit_add_to_process() {
    if [ $# -eq 0 ]; then
        pgit_die "usage: pgit add-to-process <file> [<file> ...]"
    fi

    pgit_load_patterns
    _moved=0

    for _file in "$@"; do
        if [ ! -f "$_file" ]; then
            echo "pgit: skipping '$_file' (not a file)" >&2
            continue
        fi

        _subdir=$(pgit_get_subdir)
        _relfile="$_file"
        if [ -n "$_subdir" ]; then
            _relfile="$_subdir/$_file"
        fi

        pgit_product_git_run rm --cached -q "$_file" 2>/dev/null || true
        pgit_process_git_run add -f "$_file" 2>/dev/null || true

        echo "pgit: moved '$_relfile' from product to process"
        _moved=$((_moved + 1))
    done

    if [ "$_moved" -gt 0 ]; then
        echo "pgit: $_moved file(s) moved. Commit both repos to finalize."
    fi
}
