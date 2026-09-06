import { next } from "@vercel/functions"
import { auth, getAllowedGoogleHd, isAllowedEmail, isGoogleAuthConfigured } from "./auth.js"

const PUBLIC_PATH_PREFIXES = ["/api/auth", "/api/webhooks/"]
const PUBLIC_PATHS = new Set(["/favicon.svg"])

export const config = {
  runtime: "nodejs",
}

function isPublicPath(pathname: string): boolean {
  if (PUBLIC_PATHS.has(pathname)) return true
  return PUBLIC_PATH_PREFIXES.some(prefix => pathname.startsWith(prefix))
}

function safeNextPath(requestUrl: URL): string {
  const nextPath = requestUrl.searchParams.get("next") ?? "/"
  return nextPath.startsWith("/") && !nextPath.startsWith("//") ? nextPath : "/"
}

function renderLoginPage(requestUrl: URL): Response {
  const nextPath = safeNextPath(requestUrl)
  const hostedDomain = getAllowedGoogleHd()
  const configured = isGoogleAuthConfigured()

  return new Response(`<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Sign in</title>
    <style>
      body { min-height: 100vh; margin: 0; display: grid; place-items: center; font-family: system-ui, sans-serif; background: #111827; color: white; }
      main { width: min(100%, 26rem); padding: 1.25rem; border: 1px solid #374151; border-radius: 0.75rem; background: #1f2937; }
      button { font: inherit; padding: 0.75rem; border-radius: 0.5rem; border: 0; background: #fbbf24; color: #111827; cursor: pointer; width: 100%; }
      .error { color: #fecaca; }
    </style>
  </head>
  <body>
    <main>
      <h1>Sign in</h1>
      ${configured ? `
      <form>
        <button type="submit">Continue with Google</button>
      </form>
      <p class="error" role="alert" hidden></p>
      ` : `<p class="error" role="alert">Google sign-in is not configured.</p>`}
    </main>
    ${configured ? `<script>
      const form = document.querySelector("form")
      const error = document.querySelector(".error")
      form.addEventListener("submit", async event => {
        event.preventDefault()
        error.hidden = true
        const body = {
          provider: "google",
          callbackURL: ${JSON.stringify(nextPath)},
        }
        const hostedDomain = ${JSON.stringify(hostedDomain)}
        if (hostedDomain) body.additionalParams = { hd: hostedDomain }
        const response = await fetch("/api/auth/sign-in/social", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        })
        if (response.redirected) {
          window.location.assign(response.url)
          return
        }
        const payload = await response.json().catch(() => null)
        if (payload?.url) {
          window.location.assign(payload.url)
          return
        }
        error.textContent = payload?.message ?? payload?.errorDescription ?? "Unable to sign in."
        error.hidden = false
      })
    </script>` : ""}
  </body>
</html>`, { headers: { "Content-Type": "text/html; charset=utf-8" } })
}

export default async function middleware(request: Request) {
  const url = new URL(request.url)

  if (url.pathname === "/login") return renderLoginPage(url)
  if (isPublicPath(url.pathname)) return next()

  const session = await auth.api.getSession({ headers: request.headers })
  if (session?.user && isAllowedEmail(session.user.email)) return next()

  const loginUrl = new URL("/login", url)
  loginUrl.searchParams.set("next", `${url.pathname}${url.search}`)
  return new Response(null, { status: 302, headers: { Location: loginUrl.toString() } })
}
