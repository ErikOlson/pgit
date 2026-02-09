#!/usr/bin/env bats

# Test pgit add smart routing.

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

@test "pgit add . stages product files in product repo" {
    echo "code" > app.js
    pgit add .
    run git --git-dir=.git --work-tree=. diff --cached --name-only
    [[ "$output" == *"app.js"* ]]
}

@test "pgit add . stages process files in process repo" {
    echo "# Claude" > CLAUDE.md
    pgit add .
    run git --git-dir=.pgit/layers/process/.git --work-tree=. diff --cached --name-only
    [[ "$output" == *"CLAUDE.md"* ]]
}

@test "pgit add . routes mixed files to correct repos" {
    echo "code" > app.js
    echo "# Claude" > CLAUDE.md
    pgit add .

    run git --git-dir=.git --work-tree=. diff --cached --name-only
    [[ "$output" == *"app.js"* ]]
    [[ "$output" != *"CLAUDE.md"* ]]

    run git --git-dir=.pgit/layers/process/.git --work-tree=. diff --cached --name-only
    [[ "$output" == *"CLAUDE.md"* ]]
    [[ "$output" != *"app.js"* ]]
}

@test "pgit add CLAUDE.md stages in process repo only" {
    echo "# Claude" > CLAUDE.md
    pgit add CLAUDE.md

    # Should be in process
    run git --git-dir=.pgit/layers/process/.git --work-tree=. diff --cached --name-only
    [[ "$output" == *"CLAUDE.md"* ]]

    # Should NOT be in product
    run git --git-dir=.git --work-tree=. diff --cached --name-only
    [[ "$output" != *"CLAUDE.md"* ]]
}

@test "pgit add src/app.js stages in product repo only" {
    mkdir -p src
    echo "code" > src/app.js
    pgit add src/app.js

    # Should be in product
    run git --git-dir=.git --work-tree=. diff --cached --name-only
    [[ "$output" == *"src/app.js"* ]]

    # Should NOT be in process
    run git --git-dir=.pgit/layers/process/.git --work-tree=. diff --cached --name-only
    [[ "$output" != *"src/app.js"* ]]
}

@test "pgit add routes PLAN.md to process" {
    echo "# Plan" > PLAN.md
    pgit add PLAN.md
    run git --git-dir=.pgit/layers/process/.git --work-tree=. diff --cached --name-only
    [[ "$output" == *"PLAN.md"* ]]
}

@test "pgit add routes .agent-log files to process" {
    echo "log" > build.agent-log
    pgit add build.agent-log
    run git --git-dir=.pgit/layers/process/.git --work-tree=. diff --cached --name-only
    [[ "$output" == *"build.agent-log"* ]]
}

@test "pgit add multiple files routes each correctly" {
    echo "code" > main.go
    echo "# Claude" > CLAUDE.md
    echo "# Tasks" > TASKS.md
    pgit add main.go CLAUDE.md TASKS.md

    run git --git-dir=.git --work-tree=. diff --cached --name-only
    [[ "$output" == *"main.go"* ]]

    run git --git-dir=.pgit/layers/process/.git --work-tree=. diff --cached --name-only
    [[ "$output" == *"CLAUDE.md"* ]]
    [[ "$output" == *"TASKS.md"* ]]
}
