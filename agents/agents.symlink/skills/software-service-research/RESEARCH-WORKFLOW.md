# Research workflow

## 1. Identity and research map

Establish canonical product, API, docs, jobs, blog, status, trust, GitHub, and model-hub domains. Read About/Terms/footer and legal records when useful. Record rebrands, acquisitions, historical versions, spelling/transliteration variants, and unrelated namesakes.

Create an initial list of claims and open questions tied to the user's purpose. Prioritize facts whose answers could change the conclusion or decision; do not let marketing positioning determine the actual architecture. Record the requested emphasis, appropriate depth, and any constraints.

## 2. Search tracks

Batch independent searches and reads where tools support it; keep dependent inspection sequential. Use multiple languages when attributable builders publish outside English. Search targeted combinations, adapting to findings:

| Track | Search families | Highest-value evidence |
|---|---|---|
| Product | service + docs, API, integrations, changelog | Official schemas, behavior, constraints, workflows |
| Architecture | service + architecture, engineering, infrastructure, scaling, incident | Engineer articles, talks, status incidents, deployment docs |
| AI | service + models, inference, fine-tuning, retrieval, embeddings, evaluation | Model cards, official jobs, research papers, first-person posts |
| Builders | founder/engineer + service, previous company, technical profile | Cross-linked professional accounts and original publications |
| Code | official org and attributable handles + repos/packages | Source, manifests, release history, provenance |
| Operations | service + hiring, backend, data, GPU, deliverability, SRE | Current/archived official role descriptions |
| Publications | builder/service + blog, podcast, conference, slides | Original publisher, organizer, recording, transcript |
| Governance | service + security, trust, subprocessors, privacy, SOC2 | Exact policy language, dates, published audit status |

Choose additional sources by the question they can resolve; these are leads, not a required checklist:

| Question | Additional public sources | Attribution limit |
|---|---|---|
| Which dependencies or client tools are used? | Official package registries, SDK releases, manifests, public repo issues/discussions | SDK dependencies establish client scope; issues may describe proposed or historical usage. |
| Which infrastructure or AI providers are adopted? | Vendor case studies, partner engineering posts, model-provider customer stories | Attribute vendor/company claims and their dates; partnership or compatibility alone does not establish internal adoption. |
| What data flows or external processing are disclosed? | Subprocessor lists, privacy documents, integration guides | A listed provider may support only a particular feature or business function. |
| What constraints shaped the architecture? | Incident write-ups, migration posts, deprecation notices | Identify the affected component and version; past failures or migrations do not establish today's stack. |
| Have builders disclosed additional details? | Attributable Hacker News/Reddit comments, personal newsletters, podcasts, slides | Corroborate identity and role; unattributed community posts supply leads, not implementation facts. |

Search results and mirrors are discovery aids. Follow claims to the source owner. If only a mirror survives, mark the claim unverified and avoid using it as the foundation for a named production dependency.

Use ordinary published archives if available; label historical evidence. Do not route around blocked pages. Document promising inaccessible sources and what they might resolve.

For material stack claims, distinguish current evidence, historical evidence, and current status unverified. Check for newer releases, migrations, acquisitions, or conflicting disclosures when they could change applicability. An access date does not make an old implementation description current.

## 3. Public technical inspection

### API

Read the documented API/schema without issuing real workloads. Note:

- Resource boundaries, authentication scope, validation, limits, pagination.
- Natural-language interpretation versus structured requests.
- Jobs, statuses, progress, polling, callbacks, traces, and result schemas.
- Data enrichment, search filters, scores, explanations, provenance.
- Stateful actions, retries/idempotency if documented, accounting, moderation.
- Feedback/optimization, human review, pauses, and explicit failure behavior.

An async run suggests background execution, not a particular queue. A structured output schema does not prove constrained decoding. A semantic score does not prove cosine similarity or a vector database. Generated schema conventions are fingerprints, not conclusive backend identification.

For downloaded OpenAPI JSON, use the inventory helper. Distinguish local schema counts from company scale claims. Do not treat schemas as proof of runtime enforcement.

### Frontend and public artifacts

Inspect normal unauthenticated HTML and scripts loaded by the page. Look for framework/runtime signatures, import/package identifiers, auth state, analytics config, UI libraries, payment integration, and public endpoint references. Record small sanitized snippets or file/field names.

Inspect context around matches. A vendor name in prose, bundled unused dependency, illustrative example, preload, or configuration flag has different evidentiary strength from an active integration. Do not print token values or unnecessary public identifiers. CDN usage does not establish origin hosting.

Keep marketing-site fingerprints separate from application frontend, public SDK, production backend, and internal-development evidence. Do not extend an observed dependency beyond the component inspected.

Do not enumerate unlinked internal routes, seek source-map leaks, exploit exposed files, or inspect user/account data. Third-party stack scanners are leads requiring verification.

### Repositories and models

Separate official production code, employee personal projects, dependencies, forks, SDKs, external integrations, demos, applicant submissions, and unrelated namesakes. Require cross-linked identity evidence before attributing an author.

Read README/manifests and relevant implementation paths. A personal repo may illustrate a builder's design philosophy without proving company adoption. Version pins in deployed/released official source are stronger than README mentions. No public repos/models means none were visible in the checked accounts, not that the company lacks private code/models.

Avoid applicant trace dumps or files flagged as confidential. Synthetic provider names in exercises are not vendor disclosures. Training/adapting/serving a model are different claims.

## 4. Publications and talks

Trace posts to their authors and preserve absolute dates where available. Distinguish publication, event, recording, and indexed/crawl dates. Read technical content, not just search snippets.

For talks, identify speaker, organizer, title, event date, available slides/recording, and whether a transcript was actually read. Use timestamps from the inspected edition; audio/video edits differ. Prior-career talks establish experience, not the current service's stack.

If captions or a transcript are unavailable, provide navigation leads and disclose the limit. Do not attribute detailed spoken assertions based on titles or chapter markers.

## 5. Synthesis and gap closure

Construct a logical map: inputs -> reusable data -> retrieval/decision -> action -> feedback. Add storage, jobs, human controls, and internal development separately where evidence supports them. Mark inferred boundaries and alternatives.

Explain strategy through supported decisions: compute ownership, reuse versus on-demand work, model specialization, explicit state, quality gates, delivery costs, context engineering, and workflow integration. Do not assume all services use all patterns.

For tool likelihood, prioritize company-specific fingerprints, attributed disclosures, and verified code. Use generic technology examples only as alternatives when helpful, not as a long asserted stack list. Explain why each likelihood assessment could be wrong.

Translate findings into implications for the user's purpose. When recommending actions, state supporting evidence, assumptions, and what must be validated. For a similar-product investigation, distinguish transferable patterns, context-dependent choices, and proposed experiments; do not assume the researched stack is the best fit.

Follow unresolved leads in order of their potential to change the conclusion or action. Search negative alternatives that could falsify attractive hypotheses. Pair material unknowns with the evidence needed to resolve them. Stop when further targeted searches add little to consequential questions; summarize undisclosed components rather than promising exhaustive access to private implementation.
