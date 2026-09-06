# LLMs

Use OpenRouter when the app needs an LLM. Skip it when deterministic logic,
seeded data, or canned responses would demo faster.

## Required Choices

- Provider: OpenRouter.
- SDK: Vercel AI SDK with `@openrouter/ai-sdk-provider`.
- Environment variable: `OPENROUTER_API_KEY`.
- 1Password item: `OpenRouter API Key` via [`secrets.md`](secrets.md).
- Keep calls server-side. NEVER use `VITE_` or `NEXT_PUBLIC_` for the key.

## Models

- Default: `moonshotai/kimi-k2.6`.
- Heavy reasoning: `openai/gpt-5.5`. Use only when the demo clearly needs
  stronger reasoning; it is much more expensive.
- Fast lightweight work: `openai/gpt-5.4-nano`.

## Key Setup

If the 1Password item is missing, ask the user to add an API Credential with
that title in the active account, then retry. Do not ask them to paste the key
into chat.

```bash
SECRET="$(op item get "OpenRouter API Key" --fields credential --reveal 2>/dev/null \
  || op item get "OpenRouter API Key" --fields password --reveal)"
bunx vercel env add OPENROUTER_API_KEY production --value "$SECRET" --yes --force
unset SECRET
```

```bash
bun add ai @openrouter/ai-sdk-provider
```

## Route

One streaming Vercel route is enough:

```ts
import { createOpenRouter } from "@openrouter/ai-sdk-provider"
import { streamText } from "ai"

export async function POST(request: Request) {
  const { messages, system } = await request.json()
  const apiKey = process.env.OPENROUTER_API_KEY
  if (!apiKey) throw new Error("OPENROUTER_API_KEY is not configured")

  const openrouter = createOpenRouter({ apiKey })
  const result = streamText({
    model: openrouter("moonshotai/kimi-k2.6"),
    system,
    messages,
  })

  return result.toTextStreamResponse()
}
```

For tools, use the Vercel AI SDK `tools` option on that same `streamText` call.

## Done When

- One server-side OpenRouter request succeeds.
- The key is set locally and in Vercel when deployed.
- The browser bundle does not include the API key.
- The README `Demo` section explains the LLM-powered happy path and fallback.
