# Hosting

Use Vercel when the app needs a shareable web URL.

## Defaults

- Ask whether the deployed app should require Google sign-in. Recommend yes
  unless the user wants it public.
- If yes, create or reuse the `<app-name> app auth` item from
  [`secrets.md`](secrets.md). Do not invent secrets or ask the user to paste
  them.
- Google sign-in plus an email allowlist is the access gate. Optional
  Workspace domain: `APP_ALLOWED_GOOGLE_HD`.
- If Google sign-in is enabled, protect the app and all assets:
  `/assets/*.js`, `/assets/*.css`, imported JSON, images, and static data.

## Vercel Login

If Vercel is not configured:

```bash
bunx vercel login
```

If the CLI prints a device URL, send it to the user and wait for approval.

## Project Config

Create `vercel.json` in the project root:

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "installCommand": "bun install --frozen-lockfile",
  "buildCommand": "bun run build",
  "outputDirectory": "dist",
  "rewrites": [
    {
      "source": "/((?!api/).*)",
      "destination": "/index.html"
    }
  ]
}
```

Vercel Functions under `/api` are auto-detected from `api/**/*.ts`. Do not
rewrite those paths to `.ts` files. The SPA catch-all must not swallow `/api/*`.

Add `.vercel` to `.gitignore`. Do not commit `.vercel/` or
`.vercel/.env*.local`.

## Google Sign-In

Use this when the user chose Google sign-in. Skip if the app is public.

Ask which Google emails may sign in. Recommend the user's email. Then create
or reuse `<app-name> app auth` with [`secrets.md`](secrets.md).

Requirements:

- Login page must not load the app bundle.
- `/api/auth` and `/login` are public.
- `/api/webhooks/*` is public so Slack can reach the app. Slack signing
  verifies those requests. Any extra webhook must verify its own signatures
  and must not rely on this middleware.
- `/assets/*` and static files are protected unless intentionally public.
- Session cookies come from Better Auth (HttpOnly, Secure, SameSite=Lax).
- Sign-in is Google OAuth only. Do not add a password, query-string token, or
  shared header bypass.
- Never use `VITE_*` for secrets.

Install auth packages:

```bash
bun add better-auth @vercel/functions
```

Copy the contents of `resources/vercel-protected-app/` from this skill's
directory into the project root. That adds `auth.ts`, `api/auth/[...all].ts`,
and `middleware.ts`.

Local auth routes need `bunx vercel dev`, not plain `vite` alone.

### Google OAuth client

Do this after the production URL exists, or use localhost first and add the
production redirect after deploy.

1. Open [Google Cloud credentials](https://console.cloud.google.com/apis/credentials).
2. Select an existing project, or click **Create Project**, name it after the
   app, and create it.
3. If prompted, open **OAuth consent screen**. Choose **External**. Set the
   app name, user support email, and developer contact. Save.
4. If the consent screen is in **Testing**, add every allowlisted email as a
   test user.
5. Click **Create Credentials**, then **OAuth client ID**.
6. Application type: **Web application**. Name: `<app-name>`.
7. Authorized JavaScript origins:
   - `http://localhost:5173`
   - `https://<production-host>`
8. Authorized redirect URIs:
   - `http://localhost:5173/api/auth/callback/google`
   - `https://<production-host>/api/auth/callback/google`
9. Click **Create**.
10. Put **Client ID** into `GOOGLE_CLIENT_ID` and **Client secret** into
    `GOOGLE_CLIENT_SECRET` on the `<app-name> app auth` 1Password item. Tell
    the agent when that is done. Do not paste the values into chat.

Then load env vars from that item ([`secrets.md`](secrets.md)) and redeploy.

## Deploy

From the project root:

```bash
bunx vercel build --prod --yes
bunx vercel deploy --prebuilt --prod
```

If the project is not linked yet:

```bash
bunx vercel --prod
```

Accept the detected `vercel.json` settings and create a new project.

After the first production URL exists, set `BETTER_AUTH_URL` on the 1Password
item to that origin (no trailing slash), add it as a Google redirect origin,
load env, and redeploy.

## Verification

Before telling the user the app is protected, verify root, assets, login, and
the auth handler. Do not send passwords or Google tokens in curl.

```bash
APP_URL="https://your-project.vercel.app"
asset_path="$(
  find .vercel/output/static/assets -type f 2>/dev/null |
    head -n 1 |
    sed 's#^\.vercel/output/static##'
)"

curl -s -o /dev/null -w 'root:%{http_code} %{redirect_url}\n' "$APP_URL/"
if [ -n "$asset_path" ]; then
  curl -s -o /dev/null -w 'asset:%{http_code} %{redirect_url}\n' "$APP_URL$asset_path"
else
  echo "asset:missing-local-built-asset"
fi
curl -s -o /dev/null -w 'login:%{http_code}\n' "$APP_URL/login"
curl -s "$APP_URL/login" | grep -q 'Continue with Google' && echo 'login:google-button'
curl -s -o /dev/null -w 'auth-ok:%{http_code}\n' "$APP_URL/api/auth/ok"
curl -s -o /dev/null -w 'session:%{http_code}\n' "$APP_URL/api/auth/get-session"
```

Expected:

- Root and protected assets redirect to `/login`.
- `/login` returns `200` and includes **Continue with Google**.
- `/api/auth/ok` returns `200`.
- `/api/auth/get-session` without a cookie does not return an authenticated
  user.

Inspect the built output:

```bash
find .vercel/output/static -maxdepth 3 -type f | sort
```

If private data is imported by Vite, it may be embedded in the JS bundle. That
is acceptable only when `/assets/*` is protected.
