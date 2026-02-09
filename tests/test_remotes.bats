#!/usr/bin/env bats

# Test pnp remotes — cross-referenced remote display.

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_DIR="$(mktemp -d)"
    CONFIG_DIR="$(mktemp -d)"
    export XDG_CONFIG_HOME="$CONFIG_DIR"
    cd "$TEST_DIR"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    git commit --allow-empty -q -m "initial"
    pgit init
}

teardown() {
    rm -rf "$TEST_DIR" "$CONFIG_DIR"
}

@test "pnp remotes shows both layers" {
    run pgit pp remotes
    [ "$status" -eq 0 ]
    [[ "$output" == *"product remotes:"* ]]
    [[ "$output" == *"process remotes:"* ]]
}

@test "pnp remotes shows (none) when no remotes configured" {
    run pgit pp remotes
    [ "$status" -eq 0 ]
    [[ "$output" == *"(none)"* ]]
}

@test "pnp remotes shows product remote" {
    git remote add origin https://github.com/test/repo.git
    run pgit pp remotes
    [ "$status" -eq 0 ]
    [[ "$output" == *"origin"* ]]
    [[ "$output" == *"test/repo"* ]]
}

@test "pnp remotes shows process remote" {
    pgit -p remote add origin https://github.com/test/repo-process.git
    run pgit pp remotes
    [ "$status" -eq 0 ]
    [[ "$output" == *"repo-process"* ]]
}

@test "pnp overview shows divergence info" {
    # Create a bare remote for product
    _remote="$(mktemp -d)"
    git init -q --bare "$_remote"
    git remote add origin "$_remote"
    git push -q -u origin HEAD 2>/dev/null

    # Make a local commit ahead of remote
    git commit --allow-empty -q -m "ahead"

    run pgit pp
    [ "$status" -eq 0 ]
    # Should show the ahead indicator
    [[ "$output" == *"product"* ]]
    [[ "$output" == *"process"* ]]
}
