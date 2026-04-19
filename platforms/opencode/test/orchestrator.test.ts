import { describe, it, expect, mock } from "bun:test"
import { formatResults } from "../src/orchestrator"
import type { AgentResult } from "../src/types"

describe("formatResults", () => {
  it("formats successful results", () => {
    const results: AgentResult[] = [
      {
        name: "logic-reviewer",
        response: "### [LOGIC] Off-by-one\n- **Severity**: blocking",
        success: true,
        durationMs: 12345,
      },
      {
        name: "security-reviewer",
        response: "No findings.",
        success: true,
        durationMs: 8000,
      },
    ]

    const output = formatResults(results)

    expect(output).toContain("## logic-reviewer [OK, 12.3s]")
    expect(output).toContain("### [LOGIC] Off-by-one")
    expect(output).toContain("## security-reviewer [OK, 8.0s]")
    expect(output).toContain("No findings.")
    expect(output).toContain("---")
  })

  it("formats failed results", () => {
    const results: AgentResult[] = [
      {
        name: "broken-agent",
        response: "## Error\n\nAgent timed out",
        success: false,
        durationMs: 300000,
      },
    ]

    const output = formatResults(results)

    expect(output).toContain("## broken-agent [FAILED, 300.0s]")
    expect(output).toContain("Agent timed out")
  })

  it("handles empty results array", () => {
    expect(formatResults([])).toBe("(no agents were spawned)")
  })

  it("handles mixed success and failure", () => {
    const results: AgentResult[] = [
      { name: "a", response: "ok", success: true, durationMs: 1000 },
      { name: "b", response: "err", success: false, durationMs: 2000 },
      { name: "c", response: "ok", success: true, durationMs: 500 },
    ]

    const output = formatResults(results)

    expect(output).toContain("[OK, 1.0s]")
    expect(output).toContain("[FAILED, 2.0s]")
    expect(output).toContain("[OK, 0.5s]")
  })
})
