#!/usr/bin/env bats

# Test pgit commit nudging, pp commit, and auto-commit.

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_DIR="$(mktemp -d)"
    cd "$TEST_DIR"
    git init -q
    git commit --allow-empty -q -m "initial"
    pgit init
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "pgit commit shows nudge when process has staged changes" {
    echo "code" > app.js
    echo "# Claude" > CLAUDE.md

    pgit add .
    # Stage process file manually so we can test the nudge
    git --git-dir=.pgit/layers/process/.git --work-tree=. add CLAUDE.md

    run pgit commit -m "product change"
    [[ "$output" == *"process layer has staged changes"* ]]
}

@test "pgit commit does NOT nudge when process has no staged changes" {
    echo "code" > app.js
    pgit add .
    run pgit commit -m "product only"
    [[ "$output" != *"process layer has staged changes"* ]]
}

@test "pgit commit passes through to product repo" {
    echo "code" > app.js
    pgit add app.js
    pgit commit -m "add app"
    run git --git-dir=.git log --oneline -1
    [[ "$output" == *"add app"* ]]
}

@test "pnp commit commits both repos" {
    echo "code" > app.js
    echo "# Claude" > CLAUDE.md
    pgit add .

    pnp commit -m "dual commit"

    run git --git-dir=.git log --oneline -1
    [[ "$output" == *"dual commit"* ]]

    run git --git-dir=.pgit/layers/process/.git log --oneline -1
    [[ "$output" == *"sync: dual commit"* ]]
}

@test "pnp commit with no process changes only commits product" {
    echo "code" > app.js
    pgit add app.js
    run pnp commit -m "product only"
    [ "$status" -eq 0 ]

    run git --git-dir=.git log --oneline -1
    [[ "$output" == *"product only"* ]]
}

@test "pnp commit with only process changes commits process" {
    echo "# Claude" > CLAUDE.md
    pgit add CLAUDE.md
    run pnp commit -m "process only"
    [ "$status" -eq 0 ]

    run git --git-dir=.pgit/layers/process/.git log --oneline -1
    [[ "$output" == *"sync: process only"* ]]
}

@test "pp.auto-commit causes pgit commit to commit both" {
    pgit config pp.auto-commit true

    echo "code" > app.js
    echo "# Claude" > CLAUDE.md
    pgit add .
    pgit commit -m "auto both"

    run git --git-dir=.git log --oneline -1
    [[ "$output" == *"auto both"* ]]

    run git --git-dir=.pgit/layers/process/.git log --oneline -1
    [[ "$output" == *"auto both"* ]]
}

@test "pgit config reads and writes pp.auto-commit" {
    run pgit config pp.auto-commit
    [ "$output" = "" ]

    pgit config pp.auto-commit true
    run pgit config pp.auto-commit
    [ "$output" = "true" ]

    pgit config pp.auto-commit false
    run pgit config pp.auto-commit
    [ "$output" = "false" ]
}
