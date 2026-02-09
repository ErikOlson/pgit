#!/usr/bin/env bats

# Test pgit adopt — converting an existing repo to pgit.

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_DIR="$(mktemp -d)"
    CONFIG_DIR="$(mktemp -d)"
    export XDG_CONFIG_HOME="$CONFIG_DIR"
    cd "$TEST_DIR"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
}

teardown() {
    rm -rf "$TEST_DIR" "$CONFIG_DIR"
}

@test "pgit adopt on repo with committed CLAUDE.md moves it to process" {
    echo "# Claude" > CLAUDE.md
    echo "code" > main.js
    git add CLAUDE.md main.js
    git commit -q -m "initial"

    # Adopt with --yes to skip interactive prompt
    run pgit adopt --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"1 process file"* ]]
    [[ "$output" == *"CLAUDE.md"* ]]
    [[ "$output" == *"moved"* ]]

    # CLAUDE.md should still exist on disk
    [ -f "CLAUDE.md" ]

    # Product repo should show CLAUDE.md as deleted (staged)
    run pgit status --porcelain
    [[ "$output" == *"D  CLAUDE.md"* ]] || [[ "$output" == *"D CLAUDE.md"* ]]

    # Process repo should have CLAUDE.md staged
    run pgit -p status --porcelain
    [[ "$output" == *"CLAUDE.md"* ]]
}

@test "pgit adopt on repo with committed .claude/ directory moves it to process" {
    mkdir -p .claude
    echo "{}" > .claude/settings.json
    echo "code" > app.py
    git add .claude/settings.json app.py
    git commit -q -m "initial"

    run pgit adopt --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *".claude/settings.json"* ]]

    # File still on disk
    [ -f ".claude/settings.json" ]

    # Product repo shows deletion staged
    run pgit status --porcelain
    [[ "$output" == *".claude/settings.json"* ]]
}

@test "pgit adopt with no process files still initializes" {
    echo "code" > main.rs
    git add main.rs
    git commit -q -m "initial"

    run pgit adopt --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"no tracked files match process patterns"* ]]

    # .pgit/ should exist
    [ -d ".pgit" ]
    [ -f ".pgit/config.json" ]
}

@test "pgit adopt with multiple process files moves all" {
    echo "# Claude" > CLAUDE.md
    echo "# Agents" > AGENTS.md
    echo "# Plan" > PLAN.md
    echo "code" > index.js
    git add CLAUDE.md AGENTS.md PLAN.md index.js
    git commit -q -m "initial"

    run pgit adopt --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"3 process file"* ]]

    # All files still on disk
    [ -f "CLAUDE.md" ]
    [ -f "AGENTS.md" ]
    [ -f "PLAN.md" ]
    [ -f "index.js" ]
}

@test "pgit adopt fails if already initialized" {
    echo "code" > main.js
    git add main.js
    git commit -q -m "initial"
    pgit init

    run pgit adopt --yes
    [ "$status" -ne 0 ]
    [[ "$output" == *"already initialized"* ]]
}

@test "pgit adopt fails without .git/" {
    rm -rf .git
    run pgit adopt --yes
    [ "$status" -ne 0 ]
    [[ "$output" == *"not a git repository"* ]]
}

@test "product repo after adopt is clean once committed" {
    echo "# Claude" > CLAUDE.md
    echo "code" > main.js
    git add CLAUDE.md main.js
    git commit -q -m "initial"

    pgit adopt --yes

    # Commit the removal from product
    pgit commit -q -m "adopt: remove process files"

    # Product should be clean (CLAUDE.md not tracked)
    run pgit status --porcelain
    [ -z "$output" ]

    # main.js still tracked in product
    run pgit log --oneline -- main.js
    [[ "$output" == *"initial"* ]]
}

@test "pgit adopt uses registry patterns" {
    # Add a custom pattern to registry
    pgit pp registry add "*.notes" custom

    echo "thoughts" > ideas.notes
    echo "code" > app.go
    git add ideas.notes app.go
    git commit -q -m "initial"

    run pgit adopt --yes
    [ "$status" -eq 0 ]
    [[ "$output" == *"ideas.notes"* ]]
}
