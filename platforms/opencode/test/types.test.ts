import { describe, it, expect } from "bun:test"
import { extractTextFromParts, errorMessage } from "../src/types"
import type { Part, TextPart } from "../src/types"

describe("extractTextFromParts", () => {
  it("extracts text from TextPart array", () => {
    const parts: Part[] = [
      {
        id: "1", sessionID: "s1", messageID: "m1",
        type: "text", text: "Hello",
      } as TextPart,
      {
        id: "2", sessionID: "s1", messageID: "m1",
        type: "text", text: "World",
      } as TextPart,
    ]
    expect(extractTextFromParts(parts)).toBe("Hello\nWorld")
  })

  it("filters out non-text parts", () => {
    const parts: Part[] = [
      {
        id: "1", sessionID: "s1", messageID: "m1",
        type: "text", text: "visible",
      } as TextPart,
      {
        id: "2", sessionID: "s1", messageID: "m1",
        type: "reasoning", text: "hidden reasoning",
        time: { start: 0 },
      } as Part,
    ]
    expect(extractTextFromParts(parts)).toBe("visible")
  })

  it("returns empty string for empty array", () => {
    expect(extractTextFromParts([])).toBe("")
  })

  it("returns empty string for array with no text parts", () => {
    const parts: Part[] = [
      {
        id: "1", sessionID: "s1", messageID: "m1",
        type: "reasoning", text: "thinking...",
        time: { start: 0 },
      } as Part,
    ]
    expect(extractTextFromParts(parts)).toBe("")
  })
})

describe("errorMessage", () => {
  it("extracts message from Error", () => {
    expect(errorMessage(new Error("boom"))).toBe("boom")
  })

  it("converts string to string", () => {
    expect(errorMessage("failed")).toBe("failed")
  })

  it("converts number to string", () => {
    expect(errorMessage(42)).toBe("42")
  })

  it("converts null to string", () => {
    expect(errorMessage(null)).toBe("null")
  })

  it("converts undefined to string", () => {
    expect(errorMessage(undefined)).toBe("undefined")
  })

  it("converts object to string", () => {
    expect(errorMessage({ code: 500 })).toBe("[object Object]")
  })
})
