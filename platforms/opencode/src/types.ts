import type { createOpencodeClient, Part, TextPart } from "@opencode-ai/sdk"
import type { PluginInput, Hooks } from "@opencode-ai/plugin"

export type { PluginInput, Hooks, Part, TextPart }

export type Client = ReturnType<typeof createOpencodeClient>

export interface AgentCall {
  name: string
  mode: "explore" | "auto"
  prompt: string
}

export interface AgentResult {
  name: string
  response: string
  success: boolean
  durationMs: number
}

export function extractTextFromParts(parts: Part[]): string {
  return parts
    .filter((p): p is TextPart => p.type === "text")
    .map((p) => p.text)
    .join("\n")
}

export function errorMessage(err: unknown): string {
  return err instanceof Error ? err.message : String(err)
}
