// SPDX-License-Identifier: MPL-2.0

//! Opt-in reproductions for the host-side QEMU exit-status classifier.

use crate::prelude::ktest;

#[ktest]
fn ci_exit_success() {
    crate::early_println!("CI_EXIT_REPRO: successful control");
}

#[ktest]
fn ci_exit_assertion_failure() {
    panic!("CI_EXIT_REPRO: intentional assertion failure");
}

#[inline(never)]
fn recurse_until_stack_overflow(depth: usize) -> usize {
    let frame = [depth as u8; 1024];
    core::hint::black_box(&frame);
    let result = if depth == 0 {
        0
    } else {
        recurse_until_stack_overflow(depth - 1)
    };
    core::hint::black_box(&frame);
    result
}

#[ktest]
fn ci_exit_stack_overflow() {
    crate::early_println!("CI_EXIT_REPRO: ordinary Rust recursion before stack overflow");

    // An ordinary unbounded recursion exhausts the task's kernel stack. Without a
    // valid stack for the page-fault handler, the fault escalates to a triple fault.
    core::hint::black_box(recurse_until_stack_overflow(usize::MAX));
}

#[ktest]
fn ci_exit_triple_fault() {
    #[repr(C, packed)]
    struct EmptyIdt {
        limit: u16,
        base: u64,
    }

    let empty_idt = EmptyIdt { limit: 0, base: 0 };
    let _irq_guard = crate::irq::disable_local();
    crate::early_println!("CI_EXIT_REPRO: about to triple fault; test cannot complete");

    // With no valid IDT entries, #BP, #GP, and #DF delivery fail in succession.
    // SAFETY: This opt-in test runs only in a disposable QEMU guest. The IDT descriptor
    // remains readable through `lidt`; no Rust code executes after the forced shutdown.
    unsafe {
        core::arch::asm!(
            "lidt [{}]",
            "int3",
            in(reg) &empty_idt,
            options(noreturn),
        );
    }
}
