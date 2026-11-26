Goal: connect to my Claude Design project, study it, and write a phased implementation plan for building the game in Flutter. Do NOT write app code in this session. The only output is the plan file.

## Step 1: Connect to Claude Design
- Use the Artifact tool. Call `action: "quickstart"` with `intent: "design"` to see how designs work. Then use `action: "list"` (scope "all") and `action: "list_types"` to find my design artifacts.
- If several designs could be the game, ask me which one. Otherwise pick the obvious match.
- Fetch the design with `action: "read"`. For a multi-file design, use `list_files` and `read_file` for every file. Also read the design system, and the comments (`action: "comments"`) if there are any.
- Inventory what you find: screens, components, states, flows, colors, typography, spacing, assets, animations, and game rules or mechanics.
- If the design leaves something about the game rules unclear, list it under "Open questions" in the plan instead of guessing.

## Step 2: Environment facts (already set up)
- Project directory: C:\Users\Administrator\Documents\dark (empty, not a git repo yet)
- Flutter 3.50.1 is at C:\src\flutter, and Git is at C:\src\git. Both are on PATH.
- The server is Windows Server 2019 with 1 CPU core and 8 GB RAM.
- There is no Android or Windows-desktop toolchain and no emulator, and I won't build APKs.
- The only verification is `flutter test`, mainly golden tests that compare the UI against the Claude Design screens, plus unit and widget tests.
- Keep every command light, because the machine has one core.

## Step 3: Write the plan
Save it to C:\Users\Administrator\Documents\dark\PLAN.md. The plan must be phased, and **each phase must fit in one Claude Code session**. Aim for a phase to be roughly 1 to 3 hours of work that can be finished and verified in one sitting. Split any phase that is bigger than that.

Suggested shape (adapt it to the design):
- Phase 0: project scaffold, folder structure, theme/design tokens from the design system, font and asset loading, and the golden-test harness (fixed surface size, real fonts loaded, a helper that compares against a design reference).
- Next phases: one slice at a time, such as core game logic and state with no UI and unit tests, then each screen or component group, then animation and interaction, then persistence, audio and polish.
- Last phase: full-flow integration, a golden sweep, and cleanup.

For EACH phase, give:
1. Goal, in one sentence.
2. Scope: the exact screens, components and logic included, and what is explicitly excluded.
3. Inputs: which Claude Design screens or files to read, and which earlier phases must be done.
4. Files to create or change.
5. Tasks as a checklist.
6. Verification: the exact `flutter test` commands, which golden files must match which design screens, and the done criteria.
7. Handoff notes: what the next session needs to know, such as decisions made or the state of the code.
8. A ready-to-paste starting prompt for the session that implements this phase.

Also include:
- An overview of the architecture (state management choice with the reason, folder layout, key packages) with a short justification. Prefer few dependencies.
- A dependency graph of the phases.
- A golden testing strategy: how the design references are exported into the repo, tolerance for differences, and font handling. Goldens must be generated and compared on this same OS.
- Risks and Open questions.

Finish by showing me a short summary of the phases and asking me to approve the plan before any implementation starts.
