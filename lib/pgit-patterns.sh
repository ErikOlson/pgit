# pgit-patterns.sh — pattern loading, matching, classification, exclude sync

pgit_load_patterns() {
    _config="$PGIT_DIR/config.json"
    PGIT_PROCESS_PATTERNS=""
    _in_patterns=0
    while IFS= read -r _line; do
        case "$_line" in
            *'"patterns"'*)
                _in_patterns=1
                continue
                ;;
        esac
        if [ "$_in_patterns" -eq 1 ]; then
            case "$_line" in
                *']'*)
                    _in_patterns=0
                    continue
                    ;;
                *)
                    _pat=$(echo "$_line" | sed -n 's/.*"\([^"]*\)".*/\1/p')
                    if [ -n "$_pat" ]; then
                        PGIT_PROCESS_PATTERNS="${PGIT_PROCESS_PATTERNS}${_pat}
"
                    fi
                    ;;
            esac
        fi
    done < "$_config"
}

# Classify a file path (relative to project root) as "process" or "product".
# Last matching pattern wins; negation (!) overrides.
pgit_classify_file() {
    _file="$1"
    _result="product"

    _old_ifs="$IFS"
    IFS='
'
    for _pat in $PGIT_PROCESS_PATTERNS; do
        case "$_pat" in
            '!'*)
                _pos="${_pat#!}"
                if pgit_match_pattern "$_file" "$_pos"; then
                    _result="product"
                fi
                ;;
            *)
                if pgit_match_pattern "$_file" "$_pat"; then
                    _result="process"
                fi
                ;;
        esac
    done
    IFS="$_old_ifs"

    echo "$_result"
}

# Returns 0 if file matches pattern.
# Rules follow gitignore conventions:
#   pattern/  -> directory (matches dir and contents)
#   */pattern -> path-specific match
#   pattern   -> basename match (no slash in pattern)
pgit_match_pattern() {
    _file="$1"
    _pattern="$2"

    case "$_pattern" in
        */)
            _dir="${_pattern%/}"
            case "$_file" in
                "$_dir"/*|"$_dir") return 0 ;;
            esac
            ;;
        */*)
            case "$_file" in
                $_pattern) return 0 ;;
            esac
            ;;
        *)
            _base="${_file##*/}"
            case "$_base" in
                $_pattern) return 0 ;;
            esac
            ;;
    esac
    return 1
}

# Regenerate info/exclude files from config.json patterns.
pgit_sync_excludes() {
    pgit_load_patterns

    _old_ifs="$IFS"
    IFS='
'

    # Collect directories that have negated children.
    # Git skips excluded directories entirely, so we must use dir/**
    # instead of dir/ when a negation exists for a file inside it.
    _negated_dirs=""
    for _pat in $PGIT_PROCESS_PATTERNS; do
        case "$_pat" in
            '!'*/*)
                _pos="${_pat#!}"
                _ndir="${_pos%/*}"
                _negated_dirs="$_negated_dirs|$_ndir"
                ;;
        esac
    done

    # --- Product repo info/exclude ---
    _exclude="$PGIT_ROOT/.git/info/exclude"
    if [ -f "$_exclude" ]; then
        _tmp=$(mktemp)
        sed '/^# pgit: process layer/,$d' "$_exclude" > "$_tmp"
        mv "$_tmp" "$_exclude"
    fi
    {
        echo "# pgit: process layer patterns (auto-generated, do not edit)"
        for _pat in $PGIT_PROCESS_PATTERNS; do
            [ -z "$_pat" ] && continue
            case "$_pat" in
                '!'*)
                    echo "$_pat"
                    ;;
                */)
                    _dir="${_pat%/}"
                    case "$_negated_dirs" in
                        *"|$_dir"|*"|$_dir"*|"$_dir")
                            echo "$_dir/**"
                            ;;
                        *)
                            echo "$_pat"
                            ;;
                    esac
                    ;;
                *)
                    echo "$_pat"
                    ;;
            esac
        done
    } >> "$_exclude"

    # --- Process repo info/exclude ---
    _process_exclude="$PGIT_DIR/layers/process/.git/info/exclude"
    {
        echo "# pgit: product layer exclusions (auto-generated)"
        echo "*"
        for _pat in $PGIT_PROCESS_PATTERNS; do
            [ -z "$_pat" ] && continue
            case "$_pat" in .pgit|.pgit/) continue ;; esac
            case "$_pat" in
                '!'*)
                    _pos="${_pat#!}"
                    echo "$_pos"
                    ;;
                */)
                    _dir="${_pat%/}"
                    echo "!$_dir/"
                    echo "!$_dir/**"
                    ;;
                *)
                    echo "!$_pat"
                    ;;
            esac
        done
    } > "$_process_exclude"

    IFS="$_old_ifs"
}
