---
name: vercel-app-builder
description: Use when creating, hosting, or iterating on a Vite/React app on Vercel, including Google sign-in, OpenRouter, Upstash, Vercel Blob, Slack bots, or storing app secrets with the 1Password CLI.
---

# Vercel App Builder

## Goal

Help turn an app idea into a shareable Vercel MVP. Scope it to the strongest
demo path, choose practical tradeoffs, and keep moving toward launch.

## NEVER

- NEVER invent a secret or ask the user to paste one. Generate or reuse it in
  1Password.
- NEVER use `VITE_` or `NEXT_PUBLIC_` for secrets.
- NEVER switch to Next.js only because a vendor guide uses it.
- NEVER tell the user the app is protected without verifying that `/assets/*`
  redirects to `/login`.
- NEVER print passwords, API keys, or tokens. Name the 1Password item instead.
- NEVER commit `.env.local` or `.vercel/`.
- NEVER scaffold into a foreign repo because the shell started there.

## Required Defaults

- Ask for project name, then project description, before file edits.
- `<name>` is a lowercase kebab-case slug.
- Treat the current directory as the app only if the user named this folder,
  or it already has both `MEMORY.md` and a Vite `package.json` (`vite` in
  `devDependencies`). Otherwise ask where to create it.
- Stay on the current git branch unless the user asks for a new one.
- Use Bun and TypeScript when practical.
- Use Vite and React for browser apps. This skill does not cover other stacks.
- Add project `AGENTS.md` by copying `resources/sample-agents.md` from this
  skill's directory (the folder that contains `SKILL.md`).
- Create and update project `MEMORY.md`.
- Optimize for a secure, demoable MVP, not completeness.
- Ask whether the deployed app should require Google sign-in. Recommend yes
  unless the user wants it public.
- If yes, create or reuse `<name> app auth` with
  [`resources/secrets.md`](resources/secrets.md). Ask which Google emails may
  sign in; recommend the user's email.
- Use the active 1Password CLI account (`op whoami`) for secrets. Do not
  hardcode an account or vault.
- Put secrets in 1Password, Vercel env vars, and `.env.local` only.

## Interaction Flow

1. Ask for project name if missing:

   > What should we call the project?

2. Ask for project description if missing:

   > What should this app do?

3. If the current directory is not the app (see Required Defaults), ask where
   to create it.

4. Ask at most 10 clarifying questions before choosing how to build. Prefer
   3-5 when the app shape is clear. Ask one question at a time, include a
   recommended answer, and stop once app type, core flow, data needs, hosting
   needs, and success criteria are clear. Do not load a separate grilling
   skill.

5. After app shape is clear, ask about deploy access if not already decided:

   > Should the deployed app require Google sign-in? I recommend yes unless you
   > want it public.

   If yes, ask which Google emails may sign in, then read
   [`resources/secrets.md`](resources/secrets.md) before creating or reading
   any secret.

6. If Slack is in scope, ask which workspace to install into (the
   `example.slack.com` domain). Resolve OpenRouter, Slack, and other secrets
   with [`resources/secrets.md`](resources/secrets.md). Do not assume a company
   workspace.

7. Summarize the app plan and ask the user to confirm or correct it before
   implementation.

## Build Routing

Load only the resources the app needs. Do not load the others.

- Hosting: always read [`resources/hosting.md`](resources/hosting.md) before
  deploy.
- Secrets: always read [`resources/secrets.md`](resources/secrets.md) before
  creating or reading any secret.
- LLMs: read [`resources/llms.md`](resources/llms.md) only if the app calls a
  model.
- Storage: read [`resources/storage.md`](resources/storage.md) only if durable
  state or files are needed.
- Slack: read [`resources/slack.md`](resources/slack.md) only if the user asked
  for Slack. Prefer a web form when Slack setup would slow launch.

For data, prefer Upstash via Vercel Marketplace; use Vercel Blob for object
storage. Use OpenRouter when an LLM is in scope. Use the active `op` CLI
account for secrets.

## Scope Control

- Help notice scope creep, integration risk, and polish work that threatens
  launch.
- If launch readiness looks at risk, ask:

  > What is the smallest version we can get launched?

- When time is tight, suggest specific tradeoffs: seeded data instead of live
  data, a manual step instead of automation, one happy path instead of full
  CRUD, or a local demo instead of a deployed demo.
- Prefer happy paths, seeded examples, clear logs, and demo scripts over broad
  feature completeness.
- If deployment stalls, offer a local demo, static preview, screenshots, or a
  short recorded walkthrough.

## Project Scaffold

Use this scaffold only after deciding that a Vite React browser app is the right
fit.

```bash
APP_NAME="<kebab-case-name>"
APP_DIR="<project-dir>"
mkdir -p "$(dirname "$APP_DIR")"
bun create vite "$APP_DIR" --template react-ts
touch "$APP_DIR/MEMORY.md"
cd "$APP_DIR"
bun install
```

Copy `resources/sample-agents.md` from this skill's directory to
`$APP_DIR/AGENTS.md`.

Only create a new branch if the user asked for one.

Replace the default Vite screen with the real core flow when practical. If the
flow is not clear yet, create a small themed first screen with:

- Project name.
- One visible detail tied to the idea.

## Project Files

Create project `README.md` with these sections:

- `What it is`: one-sentence app purpose.
- `Run locally`: install and dev commands.
- `Deploy`: selected hosting path.
- `Access`: public, or Google sign-in (name the 1Password item, not emails).
- `Demo`: goal, happy path, fallback, known rough edges.
- `Collaboration`: project branch, teammate prompts, push/pull guidance.
- `Storage`, `Slack`, or `LLMs`: only when those integrations exist.

Seed `MEMORY.md` with durable context from onboarding: project goal, MVP scope,
data notes, security judgment calls, and deployment notes.

Keep README `Demo` and `Collaboration` sections current as the project changes.

## Handoff

After a working version exists, tell the user:

- App URL, if deployed.
- 1Password item title for app auth, if Google sign-in is enabled. Do not
  print secrets or the allowlist.
- Local run command.
- What was built.

Then ask:

> What should we improve next?

## Git Hygiene

Launch repo (wherever this session started, including a dotfiles repo):

- Do not commit or stage files there for this skill.
- Keep unrelated repo changes unstaged.

New app directory:

- Commit app source, config, middleware/auth files, `package.json`, and
  lockfiles after each logical step only if the user asked to commit in this
  session. Otherwise leave the working tree for them.
- Do not commit `.vercel/`, `.vercel/.env*.local`, `.env.local`, or secrets.
