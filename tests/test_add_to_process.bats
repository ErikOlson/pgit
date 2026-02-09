#!/usr/bin/env bats

# Test pgit add-to-process — moving files from product to process tracking.

setup() {
    export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
    TEST_DIR="$(mktemp -d)"
    CONFIG_DIR="$(mktemp -d)"
    export XDG_CONFIG_HOME="$CONFIG_DIR"
    cd "$TEST_DIR"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    pgit init
}

teardown() {
    rm -rf "$TEST_DIR" "$CONFIG_DIR"
}

@test "pgit add-to-process moves tracked file from product to process" {
    echo "notes" > devnotes.md
    pgit add devnotes.md
    pgit commit -q -m "add notes"

    run pgit add-to-process devnotes.md
    [ "$status" -eq 0 ]
    [[ "$output" == *"moved"* ]]
    [[ "$output" == *"devnotes.md"* ]]

    # File still on disk
    [ -f "devnotes.md" ]

    # Product repo shows it removed (staged)
    run pgit status --porcelain
    [[ "$output" == *"D"*"devnotes.md"* ]]

    # Process repo shows it added (staged)
    run pgit -p status --porcelain
    [[ "$output" == *"devnotes.md"* ]]
}

@test "pgit add-to-process with multiple files" {
    echo "a" > file1.md
    echo "b" > file2.md
    pgit add file1.md file2.md
    pgit commit -q -m "add files"

    run pgit add-to-process file1.md file2.md
    [ "$status" -eq 0 ]
    [[ "$output" == *"2 file(s) moved"* ]]
}

@test "pgit add-to-process skips non-existent files" {
    run pgit add-to-process nonexistent.txt
    [[ "$output" == *"skipping"* ]]
}

@test "pgit add-to-process with no args shows usage" {
    run pgit add-to-process
    [ "$status" -ne 0 ]
    [[ "$output" == *"usage"* ]]
}

@test "pgit add-to-process requires pgit directory" {
    cd "$(mktemp -d)"
    git init -q
    echo "file" > test.txt

    run pgit add-to-process test.txt
    [ "$status" -ne 0 ]
}
