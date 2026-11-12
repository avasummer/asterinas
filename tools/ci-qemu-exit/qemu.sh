#!/bin/bash

# SPDX-License-Identifier: MPL-2.0

set -eu

: "${QEMU_EXIT_STATUS_FILE:?}"
: "${QEMU_TRACE_FILE:?}"

status=0
qemu-system-x86_64 "$@" -accel tcg -d int,cpu_reset -D "$QEMU_TRACE_FILE" || status=$?
printf '%s\n' "$status" > "$QEMU_EXIT_STATUS_FILE"
exit "$status"
