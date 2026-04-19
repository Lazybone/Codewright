/**
 * @codewright/opencode — Bridge plugin for running Codewright skills in OpenCode.
 *
 * Registers the `cw_agent` custom tool via the plugin `tool` hook, closing over
 * the SDK client from PluginInput. This is necessary because ToolContext does not
 * expose the SDK client — only the plugin closure has access.
 */

import { z } from "zod"
import { tool } from "@opencode-ai/plugin"
import type { ToolContext } from "@opencode-ai/plugin"
import type { PluginInput, Hooks, Client } from "./types.js"
import type { PluginOptions } from "@opencode-ai/plugin"
import { spawnParallel, formatResults } from "./orchestrator.js"

function createCwAgentTool(client: Client) {
  return tool({
    description:
      "Spawn Codewright subagents for parallel analysis or code changes. " +
      'Each agent receives a prompt and runs independently. Use mode "explore" ' +
      'for read-only analysis, "auto" for code modifications. Returns consolidated ' +
      "Markdown results from all agents.",
    args: {
      agents: z
        .array(
          z.object({
            name: z.string().describe("Unique identifier for this agent"),
            mode: z
              .enum(["explore", "auto"])
              .describe('Agent mode: "explore" for read-only, "auto" for code changes'),
            prompt: z
              .string()
              .describe("Full prompt including instructions, context, and file lists"),
          }),
        )
        .min(1)
        .describe("List of agents to spawn in parallel"),
    },
    async execute(
      args: { agents: Array<{ name: string; mode: "explore" | "auto"; prompt: string }> },
      context: ToolContext,
    ): Promise<string> {
      const results = await spawnParallel(client, args.agents, context.abort)
      return formatResults(results)
    },
  })
}

const CodewrightPlugin = async (input: PluginInput, _options?: PluginOptions): Promise<Hooks> => {
  await input.client.app.log({
    body: {
      service: "codewright",
      level: "info",
      message: `Plugin loaded (${input.directory})`,
    },
  }).catch(() => {})

  return {
    tool: {
      cw_agent: createCwAgentTool(input.client),
    },
  }
}

export const server = CodewrightPlugin
export default CodewrightPlugin
