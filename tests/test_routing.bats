#!/usr/bin/env bats

# Test that process files are invisible to product repo and vice versa.

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_DIR="$(mktemp -d)"
    export XDG_CONFIG_HOME="$TEST_DIR/config"
    cd "$TEST_DIR"
    git init -q
    git commit --allow-empty -q -m "initial"
    pgit init
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "CLAUDE.md is invisible to pgit status" {
    echo "# Process file" > CLAUDE.md
    run pgit status --porcelain
    [ "$status" -eq 0 ]
    [[ "$output" != *"CLAUDE.md"* ]]
}

@test "CLAUDE.md is visible to pgit -p status" {
    echo "# Process file" > CLAUDE.md
    run pgit -p status --porcelain
    [ "$status" -eq 0 ]
    [[ "$output" == *"CLAUDE.md"* ]]
}

@test "source file is visible to pgit status" {
    mkdir -p src
    echo "fn main() {}" > src/main.rs
    run pgit status --porcelain
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/"* ]]
}

@test "source file is invisible to pgit -p status" {
    mkdir -p src
    echo "fn main() {}" > src/main.rs
    run pgit -p status --porcelain
    [ "$status" -eq 0 ]
    [[ "$output" != *"src/main.rs"* ]]
}

@test "PLAN.md routes to process" {
    echo "# Plan" > PLAN.md
    run pgit status --porcelain
    [[ "$output" != *"PLAN.md"* ]]
    run pgit -p status --porcelain
    [[ "$output" == *"PLAN.md"* ]]
}

@test "TASKS.md routes to process" {
    echo "# Tasks" > TASKS.md
    run pgit status --porcelain
    [[ "$output" != *"TASKS.md"* ]]
    run pgit -p status --porcelain
    [[ "$output" == *"TASKS.md"* ]]
}

@test ".claude/ directory routes to process" {
    mkdir -p .claude
    echo "{}" > .claude/settings.json
    run pgit status --porcelain
    [[ "$output" != *".claude"* ]]
    run pgit -p status --porcelain
    [[ "$output" == *".claude"* ]]
}

@test "mixed files: each visible only to its layer" {
    echo "product code" > app.js
    echo "# Process" > CLAUDE.md

    run pgit status --porcelain
    [[ "$output" == *"app.js"* ]]
    [[ "$output" != *"CLAUDE.md"* ]]

    run pgit -p status --porcelain
    [[ "$output" == *"CLAUDE.md"* ]]
    [[ "$output" != *"app.js"* ]]
}

@test "pgit -p with no args shows process status" {
    echo "# Process" > CLAUDE.md
    run pgit -p
    [ "$status" -eq 0 ]
    [[ "$output" == *"CLAUDE.md"* ]]
}
