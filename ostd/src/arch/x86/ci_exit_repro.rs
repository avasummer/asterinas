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
