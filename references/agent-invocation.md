# Agent Invocation Standard

Central reference for using the **Agent** tool in all Codewright skills.

---

## 1. Starting Agents

Agents are started via the `Agent` tool in Claude Code. There are two modes:

### Read-Only (Explore)

For pure analysis without code changes:

```
Agent(
  subagent_type="Explore",
  prompt="Read the file agents/<name>.md and execute the instructions.
    Project: <PROJECT_ROOT>
    Context: <ADDITIONAL_CONTEXT>"
)
```

- The agent can read, search, and analyze files.
- It must **not** create or modify files.

### Code-Changing (Auto Mode)

For agents that are allowed to modify or create files:

```
Agent(
  mode="auto",
  prompt="Read the file agents/<name>.md and execute the instructions.
    Project: <PROJECT_ROOT>
    Files you may modify: <FILE_LIST>
    Context: <ADDITIONAL_CONTEXT>"
)
```

- The agent may read, create, and modify files.
- The allowed files must **always be explicitly** specified in the prompt.

---

## 2. Parallel Execution

Multiple agents can be started simultaneously in a single message block:

```
Agent(
  subagent_type="Explore",
  run_in_background=true,
  name="security-agent",
  prompt="..."
)

Agent(
  subagent_type="Explore",
  run_in_background=true,
  name="quality-agent",
  prompt="..."
)
```

- Start each agent with `run_in_background=true` and a unique `name`.
- Wait for **all** agents before merging the results.
- The order of completion is not guaranteed.

---

## 3. Return Format

Agents return their results as **Markdown text** in their last message. The coordinator reads this response and processes it further.

Expected format for findings:

```markdown
## Findings

### [SEVERITY] Short description
- **File:** path/to/file.ts
- **Line:** 42
- **Problem:** Description of the problem
- **Recommendation:** Suggested fix
```

---

## 4. No Findings

When an agent finds no issues, it must explicitly respond with this format:

```markdown
## Result

No findings in this area. The analyzed files are clean.

**Checked areas:** <list>
**Checked files:** <count>
```

Never return an empty response or just "all ok" — the structured indication of checked areas and file count is mandatory.

---

## 5. Error Handling

### Agent does not respond
- Wait a maximum of **5 minutes**.
- Then inform the user: which agent did not respond and which area is affected.

### Agent reports an error
- Check whether a required tool is unavailable.
- Offer the user to skip the affected area.
- Still evaluate the remaining results.

### Tool not installed
- The agent creates an **INFO** finding:

```markdown
### [INFO] Tool not available
- **Tool:** <tool-name>
- **Problem:** Tool X not available, area Y could not be checked.
- **Recommendation:** Install the tool or check the area manually.
```
