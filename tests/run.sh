#!/usr/bin/env sh

set -eu

for test in tests/*_test.lua; do
    echo "==> $test"
    nvim --headless -u NONE --cmd "set runtimepath^=." -l "$test"
    echo
done
