# Plan Format — Auto-Dev Execution Plan

The Planner Agent outputs a structured execution plan in this format.
The coordinator parses this to orchestrate Phase 3 (Execute).

## Format

```
## Task Overview

- **Goal**: [One sentence: what should be achieved]
- **Approach**: [2-3 sentences: how it will be done]

## Work Packages

### WP-1: [Descriptive Title]
- **Files**: [`path/to/file1.ts`, `path/to/file2.ts`]
- **Action**: create | modify | delete
- **Description**: [Detailed instructions for the Code Worker — what exactly to do]
- **Depends on**: [] (empty = independent)

### WP-2: [Descriptive Title]
- **Files**: [`path/to/file3.ts`]
- **Action**: modify
- **Description**: [Detailed instructions]
- **Depends on**: [WP-1]

### WP-3: [Descriptive Title]
- **Files**: [`path/to/file4.ts`, `path/to/file5.ts`]
- **Action**: modify
- **Description**: [Detailed instructions]
- **Depends on**: []

## Execution Order

- **Parallel Group 1**: WP-1, WP-3 (independent — run simultaneously)
- **Sequential after Group 1**: WP-2 (depends on WP-1)

## Review Strategy

- **Auto-checks**: test, lint, typecheck (only those available in the project)
- **Reviewers needed**: logic, quality (selected based on task type)
```

## Rules

1. **Strict file partitioning**: No file may appear in more than one work package
2. **Self-contained packages**: Each work package must be independently executable
3. **Explicit dependencies**: If WP-B needs changes from WP-A, declare `Depends on: [WP-A]`
4. **Concrete descriptions**: "Add a login endpoint that validates email/password against the users table and returns a JWT" — not "Implement login"
5. **Action types**: `create` (new file), `modify` (existing file), `delete` (remove file). A package can mix actions if they apply to different files.
