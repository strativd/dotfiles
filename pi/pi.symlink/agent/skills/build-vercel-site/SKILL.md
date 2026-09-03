---
name: build-vercel-site
description: Build and deploy a new Next.js + Drizzle + pnpm app on Vercel from scratch — brainstorm the product, write an executable plan, then scaffold, provision (git, serverless Postgres, env vars, WAF), migrate, deploy, and verify using the gh/vercel/drizzle-kit CLIs. Use when starting a greenfield Next.js project on Vercel, deploying a new site with a Postgres database, setting up a Vercel project end-to-end, or when the user says "build me a site", "new Vercel app", "deploy from scratch", or "set up hosting and a database".
---

# Build a Vercel Site From Scratch

End-to-end workflow for taking a new web app from idea to a verified production
deployment on Vercel, at minimal or $0 cost.

**Stack:** Next.js App Router, TypeScript (strict), Drizzle ORM, serverless
Postgres (e.g. Neon via the Vercel Marketplace), pnpm, `node --test`.

## Phase 0: Brainstorm the idea (before any code)

Invoke a brainstorming skill (`brainstorming`) and pin down, in writing:

- **Product contract** — the smallest set of user-visible guarantees (pages,
  actions, data rules). Everything else is a non-goal; list non-goals too.
- **Public-write surface** — what can anonymous users write, if anything? This
  drives validation, DB constraints, and rate limiting later.
- **Cost ceiling** — decide the target tier (e.g. $0 on Hobby + free-tier DB)
  up front; it constrains every provisioning choice. Note which upgrades must
  never happen silently.
- **Conventions doc** — capture decisions in an `AGENTS.md` at the repo root:
  stack, pnpm scripts, testing rules, security boundaries, and a "verified
  facts" section to append to as you learn things.

## Phase 1: Write the plan (before any code)

Invoke a plan-writing skill (`writing-plans`). The plan must be executable by a
fresh agent without re-reading the conversation:

- Checkbox tasks in dependency order, each with exact file contents or
  commands, expected outputs, and a commit step.
- An explicit **verification gate task** (lint + test + build) before any
  deploy task, and an **end-to-end verification task** last.
- Mark which steps need a human (marketplace terms, dashboard-only actions,
  browser E2E) and give a CLI fallback for each.
- Record environment facts (CLI versions, account/team, runtime) so later
  sessions don't re-verify them.

## Phase 2: Execute with the CLIs

Work task-by-task (subagent-driven or directly). The canonical command sequence
— flags, exact JSON payloads, and fallbacks — is in
[REFERENCE.md](REFERENCE.md). Order matters:

1. **Scaffold + conventions**: App Router source in `app/`, DB code in `db/`,
   `AGENTS.md`, `.gitignore` (must cover `.env*`, `.vercel/`,
   `tsconfig.tsbuildinfo`; opt the env example back in with `!.env.example`).
   pnpm only — commit `pnpm-lock.yaml`.
2. **Test-first core logic**: pure, dependency-free domain/validation modules
   under `db/` with `node --test` tests green before infra work.
3. **Database layer**: Drizzle `pgTable` schema with invariants enforced by
   the database (unique constraints → mapped HTTP statuses), a server-only
   client module, and a repository module. Generate the migration and
   **inspect the SQL**; never run schema changes at build or request time.
4. **Verification gate**: `pnpm lint` + `pnpm test` + `pnpm build` all green.
   Fix findings in place; do not disable rules.
5. **Repo + project**: `gh repo create --push`, then `vercel link` (it
   auto-creates the project and auto-connects git).
6. **Provision the database**: marketplace integration via CLI; pull env vars
   (`vercel env pull`); confirm they exist for every needed environment.
7. **Migrate once, manually** (`drizzle-kit migrate`) against the production
   database; verify the schema landed before deploying.
8. **Deploy**: push to the production branch (git-connected), or
   `vercel deploy --prod` as fallback. Smoke-test the live API.
9. **Protect public writes**: one WAF rate-limit rule on mutation endpoints,
   staged then published via CLI; verify it engages with a request burst.
10. **E2E verify**: real write → persistence from a second session → conflict
    path → persistence across a redeploy.

## Standing rules (every phase)

- **Gates before handoff**: lint, tests, and build green — evidence, not
  assertions.
- **Secrets**: never commit `.env*` (except the example file), tokens, or
  connection strings; scan `git diff` before every commit.
- **DB is the source of truth**: enforce integrity with Drizzle unique
  constraints and map violations to correct HTTP statuses (e.g. 409); return
  fixed, leak-free error messages.
- **Route handlers**: mark DB-reading routes `force-dynamic` (or send explicit
  no-store headers) so responses are never statically cached.
- **Free-tier behaviors are not bugs**: scale-to-zero cold starts, per-plan
  feature caps (e.g. one free WAF rule). Design around them; don't "fix" them.
- **After any subagent does git work**, check `git status` for detached HEAD.
- **Update `AGENTS.md`** whenever a platform fact, command shape, or gotcha is
  verified — it is the project's durable memory.

## Reference

- [REFERENCE.md](REFERENCE.md) — CLI command cheatsheet (gh, vercel link/env/
  integration/firewall/deploy, drizzle-kit), Next.js/Drizzle gotcha catalog,
  and human-step fallbacks.
