#!/usr/bin/env bats

# Test pnp alias and pgit pp overview.

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_DIR="$(mktemp -d)"
    export XDG_CONFIG_HOME="$TEST_DIR/config"
    cd "$TEST_DIR"
    git init -q
    git commit --allow-empty -q -m "initial product commit"
    pgit init
    # Make an initial process commit too
    echo "# Claude" > CLAUDE.md
    git --git-dir=".pgit/layers/process/.git" --work-tree="." add CLAUDE.md
    git --git-dir=".pgit/layers/process/.git" --work-tree="." commit -q -m "initial process commit"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "pgit pp shows overview of both repos" {
    run pgit pp
    [ "$status" -eq 0 ]
    [[ "$output" == *"product"* ]]
    [[ "$output" == *"process"* ]]
    [[ "$output" == *"initial product commit"* ]]
    [[ "$output" == *"initial process commit"* ]]
}

@test "pgit pp shows branch names" {
    run pgit pp
    [[ "$output" == *"["* ]]
    [[ "$output" == *"]"* ]]
}

@test "pgit pp shows clean status" {
    run pgit pp
    [[ "$output" == *"clean"* ]]
}

@test "pgit pp shows dirty status when files modified" {
    echo "modified" >> CLAUDE.md
    run pgit pp
    [[ "$output" == *"dirty"* ]]
}

@test "pgit pp fails outside pgit directory" {
    OTHER_DIR="$(mktemp -d)"
    cd "$OTHER_DIR"
    git init -q
    run pgit pp
    [ "$status" -ne 0 ]
    [[ "$output" == *"not a pgit directory"* ]]
    rm -rf "$OTHER_DIR"
}
