# Concept Format — Brainstormer

The Concept Developer Agent outputs a structured concept document in this format.
The coordinator parses this and passes it to the Planner and Reviewers.

## Format

```
## Concept: [Title]

### 1. Goals
- **Primary Goal**: [The main thing this should achieve]
- **Secondary Goals**: [Additional objectives]
- **Non-Goals / Out of Scope**: [What is explicitly NOT included]

### 2. Assumptions
- [Assumption about user behavior, system state, or environment]
- [Assumption about existing infrastructure]
- [Assumption about data volume or load]

### 3. Constraints
- [Technical constraint]
- [Business or time constraint]
- [Regulatory or compliance constraint]

### 4. Components

#### Component: [Name]
- **Responsibility**: [What this component does]
- **Inputs**: [What it receives]
- **Outputs**: [What it produces]
- **Dependencies**: [Other components it relies on]
- **Technology**: [Recommended stack/library]

### 5. Data Flow
[Step-by-step description or diagram of how data moves through the system]

### 6. Interfaces / APIs

#### [Interface Name]
- **Type**: [REST / GraphQL / gRPC / Function / Event / etc.]
- **Purpose**: [What it does]
- **Input**: [Schema or shape]
- **Output**: [Schema or shape]
- **Error Cases**: [What can go wrong]

### 7. Error Handling & Edge Cases
- [Scenario]: [How it should be handled]
- [Scenario]: [How it should be handled]

### 8. Security Considerations
- [Authentication/Authorization approach]
- [Data protection measures]
- [Input validation strategy]

### 9. Performance Considerations
- [Expected load]
- [Caching strategy]
- [Scaling approach]

### 10. Open Questions / Risks
- [Risk]: [Mitigation or open question]
```

## Rules

1. **Concrete over vague**: "Use Redis for session caching with 1h TTL" — not "use caching"
2. **Every component must have a clear responsibility**
3. **Every interface must specify error cases**
4. **Assumptions must be explicit** — hidden assumptions are risks
5. **Non-goals are mandatory** — scope clarity prevents creep
