# claude.md — DeepStep Project Context

## Project Summary

DeepStep is a browser-based interactive visualization tool that shows code execution across four synchronized vertical columns: WebAssembly bytecode, WASM VM internals, Intel x86-64 instructions, and Intel microcode (µops). Users step through execution and watch registers, stacks, and memory update at every abstraction level simultaneously.

## Tech Stack

- **Frontend**: React 18+ with TypeScript
- **State Management**: Zustand (immutable snapshots for reverse stepping)
- **Rendering**: HTML/CSS for columns and panels; Canvas or SVG for connection lines and animations
- **WASM Interpreter**: Custom TypeScript implementation (not using browser's native WASM engine — we need full introspection)
- **Build**: Vite
- **Testing**: Vitest + React Testing Library
- **Styling**: Tailwind CSS, dark mode default

## Architecture

```
src/
├── core/                    # Execution engines (no UI dependencies)
│   ├── wasm/                # WASM binary parser and step-by-step interpreter
│   │   ├── parser.ts        # Binary format → internal IR
│   │   ├── interpreter.ts   # Single-step execution engine
│   │   ├── types.ts         # WASM types, instructions, modules
│   │   ├── validation.ts    # Module validation
│   │   └── source-map.ts    # Source line ↔ WASM instruction mapping (DWARF / source maps)
│   ├── vm/                  # VM-level abstraction (dispatch, frames, memory management)
│   │   ├── dispatch.ts      # Instruction dispatch modeling
│   │   └── memory.ts        # Page-level memory model
│   ├── x86/                 # WASM → x86-64 mapping
│   │   ├── mapper.ts        # Instruction-level translation
│   │   ├── registers.ts     # x86 register file model
│   │   └── instructions.ts  # x86 instruction definitions
│   ├── uops/                # x86 → µop decomposition
│   │   ├── decomposer.ts    # Instruction → µop breakdown
│   │   ├── ports.ts         # Execution port assignment model
│   │   └── pipeline.ts      # Simplified pipeline stage model
│   ├── sync/                # Cross-level synchronization
│   │   ├── mapping.ts       # Maps items across all four levels
│   │   └── stepper.ts       # Unified stepping logic (step at any level, advance all)
│   └── snapshot.ts          # State snapshot/restore for reverse stepping
├── ui/
│   ├── columns/             # The four main columns
│   │   ├── WasmColumn.tsx
│   │   ├── VMColumn.tsx
│   │   ├── X86Column.tsx
│   │   └── UopsColumn.tsx
│   ├── panels/              # Register, stack, memory sub-panels
│   │   ├── RegisterPanel.tsx
│   │   ├── StackPanel.tsx
│   │   └── MemoryPanel.tsx
│   ├── controls/            # Playback controls, breakpoints
│   │   ├── StepControls.tsx
│   │   └── BreakpointManager.tsx
│   ├── connections/         # Cross-column linking visuals
│   │   └── ConnectionLines.tsx
│   ├── editor/              # WAT/WASM input area
│   │   └── CodeEditor.tsx
│   └── layout/
│       └── App.tsx
├── data/
│   ├── examples/            # Prebuilt .wat example programs
│   ├── uop-tables/          # µop decomposition data (sourced from Agner Fog / uops.info)
│   └── x86-patterns/        # WASM → x86 translation patterns
└── store/
    └── execution.ts         # Zustand store for full execution state
```

## Key Design Decisions

### The interpreter must be custom
We cannot use the browser's built-in WASM engine because we need full visibility into every internal state transition. The interpreter lives in `core/wasm/` and executes one instruction at a time, exposing operand stack, locals, globals, memory, and call frames after each step.

### Source interleaving follows the objdump -S pattern
When source code is available (AssemblyScript, C, Rust), we interleave source lines directly into the WASM column as dimmed/grayed annotations between bytecode instructions — exactly how `objdump -S` shows C source between assembly lines. This is NOT a separate column or panel. Source lines are non-interactive context annotations. The mapping comes from DWARF debug info (for C/Rust via Emscripten/wasm-pack) or compiler source maps (for AssemblyScript). When no source is available, the WASM column just shows bytecode. The `core/wasm/source-map.ts` module handles all source ↔ instruction mapping.

### Microcode is pedagogical, not real
Intel microcode is proprietary and undocumented. Our µop decomposition is based on publicly available data from:
- Agner Fog's instruction tables (https://agner.org/optimize/)
- uops.info measured data
- Intel Software Optimization Manual
Label it clearly in the UI as an "approximate model based on published data."

### x86 mapping is pedagogical first
The WASM → x86 mapping is not a real JIT compiler. It produces plausible x86 sequences that help users understand the translation. Patterns are stored as data in `data/x86-patterns/` so they're easy to review and update.

### State snapshots enable reverse stepping
Every step records a full immutable state snapshot. Stepping backward just restores the previous snapshot. Memory-intensive but correctness is trivial. Consider snapshot compression if memory becomes an issue.

## Agent Usage

- **Always use the Task tool** to delegate work to subagents rather than doing everything in the main context. The main Claude instance should orchestrate, not execute. This prevents context window exhaustion on a large, multi-file project like this.
- Use parallel Task calls for independent work (e.g., building core/wasm and core/x86 simultaneously).
- Reserve the main context for coordination, user interaction, and reviewing subagent results.

## Coding Conventions

- All core engine code must be **pure functions with no side effects** — takes state in, returns new state out
- State is **immutable** — never mutate, always create new objects
- TypeScript **strict mode**, no `any` types in core
- Each column component receives execution state as props — columns are pure renderers
- Use `BigInt` for 64-bit register values
- Test core engines thoroughly — the UI is only as good as the execution model
- Prefer data-driven design: instruction behaviors, µop tables, and x86 patterns should be declarative data, not hardcoded switch statements

## Important Context

- **Four columns must stay synchronized.** The mapping layer in `core/sync/` is the most critical and complex piece. Get this right first.
- **Performance matters for the UI** — stepping should feel instant. Pre-compute mappings when a module is loaded, not during stepping.
- **Don't over-model the pipeline.** The µop pipeline visualization is for intuition, not cycle-accurate simulation. Show fetch → decode → execute → retire as conceptual stages. Do not attempt to model out-of-order execution, branch prediction, or cache hierarchy (yet).
- **WAT is the display format.** Even if the user uploads a `.wasm` binary, disassemble it to WAT for display.

## Example Data Flow

When user clicks "Step (WASM level)":

1. `core/wasm/interpreter.ts` executes one WASM instruction, returns new WasmState
2. `core/sync/mapping.ts` looks up corresponding VM operations, x86 instructions, and µops
3. `core/sync/stepper.ts` computes complete `ExecutionState` across all four levels
4. `store/execution.ts` pushes new state (old state becomes snapshot for reverse)
5. All four column components re-render with new highlighted instructions and updated registers

## References

- WebAssembly spec: https://webassembly.github.io/spec/
- WASM binary format: https://webassembly.github.io/spec/core/binary/
- Agner Fog instruction tables: https://agner.org/optimize/
- uops.info: https://uops.info/
- Intel 64 and IA-32 Software Developer Manuals: https://www.intel.com/sdm
- "WebAssembly: Neither Web Nor Assembly" (talk by Ben Titzer) — good mental model for VM internals
