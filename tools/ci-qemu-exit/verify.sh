#!/bin/bash

# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
log_dir="$repo_dir/target/ci-qemu-exit"

[[ $(< "$log_dir/success.qemu-status") == 33 ]]
[[ $(< "$log_dir/success.osdk-status") == 0 ]]
grep -q 'CI_EXIT_REPRO: successful control' "$log_dir/success.osdk.log"
grep -q 'All crates tested' "$log_dir/success.osdk.log"

[[ $(< "$log_dir/assertion-failure.qemu-status") == 65 ]]
[[ $(< "$log_dir/assertion-failure.osdk-status") == 1 ]]
grep -q 'CI_EXIT_REPRO: intentional assertion failure' "$log_dir/assertion-failure.osdk.log"

[[ $(< "$log_dir/triple-fault.qemu-status") == 0 ]]
[[ $(< "$log_dir/triple-fault.osdk-status") == 0 ]]
grep -q 'CI_EXIT_REPRO: about to triple fault' "$log_dir/triple-fault.osdk.log"
grep -qi 'triple fault' "$log_dir/triple-fault.qemu.log"
if grep -q 'All crates tested\|test result:' "$log_dir/triple-fault.osdk.log"; then
    echo "unexpected test completion after the triple fault" >&2
    exit 1
fi

[[ $(< "$log_dir/stack-overflow.qemu-status") == 0 ]]
[[ $(< "$log_dir/stack-overflow.osdk-status") == 0 ]]
grep -q 'CI_EXIT_REPRO: ordinary Rust recursion before stack overflow' \
    "$log_dir/stack-overflow.osdk.log"
grep -qi 'triple fault' "$log_dir/stack-overflow.qemu.log"
if grep -q 'All crates tested\|test result:' "$log_dir/stack-overflow.osdk.log"; then
    echo "unexpected test completion after the stack overflow" >&2
    exit 1
fi

summary='| Guest test | QEMU exit | OSDK exit | Runner completed |
| --- | --- | --- | --- |
| Successful control | 33 | 0 | Yes |
| Assertion failure | 65 | 1 | Failed |
| Triple fault | 0 | 0 | No |
| Stack overflow (#2264) | 0 | 0 | No |

Confirmed: OSDK accepts a triple fault or an ordinary kernel stack overflow
as a successful test run.'
printf '%s\n' "$summary"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    printf '%s\n' "$summary" >> "$GITHUB_STEP_SUMMARY"
fi
