# Agent instructions

This is a Vercel-hosted app. Optimize for a demoable MVP.

## Build Priorities

- Build the demo path first.
- Keep code easy to debug; log important user actions, API calls, background
  work, and failures.
- Use seeded or local data when live data would slow the MVP.
- Do not expose secrets, private data, or sensitive content.
- Do not spend time on markdown linting unless it blocks a build, deploy, or
  required check.

## Memory

Maintain `MEMORY.md` in the project root. Update it with durable context:

- User goals and feedback.
- Product decisions.
- Data sources and access constraints.
- Deployment details.
- Known limitations and follow-up ideas.

Do not store secrets in `MEMORY.md`.

## README

Keep these README sections current:

- `Demo`: goal, happy path, launch URL or local fallback, whether access is
  public or Google sign-in, known rough edges. Do not write secrets.
- `Collaboration`: project branch, teammate prompts, and plain-language
  push/pull guidance.

## Git

- Work on the project branch.
- Commit after every logical step.
- Pull the latest project branch before parallel work.
- Push completed commits so teammates can continue from current code.
- Keep unrelated repo changes unstaged.
