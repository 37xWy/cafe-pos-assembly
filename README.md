# ☕ Smart Cafe POS System – bare-metal x86 Assembly

A robust, terminal-based Point of Sale (POS) application written entirely in 32-bit x86 Assembly for Linux. This project demonstrates low-level system architecture, memory management, and hardware-level arithmetic by processing live sales, applying conditional discounts, managing role-based access, and generating financial shift reports without relying on any high-level standard libraries.

## 🧠 Technical Highlights

* **Bare-Metal System Calls:** Utilizes Linux `int 0x80` kernel interrupts exclusively for all standard I/O operations (`sys_read`, `sys_write`), managing file descriptors directly through the `EAX`, `EBX`, `ECX`, and `EDX` hardware registers.
* **Hardware-Level Arithmetic & Currency Formatting:** Avoids floating-point inaccuracies by tracking all financial data natively in integers (cents). Implements a custom integer-to-ASCII (itoa) algorithm, utilizing `div` routines and LIFO stack `push`/`pop` operations to dynamically format and print decimals (e.g., converting `1250` to `$12.50`).
* **Buffer Overflow Protection & `stdin` Flushing:** Implements an oversized 100-byte input buffer (`resb 100`) that safely absorbs extraneous newline characters (`\n`) from the Standard Input queue, preventing infinite looping during validation checks.
* **Register Slicing & Signed Branching:** Optimizes memory reads by targeting specific register subdivisions (e.g., `mov al, [choice]`) for single-character authentication checks. Utilizes Signed Jumps (`jl`) for discount arithmetic to ensure stability in the event of negative integer underflows.

## ⚙️ Environment & Requirements

This program requires a **Linux environment** (native, WSL, or VM) and the **Netwide Assembler (NASM)**.

If you are running a 64-bit Linux distribution, you will need the multilib package installed to link 32-bit executables (e.g., `sudo apt-get install gcc-multilib` on Debian/Ubuntu).

## 🚀 How to Run

1. Clone the repository and navigate to the directory.
2. **Assemble** the `.asm` file into a 32-bit object file:
   ```bash
   nasm -f elf32 pos.asm -o pos.o
