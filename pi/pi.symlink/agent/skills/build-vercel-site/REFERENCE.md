# Build a Vercel Site — CLI Cheatsheet and Gotcha Catalog

Reference for the execution phase. Stack: Next.js App Router + TypeScript +
Drizzle ORM + serverless Postgres + pnpm. All commands assume the repo root.
Parse only stdout from `vercel` commands; warnings go to stderr.

## 1. Preflight

```bash
node --version && pnpm --version       # know your runtime
gh auth status                         # GitHub account + scopes
vercel whoami                          # account — linking on the wrong team
                                       # is a common, confusing failure
```

## 2. Scaffold and ignore rules

- pnpm only; commit `pnpm-lock.yaml`. Do not mix package managers.
- Standard scripts:

  ```json
  {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint .",
    "test": "node --test",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate"
  }
  ```

- `.gitignore` must cover: `.env*`, `.vercel/`, `node_modules/`,
  `tsconfig.tsbuildinfo`.
- Keep a committable env template: add a `!.env.example` negation **after**
  the `.env*` rule or `git add .env.example` will silently fail:

  ```gitignore
  .env*
  !.env.example
  tsconfig.tsbuildinfo
  ```

- `.env.example` lists variable names only, never values.

## 3. Tests with `node --test` (Node 22+ native type stripping)

- Any module imported by a test — directly or transitively — must be imported
  with an explicit `.ts` extension.
- `tsconfig.json` needs `"allowImportingTsExtensions": true` with
  `"noEmit": true`. Current Next.js builds accept `.ts` import extensions in
  app code; do not strip them to satisfy the bundler.
- Keep domain modules (date windows, validation, error classifiers)
  dependency-free so the test runner never pulls in Drizzle or the DB driver.
- For route-level logic, use an injectable-repository pattern:
  `handler(payload, repo)` does validation + status mapping; the route file is
  a thin wrapper passing the real Drizzle-backed repo; tests pass a fake.

## 4. Next.js App Router conventions

- DB-reading route handlers: `export const dynamic = "force-dynamic"` (or
  explicit no-store headers) — never statically cache live data.
- Keep database access in server-only modules under `db/`; no DB SDKs or
  credentials in client bundles.
- Modern React lint configs (Next 16+) flag `react-hooks/set-state-in-effect`:
  keep fetchers pure (return data, throw user-safe errors) and call setState
  only inside `.then`/`.catch` callbacks.

## 5. Repo and project linking

```bash
gh repo create <owner>/<name> --private --source . --remote origin --push
vercel link --yes --project <project-name>
```

- `vercel link` creates the project if missing **and** auto-connects the git
  repo — a separate `vercel git connect` is usually unnecessary. Verify with
  `vercel api /v9/projects/<name>` and inspect the `link` object.
- Push to the production branch = production deploy once git is connected.

## 6. Marketplace Postgres (e.g. Neon)

```bash
vercel integration discover neon                    # find the slug
vercel integration add neon --name <resource> -m region=<code>
```

- **Region metadata takes Vercel region codes** (`iad1`, `fra1`…), not cloud
  provider names (`us-east-1` is rejected with the valid list).
- Connecting defaults to all environments (production, preview, development).
  Verify with `vercel env list`.
- **Human step risk**: first-time installs may require marketplace terms
  acceptance in a browser. Try the CLI with a bounded timeout; if it reports a
  `reason` requiring interaction or exits 1 on a non-provisionable product,
  finish in the dashboard (vercel.com/marketplace) and note it in the plan.
- Free-plan fallback if marketplace install fails on a free team: create the
  resource at the provider's own site, then set vars with `vercel env add`.

## 7. Environment variables

```bash
vercel env pull .env.local   # what `next dev` loads
vercel env pull .env         # what drizzle-kit auto-loads
git check-ignore .env .env.local   # both must print the path
```

- Convention: pooled/accelerated URL (e.g. `DATABASE_URL`) for runtime;
  unpooled/direct URL (e.g. `DATABASE_URL_UNPOOLED`) for migrations. DDL over
  a pooling proxy is a known failure mode — `drizzle.config.ts` should prefer
  the unpooled var:

  ```ts
  dbCredentials: {
    url: process.env.DATABASE_URL_UNPOOLED ?? process.env.DATABASE_URL ?? "",
  }
  ```

## 8. Drizzle schema and migrations

- Declare tables with `pgTable` from `drizzle-orm/pg-core`, Postgres types,
  and named `unique()` constraints. Integrity lives in the database; the app
  maps violations to statuses (unique → 409), never pre-checks on the client.
