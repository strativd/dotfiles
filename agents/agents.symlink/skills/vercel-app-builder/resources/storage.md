# Data Storage

Use this resource when the app needs durable state, search,
messaging, vectors, or object storage.

Source references:

- [Upstash on Vercel Marketplace](https://vercel.com/marketplace/upstash)
- [Vercel Blob docs](https://vercel.com/docs/vercel-blob)
- [Vercel Blob SDK docs](https://vercel.com/docs/storage/vercel-blob/using-blob-sdk)

## Defaults

- Database, Redis/KV state, vectors, messaging, queues, and search: Upstash via
  Vercel Marketplace.
- Uploaded files, generated files, images, PDFs, audio, and video: Vercel Blob.
- Skip durable storage when in-memory state is enough for the demo.

## Upstash

Prefer Vercel Marketplace setup. Do not ask the user for raw Upstash tokens
unless Marketplace setup is blocked.

For Redis-backed state:

```bash
bun add @upstash/redis
```

Environment variables:

```text
UPSTASH_REDIS_REST_URL
UPSTASH_REDIS_REST_TOKEN
```

Do not use `NEXT_PUBLIC_` for these values.

Minimal server-side Redis helper with local memory fallback:

```ts
import { Redis } from "@upstash/redis"

const memoryStore = new Map<string, unknown>()

declare global {
  var appRedis: Redis | undefined
}

function redisClient(): Redis | null {
  if (
    !process.env.UPSTASH_REDIS_REST_URL ||
    !process.env.UPSTASH_REDIS_REST_TOKEN
  ) {
    return null
  }

  globalThis.appRedis ??= Redis.fromEnv()
  return globalThis.appRedis
}

export async function getValue<T>(key: string): Promise<T | undefined> {
  const redis = redisClient()
  return redis ? ((await redis.get<T>(key)) ?? undefined) : memoryStore.get(key) as T | undefined
}

export async function setValue(
  key: string,
  value: unknown,
  ttlSeconds = 60 * 60 * 6,
): Promise<void> {
  const redis = redisClient()
  if (redis) await redis.set(key, value, { ex: ttlSeconds })
  else memoryStore.set(key, value)
}
```

### Vercel Marketplace Setup

After the app is deployed or linked to Vercel:

1. Open <https://vercel.com/marketplace/upstash>.
2. Install the needed Upstash product:
   - **Upstash Redis** for database, app state, counters, and TTL records.
   - **Upstash Vector** for embeddings and semantic search.
   - **Upstash QStash** for messaging, queues, and scheduled work.
   - **Upstash Search** for search.
3. Connect it to the app's Vercel project.
4. Create or select the database, index, queue, or search resource.
5. Confirm Vercel added the required environment variables.
6. Redeploy.

For local development after Marketplace setup:

```bash
bunx vercel env pull .env.local
```

Never commit `.env.local`.

## Vercel Blob

Use Vercel Blob for object storage. Keep `BLOB_READ_WRITE_TOKEN` server-side
unless using Vercel's client-upload flow.

```bash
bun add @vercel/blob
```

Environment variable:

```text
BLOB_READ_WRITE_TOKEN
```

Minimal private upload helper:

```ts
import { put } from "@vercel/blob"

export async function uploadObject(
  pathname: string,
  body: Blob | ArrayBuffer | ReadableStream | string,
) {
  if (!process.env.BLOB_READ_WRITE_TOKEN) {
    throw new Error("BLOB_READ_WRITE_TOKEN is not configured")
  }

  return await put(pathname, body, {
    access: "private",
    addRandomSuffix: true,
  })
}
```

Use `access: "public"` only when the object is intended to be public.

### Vercel Blob Setup

After the app is deployed or linked to Vercel:

1. Open the Vercel project.
2. Go to **Storage**.
3. Create a **Blob** store.
4. Connect it to the project.
5. Confirm Vercel added `BLOB_READ_WRITE_TOKEN`.
6. Redeploy.

Pull local env after setup:

```bash
bunx vercel env pull .env.local
```

## README

Document only the storage actually used:

- Why Upstash or Blob is used.
- Required environment variables.
- Local fallback behavior.
- TTL, retention, and public/private access tradeoffs.

## Done When

- Vercel env vars include the required Upstash or Blob values.
- Production was redeployed after connecting Marketplace or Storage resources.
- A cross-request flow works in production when Upstash is used.
- A file upload/download flow works in production when Blob is used.
- Storage tokens are not committed, printed, or exposed to browser code.
