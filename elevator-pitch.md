# DeepStep: Multi-Level Execution Visualizer

## Elevator Pitch

Ever tried to explain to someone what *actually happens* when code runs? Not the hand-wavy "it compiles down to machine code" answer — the real, full-stack answer?

**DeepStep** is an interactive visualization tool that shows code execution across four simultaneous abstraction levels, displayed as synchronized vertical columns:

1. **WebAssembly** — the portable bytecode stepping through its stack machine
2. **WASM VM Internals** — the runtime's interpretation layer, memory management, and operand stack
3. **Intel x86-64 Instructions** — the native instructions the CPU actually fetches and decodes
4. **Intel Microcode (µops)** — the micro-operations the CPU *really* executes internally

As you step through execution, every column advances in lockstep. Registers update. Stacks push and pop. Memory lights up. You see — *really see* — how a single `i32.add` in WASM becomes a VM dispatch, becomes a native `ADD`, becomes a sequence of micro-ops flowing through execution units.

**Who is this for?** Systems programmers, CS educators, compiler engineers, and the mass of curious developers who want to understand the machine beneath the abstraction. There's nothing like it.

**Why now?** WASM is eating the world — browsers, edge compute, serverless, plugins. Millions of developers are targeting WASM without understanding the layers below. Meanwhile, CPU microarchitecture matters more than ever for performance work, yet remains invisible and mystifying.

Like `objdump -S` interleaves C source with assembly, DeepStep interleaves your original source (AssemblyScript, C, Rust) directly into the WASM column — grayed-out context lines between the bytecode instructions so you always know *which line of code* produced *which instructions* without breaking your eye flow.

**DeepStep makes the invisible visible.** Four columns. One execution. Every layer exposed.
