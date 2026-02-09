# pgit-config.sh — pgit config get/set (pp.* keys stored in .pgit/config)

pgit_config_get() {
    _key="$1"
    _config_file="$PGIT_DIR/config"
    if [ -f "$_config_file" ]; then
        _val=$(grep "^$_key=" "$_config_file" 2>/dev/null | head -1) || true
        echo "${_val#"$_key"=}"
    fi
}

pgit_config_set() {
    _key="$1"
    _value="$2"
    _config_file="$PGIT_DIR/config"

    if [ ! -f "$_config_file" ]; then
        echo "$_key=$_value" > "$_config_file"
    elif grep -q "^$_key=" "$_config_file" 2>/dev/null; then
        _tmp=$(mktemp)
        sed "s/^$_key=.*/$_key=$_value/" "$_config_file" > "$_tmp"
        mv "$_tmp" "$_config_file"
    else
        echo "$_key=$_value" >> "$_config_file"
    fi
}

pgit_config_cmd() {
    if [ $# -eq 0 ]; then
        if [ -f "$PGIT_DIR/config" ]; then
            cat "$PGIT_DIR/config"
        fi
        return
    fi
    if [ $# -eq 1 ]; then
        pgit_config_get "$1"
        return
    fi
    pgit_config_set "$1" "$2"
}
