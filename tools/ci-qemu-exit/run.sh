#!/bin/bash

# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

case "${1:-}" in
    success) test_name=ci_exit_success ;;
    assertion-failure) test_name=ci_exit_assertion_failure ;;
    triple-fault) test_name=ci_exit_triple_fault ;;
    *) echo "usage: $0 success|assertion-failure|triple-fault" >&2; exit 2 ;;
esac

repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
log_dir="$repo_dir/target/ci-qemu-exit"
mkdir -p "$log_dir"
export OSDK_LOCAL_DEV=1
export QEMU_EXIT_STATUS_FILE="$log_dir/$1.qemu-status"
export QEMU_TRACE_FILE="$log_dir/$1.qemu.log"

set +e
(
    cd "$repo_dir/ostd"
    timeout 15m cargo osdk test "$test_name" --features ci_exit_repro \
        --qemu-exe "$repo_dir/tools/ci-qemu-exit/qemu.sh"
) 2>&1 | tee "$log_dir/$1.osdk.log"
statuses=("${PIPESTATUS[@]}")
set -e

printf '%s\n' "${statuses[0]}" > "$log_dir/$1.osdk-status"
printf 'OSDK exit status for %s: %s\n' "$1" "${statuses[0]}"
if [[ "${statuses[1]}" != 0 ]]; then
    echo "failed to capture OSDK output" >&2
    exit 2
fi
exit "${statuses[0]}"