- Use the serverless HTTP driver (`drizzle-orm/neon-http` or equivalent):
  single-shot queries, no pool lifecycle across cold starts. Fine when writes
  are single inserts guarded by DB constraints; revisit if you need
  transactions.
- Generate and inspect after EVERY schema change:

  ```bash
  pnpm db:generate
  cat drizzle/0000_*.sql   # right dialect? no wrong-dialect idioms?
  ```

- Generated DDL shape is canonical: drizzle-kit may emit a unique constraint
  inline in `CREATE TABLE` rather than as `ALTER TABLE`. Do not hand-edit
  generated migrations; fix the schema and regenerate. Once a migration has
  been applied to production, add a new one instead.
- Apply once, manually, against production (`pnpm db:migrate`) — never inside
  `next build` or on request. Then verify the schema landed (e.g.
  `SELECT COUNT(*)` from the new table) before deploying.
- **Driver call shapes change**: current `@neondatabase/serverless` exposes a
  tagged-template-only query function (`` sql`SELECT ...` ``); the
  conventional `sql("SELECT $1", [v])` form throws. Check the installed
  version's API before writing verification snippets.

## 9. Deploy and smoke test

```bash
git push origin <prod-branch>        # preferred: exercises the git path
vercel deploy --prod --yes           # fallback (e.g. nothing new to push)
vercel list <project>                # watch until state is READY
curl -s https://<prod-url>/<read-endpoint>
```

- Smoke-test a read endpoint that touches the database. A 5xx there almost
  always means env vars missing for the Production environment.

## 10. WAF rate limiting for public writes

```bash
vercel firewall rules add --json '{
  "name": "<endpoint>-rate-limit",
  "active": true,
  "conditionGroup": [{"conditions": [
    {"type":"path","op":"eq","value":"/api/<endpoint>"},
    {"type":"method","op":"eq","value":"POST"}
  ]}],
  "action": {"mitigate": {"action":"rate_limit","rateLimit":{
    "algo":"fixed_window","window":60,"limit":10,"keys":["ip"],
    "action":"rate_limit"}}}
}' --yes
vercel firewall diff        # review the staged draft
vercel firewall publish --yes
```

- Rules are **staged as drafts** — nothing is live until `publish`.
- Verify engagement with a burst of cheap invalid requests (e.g. 15 POSTs with
  a bad payload that writes nothing): expect successes turning into `429` once
  the window limit is hit.
- **Plan caps**: free/Hobby tiers include a very small number of rate-limit
  rules per project (one at time of writing). Treat them as spent once
  created; a second rule may require a paid plan — do not upgrade silently.
- Rate limiting never replaces server-side validation and DB constraints;
  it's the third layer, not the first.

## 11. End-to-end verification checklist

1. Real write through the UI or API → visible in the read path.
2. Persistence from a separate session/incognito.
3. Conflict path: repeat the write → correct 4xx status and user-safe message.
4. Persistence across a redeploy (push a trivial commit through the git path).
5. Note expected free-tier behavior (cold starts) so nobody "fixes" it later.

**Caution for anonymous-write products without a delete flow**: verification
writes to production are publicly visible and may be permanent. Use real,
meaningful data for the final E2E or clean up directly in the database with
explicit approval — never silently delete production rows.

## Gotcha catalog (re-verify as tooling evolves)

| Area | Gotcha |
|---|---|
| Auth | `vercel link`/provisioning on the wrong team — check `vercel whoami` first |
| CLI | `vercel` prints warnings/prompts to stderr; in agent mode errors arrive as a single JSON object on stdout with `status`/`reason`/`next` |
| Regions | Integration metadata wants Vercel region codes (`iad1`), not AWS names |
| Git | Subagent stash/checkout cycles can leave HEAD detached — `git status` after; repair with `git branch -f main HEAD && git checkout main` |
| Lint | Next 16 configs flag `set-state-in-effect`: pure fetchers, setState only in async callbacks |
| Drizzle | Inline constraints in generated `CREATE TABLE` are canonical — don't hand-edit |
| DB drivers | `@neondatabase/serverless` is tagged-template-only; check before scripting |
| Tests | `node --test` type stripping needs explicit `.ts` extensions through the whole test import graph |
| Free tiers | Scale-to-zero cold starts (~1s first request) and tiny WAF rule allowances are platform facts, not bugs |
| Secrets | `.env*` ignore rule also blocks `.env.example` without an explicit negation |
| Errors | Map unique violations to 409; all other failures get fixed, leak-free messages — never SQL, stack traces, or connection strings |
