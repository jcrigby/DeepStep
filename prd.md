# DeepStep — Product Requirements Document

## 1. Overview

DeepStep is a browser-based interactive visualization tool that displays code execution across four abstraction levels simultaneously: WebAssembly bytecode, WASM VM internals, Intel x86-64 native instructions, and Intel microcode (µops). Execution state — registers, stacks, memory — updates in synchronized vertical columns as the user steps through their program.

## 2. Problem Statement

Modern developers routinely target WebAssembly without understanding how their code translates through the execution stack. Existing tools operate at a single level — browser DevTools show WASM, debuggers show native instructions, performance tools hint at µops — but nothing connects the layers into a coherent, visual narrative.

This gap creates real consequences: developers write WASM that performs poorly because they can't see the downstream effects of their choices. Students learn CPU architecture from static diagrams that never show real execution. Systems engineers context-switch between six different tools to trace a single instruction's journey.

## 3. Target Users

| Persona | Need |
|---|---|
| **CS Educators** | Teaching computer architecture, compilers, or systems programming with a live, interactive tool instead of static slides |
| **WASM Developers** | Understanding performance characteristics of their bytecode and how it maps to native execution |
| **Compiler Engineers** | Visualizing and debugging code generation across compilation stages |
| **Systems Programmers** | Gaining intuition for CPU microarchitecture behavior and µop scheduling |
| **Curious Developers** | Satisfying the "what really happens" itch with a tool that exposes every layer |

## 4. Core Concepts

### 4.1 The Four Columns

The UI is organized as four synchronized vertical columns, each representing an abstraction level:

**Column 1 — WebAssembly Bytecode (with Source Interleaving)**
- Disassembled WASM instructions (WAT format)
- **Original source lines (AssemblyScript, C, Rust) interleaved inline**, styled as dim/grayed annotations between WASM instructions — same pattern as `objdump -S`
- Source line mapping derived from DWARF debug info or source maps when available
- Current instruction highlighted; nearest source line provides human-readable context
- WASM operand stack visualization
- Local and global variable state
- Linear memory view (relevant segments)

**Column 2 — WASM VM Internals**
- VM dispatch/interpretation steps
- Internal VM state (instruction pointer, stack pointer, frame pointer)
- Operand stack as the VM sees it (typed values)
- Memory page state and bounds checking
- Function call frame stack

**Column 3 — Intel x86-64 Instructions**
- Native instructions generated from WASM execution
- General-purpose registers (RAX–R15)
- FLAGS register with individual flag bits
- Stack pointer and instruction pointer
- Native call stack

**Column 4 — Intel Microcode (µops)**
- Decoded micro-operations
- Execution unit assignment (ALU, AGU, load/store)
- µop queue / scheduler state (conceptual)
- Retirement state
- Pipeline stage indication (simplified)

### 4.2 Synchronization Model

The four columns are linked by a **mapping layer** that knows which WASM instruction corresponds to which VM operations, which native instructions, and which µops. Stepping at any level advances all columns to the corresponding state.

**Step granularity options:**
- **WASM-step**: Advance one WASM instruction; all lower columns advance to completion of that instruction
- **x86-step**: Advance one native instruction; WASM column may partially advance; µop column shows the full decode
- **µop-step**: Advance one micro-operation; higher columns hold position until the enclosing instruction completes
- **Free-run with breakpoints**: Execute continuously with pause conditions at any level

### 4.3 Register/State Panels

Each column has an associated state panel showing:
- Registers relevant to that level (with changed values highlighted)
- Stack contents (with push/pop animations)
- Memory view (with read/write highlights)
- A "delta" indicator showing what changed in the last step

## 5. Functional Requirements

### 5.1 Input & Loading

- **FR-1**: User can paste or upload a `.wasm` binary or `.wat` text file
- **FR-2**: User can select from a library of prebuilt examples (add, fibonacci, memory copy, function calls, loops, etc.)
- **FR-3**: User can write simple C/Rust/AssemblyScript in an embedded editor and compile to WASM via an integrated toolchain (stretch goal — may use server-side compilation or bundled wasm-based compiler)
- **FR-3a**: When source code is available (via editor input, uploaded source file, or DWARF/source map debug info in the .wasm binary), interleave source lines into the WASM column in the style of `objdump -S`
- **FR-3b**: Source lines displayed as dimmed/grayed annotations between corresponding WASM instructions; not interactive, purely contextual
- **FR-3c**: Support AssemblyScript, C, and Rust as source languages; source-to-WASM line mapping derived from debug info or compiler source maps

### 5.2 Execution Control

- **FR-4**: Step forward at any of the four granularity levels
- **FR-5**: Step backward (reverse execution via state snapshots)
- **FR-6**: Run to breakpoint at any level
- **FR-7**: Reset to beginning
- **FR-8**: Speed-controlled auto-play with configurable delay
- **FR-9**: Breakpoint support: break on WASM instruction, native instruction, specific register value, memory address access, or stack depth

### 5.3 Visualization

- **FR-10**: Four vertical columns with synchronized scrolling and highlighting
- **FR-11**: Register panels per column with change-highlighting (flash on write)
- **FR-12**: Stack visualizations per column with animated push/pop
- **FR-13**: Memory view with read (blue) / write (red) highlighting
- **FR-14**: Connection lines or color-coding showing which items across columns correspond to each other
- **FR-15**: Collapsible columns — user can hide levels they don't care about
- **FR-16**: Dark mode (default) and light mode

### 5.4 Microarchitecture Model

