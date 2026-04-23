# Plan Format — Brainstormer Implementation Plan

The Planner Agent outputs a structured implementation plan in this format.
The coordinator parses this to present to the user and store as artifact.

## Format

```
## Implementation Plan: [Title]

### Overview
- **Goal**: [One sentence: what should be achieved]
- **Approach**: [2-3 sentences: how it will be done]
- **Estimated Effort**: [S / M / L / XL with rough time estimate]
- **Based on Concept**: [Reference to concept section numbers]

### Work Packages

#### WP-1: [Descriptive Title]
- **Files**: [`path/to/file1.ts`, `path/to/file2.ts`]
- **Action**: create | modify | delete
- **Description**: [Detailed instructions — what exactly to do]
- **Depends on**: [] (empty = independent)
- **Estimated Effort**: [S / M / L]

#### WP-2: [Descriptive Title]
- **Files**: [`path/to/file3.ts`]
- **Action**: modify
- **Description**: [Detailed instructions]
- **Depends on**: [WP-1]
- **Estimated Effort**: [S / M / L]

### Execution Order

- **Parallel Group 1**: WP-1, WP-3 (independent — can be done simultaneously)
- **Sequential after Group 1**: WP-2 (depends on WP-1)

### Milestones

1. **Milestone 1**: [What is delivered] — includes WP-X, WP-Y
2. **Milestone 2**: [What is delivered] — includes WP-Z

### Testing Strategy
- [What should be tested and how]
- [Test coverage goals]

### Rollback Plan
- [How to undo the changes if something goes wrong]

### Open Questions
- [Any remaining questions that affect implementation]
```

## Rules

1. **Strict file partitioning**: No file may appear in more than one work package
2. **Self-contained packages**: Each work package must be independently describable
3. **Explicit dependencies**: If WP-B needs changes from WP-A, declare `Depends on: [WP-A]`
4. **Concrete descriptions**: "Add a login endpoint that validates email/password against the users table and returns a JWT" — not "Implement login"
5. **Action types**: `create` (new file), `modify` (existing file), `delete` (remove file)
6. **Effort estimation**: Use T-shirt sizes with clear meaning in the project context
