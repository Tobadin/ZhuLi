// ZhuLi Bot — Anthropic API Wrapper (einfach, ohne Streaming für jetzt)
import { config } from "./config.ts";

interface Message { role: "user" | "assistant"; content: string }

export async function callClaude(
  messages: Message[],
  opts: { model?: string; system?: string; maxTokens?: number } = {},
): Promise<{ text: string; tokensIn: number; tokensOut: number; durationMs: number }> {
  const model = opts.model ?? config.anthropic.defaultModel;
  const start = Date.now();

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": config.anthropic.apiKey,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model,
      max_tokens: opts.maxTokens ?? 2048,
      system: opts.system,
      messages,
    }),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`[Claude] ${res.status}: ${err}`);
  }
  const data = await res.json();
  const text = data.content?.[0]?.text ?? "";
  return {
    text,
    tokensIn: data.usage?.input_tokens ?? 0,
    tokensOut: data.usage?.output_tokens ?? 0,
    durationMs: Date.now() - start,
  };
}