- **FR-17**: Microcode column uses a **pedagogical model** of Intel µop decomposition, not actual proprietary microcode (which is undocumented). The model should be based on publicly available information from Intel optimization manuals, Agner Fog's tables, and uops.info.
- **FR-18**: µop decomposition should be reasonably accurate for common instructions (MOV, ADD, MUL, memory operations, branches)
- **FR-19**: Display pipeline stage assignments (fetch, decode, execute, retire) as a simplified visualization
- **FR-20**: Show execution port assignments based on known port mappings for recent Intel microarchitectures (e.g., Alder Lake / Golden Cove)

### 5.5 Educational Features

- **FR-21**: Tooltip explanations on any instruction, register, or concept at any level
- **FR-22**: "Explain this step" button that generates a plain-English description of what just happened across all levels
- **FR-23**: Guided tutorials that walk through specific scenarios (e.g., "How a function call works across all four levels")

## 6. Non-Functional Requirements

- **NFR-1**: Runs entirely in the browser — no server required for core execution (compilation may require server)
- **NFR-2**: Responsive down to 1280px wide (four columns need horizontal space)
- **NFR-3**: Sub-16ms UI updates when stepping (60fps animations)
- **NFR-4**: State snapshots enable instant backward stepping (no re-execution)
- **NFR-5**: Works in Chrome, Firefox, Safari, Edge (latest versions)

## 7. Technical Architecture

### 7.1 WASM Execution Engine

A custom WASM interpreter written in TypeScript (or Rust compiled to WASM) that:
- Parses WASM binary format
- Executes instructions one at a time
- Exposes full internal state after each step
- Records state snapshots for reverse stepping

### 7.2 WASM → x86 Mapping

A translation layer that:
- Maps each WASM instruction to a plausible x86-64 instruction sequence
- Uses patterns based on real WASM engines (V8/SpiderMonkey JIT output analysis)
- Not a real compiler — a pedagogically accurate mapping engine

### 7.3 x86 → µop Mapping

A decomposition layer that:
- Breaks x86 instructions into µops based on published data (Agner Fog, uops.info)
- Assigns execution ports
- Models simplified pipeline behavior

### 7.4 Frontend

- React + TypeScript
- Column layout with synchronized scrolling
- Canvas or SVG for connection lines and animations
- State management via Zustand or similar (immutable state snapshots)

## 8. Data Model

```
ExecutionState {
  wasm: {
    pc: number                    // program counter (byte offset)
    instruction: WasmInstruction
    operandStack: TypedValue[]
    locals: TypedValue[]
    globals: TypedValue[]
    callStack: WasmFrame[]
    memory: ArrayBuffer
  }
  vm: {
    dispatchState: string
    internalRegisters: Record<string, number>
    frameStack: VMFrame[]
    heapPages: PageInfo[]
  }
  x86: {
    rip: bigint
    registers: Record<string, bigint>  // RAX-R15, RSP, RBP
    flags: FlagsRegister
    stack: Uint8Array
    instructions: x86Instruction[]
  }
  uops: {
    queue: MicroOp[]
    currentOp: MicroOp
    executionPorts: PortAssignment[]
    pipelineStage: PipelineStage
    retireBuffer: MicroOp[]
  }
}
```

## 9. Example Walkthrough

User loads a WASM module containing `i32.add` of two locals (compiled from AssemblyScript `let c: i32 = a + b`):

The WASM column shows the interleaved source:
```
;; let c: i32 = a + b;
  local.get 0        ◄ highlighted
  local.get 1
  i32.add
  local.set 2
```

| Step | WASM | VM | x86-64 | µops |
|---|---|---|---|---|
| 1 | `local.get 0` | Push local[0] to operand stack | `MOV EAX, [RBP-8]` | µop: load(AGU+load port) |
| 2 | `local.get 1` | Push local[1] to operand stack | `MOV ECX, [RBP-12]` | µop: load(AGU+load port) |
| 3 | `i32.add` | Pop two, push sum | `ADD EAX, ECX` | µop: add(ALU port 0/1) |
| 4 | `local.set 2` | Pop to local[2] | `MOV [RBP-16], EAX` | µop: store-addr(AGU) + store-data(store port) |

At each step, all four columns highlight the active item, registers show updated values, and stacks animate.

## 10. Milestones

| Phase | Scope | Target |
|---|---|---|
| **M1 — Proof of Concept** | WASM interpreter + single-column stepping with operand stack | 4 weeks |
| **M2 — Two Columns** | Add x86 mapping column with register visualization | 3 weeks |
| **M3 — Four Columns** | Add VM internals and µop columns, synchronization | 4 weeks |
| **M4 — Polish** | Animations, connection lines, tooltips, dark mode, examples library | 3 weeks |
| **M5 — Education** | Guided tutorials, "explain this step", shareable URLs | 3 weeks |

## 11. Open Questions

1. **Microcode accuracy vs. pedagogy**: How faithful should the µop model be? Real microcode is proprietary. Recommendation: optimize for teaching, cite sources, label it as "approximate model."
2. **WASM → x86 fidelity**: Should the x86 output mimic a specific engine (V8 TurboFan) or be a clean pedagogical mapping? Recommendation: start pedagogical, add "V8-style" and "SpiderMonkey-style" modes later.
3. **Compilation support**: Should users be able to write C/Rust and compile in-browser? Recommendation: defer to M5+, start with paste/upload of .wasm/.wat and curated examples.
4. **Mobile support**: Four columns on a phone is rough. Recommendation: tabbed view on mobile, one column at a time with swipe navigation.

## 12. Success Metrics

- GitHub stars as a proxy for developer interest (target: 1k in first 3 months)
- Educational adoption: at least 3 university courses link to it in first year
- Completion rate on guided tutorials > 60%
- User session length > 5 minutes (indicates genuine exploration, not bounce)
