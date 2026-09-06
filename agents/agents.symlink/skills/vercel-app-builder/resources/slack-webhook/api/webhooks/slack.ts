import { waitUntil } from "@vercel/functions"

const SLACK_API = "https://slack.com/api/chat.postMessage"
const MAX_CLOCK_SKEW_SECONDS = 60 * 5

type SlackEvent = {
  type?: string
  bot_id?: string
  channel?: string
  text?: string
  ts?: string
  thread_ts?: string
}

type SlackEnvelope = {
  type?: string
  challenge?: string
  event?: SlackEvent
}

function constantTimeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false
  let difference = 0
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index)
  }
  return difference === 0
}

async function hmacSha256Hex(secret: string, value: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  )
  const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(value))
  return [...new Uint8Array(signature)]
    .map(byte => byte.toString(16).padStart(2, "0"))
    .join("")
}

async function isValidSlackRequest(request: Request, rawBody: string): Promise<boolean> {
  const signingSecret = process.env.SLACK_SIGNING_SECRET
  const timestamp = request.headers.get("x-slack-request-timestamp")
  const slackSignature = request.headers.get("x-slack-signature")
  if (!signingSecret || !timestamp || !slackSignature) return false

  const ageSeconds = Date.now() / 1000 - Number(timestamp)
  if (!Number.isFinite(ageSeconds) || Math.abs(ageSeconds) > MAX_CLOCK_SKEW_SECONDS) {
    return false
  }

  const digest = await hmacSha256Hex(signingSecret, `v0:${timestamp}:${rawBody}`)
  return constantTimeEqual(slackSignature, `v0=${digest}`)
}

async function replyInThread(event: SlackEvent): Promise<void> {
  const token = process.env.SLACK_BOT_TOKEN
  if (!token || event.bot_id || event.type !== "app_mention" || !event.channel) return

  const text = (event.text ?? "").replace(/<@[^>]+>/g, "").trim() || "Got it."
  const response = await fetch(SLACK_API, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      channel: event.channel,
      thread_ts: event.thread_ts ?? event.ts,
      text,
    }),
  })

  if (!response.ok) {
    console.error("Slack chat.postMessage failed", response.status)
  }
}

export async function POST(request: Request): Promise<Response> {
  const rawBody = await request.text()
  if (!(await isValidSlackRequest(request, rawBody))) {
    return new Response("unauthorized", { status: 401 })
  }

  let envelope: SlackEnvelope
  try {
    envelope = JSON.parse(rawBody) as SlackEnvelope
  } catch {
    return new Response("invalid payload", { status: 400 })
  }

  if (envelope.type === "url_verification") {
    return Response.json({ challenge: envelope.challenge })
  }

  if (envelope.type === "event_callback" && envelope.event) {
    waitUntil(replyInThread(envelope.event))
  }

  return new Response("ok")
}
