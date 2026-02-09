#!/usr/bin/env bats

# Test pattern negation routing.

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
    git init -q
    git commit --allow-empty -q -m "initial"
    pgit init

    # Add a negation pattern: .claude/settings.json → product
    # Insert before the closing ] in the patterns array
    _config=".pgit/config.json"
    _tmp=$(mktemp)
    sed 's|"\.pgit/"|"!.claude/settings.json",\
        ".pgit/"|' "$_config" > "$_tmp"
    mv "$_tmp" "$_config"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "negation pattern routes .claude/settings.json to product" {
    mkdir -p .claude
    echo "{}" > .claude/settings.json
    pgit add .claude/settings.json

    # Should be in product
    run git --git-dir=.git --work-tree=. diff --cached --name-only
    [[ "$output" == *".claude/settings.json"* ]]

    # Should NOT be in process
    run git --git-dir=.pgit/layers/process/.git --work-tree=. diff --cached --name-only
    [[ "$output" != *".claude/settings.json"* ]]
}

@test "other .claude/ files still route to process" {
    mkdir -p .claude
    echo "{}" > .claude/commands.json
    pgit add .claude/commands.json

    run git --git-dir=.pgit/layers/process/.git --work-tree=. diff --cached --name-only
    [[ "$output" == *".claude/commands.json"* ]]
}
