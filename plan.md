# DeepStep Implementation Plan

## Context

Building Milestone 1 (Proof of Concept): a custom WASM interpreter with single-column stepping UI and operand stack visualization. This is a greenfield React+TypeScript project.

## Current Status

- **Milestone**: M1 (Proof of Concept)
- **Phase**: Phase 0 not yet started — scaffolding needed
- **What's done**: Plan approved, no code written yet

## Execution Phases

### Phase 0: Project Scaffolding (sequential)
- Initialize Vite + React 18 + TypeScript (strict) + Tailwind (dark mode) + Zustand + Vitest
- Files: `package.json`, `tsconfig.json`, `vite.config.ts`, `vitest.config.ts`, `tailwind.config.ts`, `postcss.config.js`, `index.html`, `src/main.tsx`, `src/index.css`, `.gitignore`

### Phase 1: Core Types → then Parser, Interpreter, Snapshots in parallel

**Stream A — Types** (`src/core/wasm/types.ts`): All types first (ValType, Opcode enum, WasmInstruction, ControlFrame, WasmFunction, WasmModule, CallFrame, WasmState). Foundation for everything.

**Stream B — WAT Parser** (`src/core/wasm/parser.ts` + tests): Three-stage recursive descent — tokenizer → S-expression tree → WasmModule builder. Handles flat + folded WAT, `$name` resolution, block nesting → blockMap precomputation, comments.

**Stream C — Interpreter** (`src/core/wasm/interpreter.ts` + tests): Pure function `step(state) → state`. Data-driven dispatch table (`Record<Opcode, Handler>`). Immutable state helpers (pushOperand, popOperand, advancePc, setLocal). i32 ops wrap at 32 bits. Control flow uses blockMap for O(1) branch targets.

**Stream D — Snapshots** (`src/core/snapshot.ts` + tests): Lightweight — only deep-copies `Uint8Array` memory; all other state is already immutable/shared. Push/pop history with configurable max size (default 10,000).

### Phase 2: Store + Examples (after Phase 1)

**Stream E — Zustand Store** (`src/store/execution.ts`): Wires parser, interpreter, snapshot system. Actions: `loadWat`, `stepForward`, `stepBackward`, `reset`.

**Stream F — Examples** (`src/data/examples/*.ts`): 5 WAT programs as string constants — add, fibonacci, counter-loop, factorial, memory load/store. Each with id, name, description, source.

### Phase 3: UI (after Phase 2)
- `src/ui/panels/StackPanel.tsx` — operand stack visualization
- `src/ui/panels/MemoryPanel.tsx` — hex dump with read/write highlights
- `src/ui/panels/RegisterPanel.tsx` — locals/globals display with change highlighting
- `src/ui/controls/StepControls.tsx` — forward/back/reset buttons, step counter, status
- `src/ui/editor/CodeEditor.tsx` — textarea + example dropdown + load button
- `src/ui/columns/WasmColumn.tsx` — instruction list (current highlighted), panels
- `src/ui/layout/App.tsx` — grid layout (1 col for M1, expandable to 4), dark mode root

### Phase 4: Integration & Verification
- Wire all components together
- End-to-end smoke tests
- Cross-validate interpreter output against browser's native WASM engine

## Task Dependency Graph

```
Phase 0: Scaffold (Vite+React18+TS+Tailwind+Zustand+Vitest)
  → Phase 1A: Core types (src/core/wasm/types.ts)
    → Phase 1B: WAT Parser (parallel)
    → Phase 1C: Interpreter (parallel)
    → Phase 1D: Snapshots (parallel)
    → Phase 2B: Examples (parallel with 1B-1D)
      → Phase 2A: Zustand Store (needs 1B+1C+1D)
        → Phase 3: UI Components
          → Phase 4: Integration & Verification
```

## Key Technical Decisions

1. **Full S-expression parser** — handles nested blocks properly, ~310 lines total
2. **Handler dispatch table** not switch — data-driven design
3. **Always-copy memory in snapshots** — 64KB/snapshot, trivially correct, optimize later
4. **BlockMap precomputed at parse time** — O(1) branch resolution in interpreter
5. **No syntax highlighting in M1** — plain textarea, focus on execution viz
6. **CSS Grid layout** — `grid-cols-1` now, `grid-cols-4` later

## WASM Instructions Supported in M1

- **Control**: block, loop, br, br_if, if/else/end, return, call, nop, unreachable
- **Numeric**: i32.const, all i32 arithmetic/comparison ops
- **Variable**: local.get/set/tee, global.get/set
- **Memory**: i32.load, i32.store
- **Stack**: drop, select

## Parallelization Strategy

```
Step 1 (1 agent):  Scaffold + types.ts
Step 2 (3 agents): Parser | Interpreter | Snapshot  (all depend only on types)
Step 3 (2 agents): Store+Examples | UI components
Step 4 (1 agent):  Integration, wiring, smoke tests
```

## Verification

1. `npm run build` — compiles without errors
2. `npx vitest run` — all tests pass (parser, interpreter, snapshot, store, examples, UI smoke)
3. `npm run dev` — app loads, select example, click Load, step through, see instructions highlight and stack update
4. Cross-validate: run example WAT in browser's native WASM engine, compare final results with interpreter output

## Key Architecture Decisions

- Custom WASM interpreter (not browser native) for full introspection
- Pure functions, immutable state, TypeScript strict mode
- Data-driven dispatch table (not switch statements)
- BlockMap precomputed at parse time for O(1) branch targets
- Snapshot system deep-copies only Uint8Array memory
- WAT parser: tokenizer → S-expr tree → WasmModule (recursive descent)
- Dark mode default, CSS Grid layout (1 col M1, 4 cols later)

## Future: RISC-V Pipeline Visualizer

After M1, a natural evolution is replacing the Intel x86-64 / microcode layers with RISC-V and a pipeline visualizer:

- Replace Columns 3 & 4 (x86 + µops) with RISC-V instructions + pipeline stages
- Classic 5-stage pipeline: IF → ID → EX → MEM → WB
- Visualize hazards, stalls, forwarding paths
- RISC-V is open and regular — no proprietary microcode to approximate
- Pipeline depth is tunable (start 5-stage, go deeper later)
- See PRD Section 11 for full details
