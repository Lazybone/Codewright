import type { AgentCall, AgentResult, Client } from "./types.js"
import { extractTextFromParts, errorMessage } from "./types.js"

const AGENT_TIMEOUT_MS = 5 * 60 * 1000
const SERVICE = "codewright"

type LogLevel = "debug" | "info" | "warn" | "error"

function log(client: Client, level: LogLevel, message: string) {
  return client.app.log({ body: { service: SERVICE, level, message } }).catch(() => {})
}

function agentIdForMode(mode: AgentCall["mode"]): string {
  return mode === "explore" ? "cw-explore" : "cw-worker"
}

export async function spawnAgent(
  client: Client,
  call: AgentCall,
  abort?: AbortSignal,
): Promise<AgentResult> {
  const start = Date.now()
  const agentId = agentIdForMode(call.mode)

  let sessionId: string | undefined

  try {
    if (abort?.aborted) {
      throw new Error(`Aborted before starting agent "${call.name}"`)
    }

    const createResult = await client.session.create({
      body: { title: `cw:${call.name}` },
    })
    if (createResult.error) {
      throw new Error(`Session create failed: ${JSON.stringify(createResult.error)}`)
    }
    sessionId = createResult.data.id

    await log(client, "info", `Spawned agent "${call.name}" (${agentId})`)

    const promptPromise = client.session.prompt({
      path: { id: sessionId },
      body: {
        agent: agentId,
        parts: [{ type: "text" as const, text: call.prompt }],
      },
    })

    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(
        () => reject(new Error(`Agent "${call.name}" timed out after ${AGENT_TIMEOUT_MS / 1000}s`)),
        AGENT_TIMEOUT_MS,
      )
    })

    const abortPromise = abort
      ? new Promise<never>((_, reject) => {
          abort.addEventListener("abort", () => reject(new Error("Aborted by parent session")), {
            once: true,
          })
        })
      : null

    const racers: Promise<unknown>[] = [promptPromise, timeoutPromise]
    if (abortPromise) racers.push(abortPromise)

    // session.prompt() blocks until the agent completes.
    // Promise.race does not cancel the loser — session.delete in finally handles cleanup.
    const promptResult = await Promise.race(racers) as Awaited<typeof promptPromise>

    let response: string

    if (!promptResult.error && promptResult.data) {
      response = extractTextFromParts(promptResult.data.parts)
    } else {
      if (promptResult.error) {
        await log(client, "warn", `Agent "${call.name}" prompt returned error: ${JSON.stringify(promptResult.error)}`)
      }

      const messagesResult = await client.session.messages({
        path: { id: sessionId },
      })
      if (messagesResult.error || !messagesResult.data) {
        response = "(no response — failed to read messages)"
      } else {
        const lastAssistant = messagesResult.data
          .filter((m) => m.info.role === "assistant")
          .pop()
        response = lastAssistant
          ? extractTextFromParts(lastAssistant.parts)
          : "(no response)"
      }
    }

    if (!response || response === "(no response)") {
      await log(client, "warn", `Agent "${call.name}" returned no content`)
    }

    return {
      name: call.name,
      response: response || "(empty response)",
      success: true,
      durationMs: Date.now() - start,
    }
  } catch (error) {
    const msg = errorMessage(error)
    await log(client, "error", `Agent "${call.name}" failed: ${msg}`)

    return {
      name: call.name,
      response: `## Error\n\nAgent "${call.name}" failed: ${msg}`,
      success: false,
      durationMs: Date.now() - start,
    }
  } finally {
    if (sessionId) {
      const sid = sessionId
      client.session.delete({ path: { id: sid } }).catch((err) => {
        log(client, "warn", `Failed to clean up session ${sid}: ${errorMessage(err)}`)
      })
    }
  }
}

export async function spawnParallel(
  client: Client,
  calls: AgentCall[],
  abort?: AbortSignal,
): Promise<AgentResult[]> {
  if (calls.length === 0) {
    return []
  }

  await log(client, "info", `Spawning ${calls.length} agents in parallel: ${calls.map((c) => c.name).join(", ")}`)

  const results = await Promise.allSettled(
    calls.map((call) => spawnAgent(client, call, abort)),
  )

  return results.map((result, i) => {
    if (result.status === "fulfilled") return result.value
    return {
      name: calls[i].name,
      response: `## Error\n\nAgent "${calls[i].name}" rejected: ${errorMessage(result.reason)}`,
      success: false,
      durationMs: 0,
    }
  })
}

export function formatResults(results: AgentResult[]): string {
  if (results.length === 0) return "(no agents were spawned)"

  return results
    .map((r) => {
      const status = r.success ? "OK" : "FAILED"
      const duration = (r.durationMs / 1000).toFixed(1)
      return `## ${r.name} [${status}, ${duration}s]\n\n${r.response}`
    })
    .join("\n\n---\n\n")
}
