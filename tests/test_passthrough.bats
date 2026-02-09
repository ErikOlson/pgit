#!/usr/bin/env bats

# Test that pgit in a non-pgit directory passes through to git identically.

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_DIR="$(mktemp -d)"
    export XDG_CONFIG_HOME="$TEST_DIR/config"
    cd "$TEST_DIR"
    git init -q
    git commit --allow-empty -q -m "initial"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "pgit in non-pgit dir passes through to git" {
    run pgit status
    [ "$status" -eq 0 ]
    [[ "$output" == *"nothing to commit"* ]]
}

@test "pgit log in non-pgit dir matches git log" {
    expected="$(git log --oneline)"
    run pgit log --oneline
    [ "$status" -eq 0 ]
    [ "$output" = "$expected" ]
}

@test "pgit --version prints version" {
    run pgit --version
    [ "$status" -eq 0 ]
    [[ "$output" == "pgit "* ]]
}

@test "pgit --help prints usage" {
    run pgit --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"usage:"* ]]
}
