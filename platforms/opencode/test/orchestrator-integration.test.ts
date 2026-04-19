import { describe, it, expect, mock, beforeEach } from "bun:test"
import { spawnAgent, spawnParallel } from "../src/orchestrator"
import type { Client, AgentCall } from "../src/types"

function createMockClient(overrides?: Partial<{
  createError: boolean
  promptError: boolean
  promptParts: Array<{ type: string; text: string }>
  messagesParts: Array<{ type: string; text: string }>
}>): Client {
  const opts = overrides ?? {}

  return {
    session: {
      create: mock(async () => {
        if (opts.createError) {
          return { data: undefined, error: { name: "UnknownError", data: { message: "create failed" } } }
        }
        return { data: { id: "test-session-123" }, error: undefined }
      }),
      prompt: mock(async () => {
        if (opts.promptError) {
          return { data: undefined, error: { name: "UnknownError", data: { message: "prompt failed" } } }
        }
        return {
          data: {
            info: { id: "m1", sessionID: "test-session-123", role: "assistant" as const },
            parts: opts.promptParts ?? [
              { id: "p1", sessionID: "s1", messageID: "m1", type: "text" as const, text: "Analysis complete. No issues found." },
            ],
          },
          error: undefined,
        }
      }),
      messages: mock(async () => ({
        data: [
          {
            info: { id: "m1", sessionID: "test-session-123", role: "assistant" as const },
            parts: opts.messagesParts ?? [
              { id: "p1", sessionID: "s1", messageID: "m1", type: "text" as const, text: "Fallback response" },
            ],
          },
        ],
        error: undefined,
      })),
      delete: mock(async () => ({ data: undefined, error: undefined })),
    },
    app: {
      log: mock(async () => ({ data: undefined, error: undefined })),
    },
  } as unknown as Client
}

const baseCall: AgentCall = {
  name: "test-agent",
  mode: "explore",
  prompt: "Analyze the code.",
}

describe("spawnAgent", () => {
  it("spawns an agent and returns text from prompt response", async () => {
    const client = createMockClient()
    const result = await spawnAgent(client, baseCall)

    expect(result.success).toBe(true)
    expect(result.name).toBe("test-agent")
    expect(result.response).toContain("Analysis complete")
    expect(result.durationMs).toBeGreaterThanOrEqual(0)

    expect(client.session.create).toHaveBeenCalledTimes(1)
    expect(client.session.prompt).toHaveBeenCalledTimes(1)
    expect(client.session.delete).toHaveBeenCalledTimes(1)
  })

  it("falls back to messages when prompt returns error", async () => {
    const client = createMockClient({ promptError: true })
    const result = await spawnAgent(client, baseCall)

    expect(result.success).toBe(true)
    expect(result.response).toContain("Fallback response")
    expect(client.session.messages).toHaveBeenCalledTimes(1)
  })

  it("returns failure when session create fails", async () => {
    const client = createMockClient({ createError: true })
    const result = await spawnAgent(client, baseCall)

    expect(result.success).toBe(false)
    expect(result.response).toContain("Error")
    expect(result.response).toContain("create failed")
    expect(client.session.prompt).not.toHaveBeenCalled()
  })

  it("cleans up session even on error", async () => {
    const client = createMockClient({ createError: false })
    const throwingClient = {
      ...client,
      session: {
        ...client.session,
        prompt: mock(async () => { throw new Error("kaboom") }),
      },
    } as unknown as Client

    const result = await spawnAgent(throwingClient, baseCall)

    expect(result.success).toBe(false)
    expect(result.response).toContain("kaboom")
    expect(client.session.delete).toHaveBeenCalledTimes(1)
  })

  it("respects pre-aborted signal", async () => {
    const client = createMockClient()
    const controller = new AbortController()
    controller.abort()

    const result = await spawnAgent(client, baseCall, controller.signal)

    expect(result.success).toBe(false)
    expect(result.response).toContain("Aborted")
    expect(client.session.create).not.toHaveBeenCalled()
  })

  it("handles multiple text parts", async () => {
    const client = createMockClient({
      promptParts: [
        { type: "text", text: "Part 1" },
        { type: "text", text: "Part 2" },
      ],
    })
    const result = await spawnAgent(client, baseCall)

    expect(result.success).toBe(true)
    expect(result.response).toBe("Part 1\nPart 2")
  })

  it("filters non-text parts", async () => {
    const client = createMockClient({
      promptParts: [
        { type: "text", text: "visible" },
        { type: "reasoning", text: "hidden" },
      ],
    })
    const result = await spawnAgent(client, baseCall)

    expect(result.success).toBe(true)
    expect(result.response).toBe("visible")
  })
})

describe("spawnParallel", () => {
  it("spawns multiple agents in parallel", async () => {
    const client = createMockClient()
    const calls: AgentCall[] = [
      { name: "agent-a", mode: "explore", prompt: "check A" },
      { name: "agent-b", mode: "explore", prompt: "check B" },
      { name: "agent-c", mode: "auto", prompt: "fix C" },
    ]

    const results = await spawnParallel(client, calls)

    expect(results).toHaveLength(3)
    expect(results.every((r) => r.success)).toBe(true)
    expect(client.session.create).toHaveBeenCalledTimes(3)
  })

  it("returns empty array for empty calls", async () => {
    const client = createMockClient()
    const results = await spawnParallel(client, [])

    expect(results).toHaveLength(0)
    expect(client.session.create).not.toHaveBeenCalled()
  })

  it("handles partial failures gracefully", async () => {
    let callCount = 0
    const client = createMockClient()
    const originalPrompt = client.session.prompt
    ;(client.session as any).prompt = mock(async (...args: any[]) => {
      callCount++
      if (callCount === 2) throw new Error("second agent failed")
      return (originalPrompt as Function)(...args)
    })

    const calls: AgentCall[] = [
      { name: "ok-1", mode: "explore", prompt: "check" },
      { name: "fail", mode: "explore", prompt: "check" },
      { name: "ok-2", mode: "explore", prompt: "check" },
    ]

    const results = await spawnParallel(client, calls)

    expect(results).toHaveLength(3)
    expect(results[0].success).toBe(true)
    expect(results[1].success).toBe(false)
    expect(results[2].success).toBe(true)
  })

  it("passes abort signal to all agents", async () => {
    const client = createMockClient()
    const controller = new AbortController()
    controller.abort()

    const calls: AgentCall[] = [
      { name: "a", mode: "explore", prompt: "x" },
      { name: "b", mode: "explore", prompt: "y" },
    ]

    const results = await spawnParallel(client, calls, controller.signal)

    expect(results.every((r) => !r.success)).toBe(true)
    expect(results.every((r) => r.response.includes("Aborted"))).toBe(true)
  })
})
