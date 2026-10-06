# Evidence and report contract

## Evidence labels

| Label | Meaning | Example |
|---|---|---|
| Observed | Directly visible public artifact/interface or authoritative record | A released manifest pins a package; an API exposes a job resource. |
| Firsthand claim | Company/builder statement, not independently measured | A role advertises owned GPUs or autonomous deployments. |
| Inference | Interpretation of specific evidence | Async runs suggest background workers; schema conventions suggest a framework. |
| Unknown | Available research did not establish the answer | Exact embedding model or database is undisclosed. |

Source authenticity and claim truth are separate. A verified founder can publish an unverified performance claim. Several pages copying the same statement are not independent corroboration.

When ranking tools, use **observed**, **explicitly claimed**, **likely**, **plausible alternative**, or **unknown**. Include evidence and a limitation. Reserve "likely" for service-specific clues; architectural necessity alone usually supports a category, not a vendor. Do not manufacture probabilities.

State evidence scope for material claims: marketing site, application frontend, public SDK, production backend, internal development, or another identified component. A manifest establishes a dependency in that artifact; production deployment requires separate evidence. Do not extend component findings to the whole service.

Label temporal applicability as **current**, **historical**, or **current status unverified**, with the supporting date/version. Use current only when evidence supports present applicability; historical evidence is not automatically false or obsolete, but does not establish continued use. Keep temporal applicability separate from evidence strength.

## Evidence ledger

For important findings, retain a compact record:

| Claim | Source URL/artifact | Author/owner | Publication date | Access date | Label | Component / temporal applicability | Limitation |
|---|---|---|---|---|---|---|---|
| [Claim] | [Direct source] | [Owner] | [Date/unknown] | [Date] | [Label] | [Component; current/historical/unverified; version if known] | [Alternative or gap] |

Record repo ownership and whether deployment is established. Preserve conflicting numbers with their dates, units, and definitions. Do not combine overlapping entity counts or compare incompatible time periods. Explicitly label scenario calculations and their assumptions.

Cite sources beside the claims they support. Link source pages, exact repo files/revisions when available, and the correct recording edition. Do not cite search result pages. Respect quotation and source-derived word limits; avoid copying entire pages into the answer or artifact.

## Suggested report structure

Adapt this outline to the service and user request; do not force unsupported sections:

1. **Finding and scope:** user's purpose, research date, canonical service, strongest relevant conclusion, evidence limits.
2. **Identity and builders:** entity, founders, attributable engineers, rebrands, namesake exclusions.
3. **System reconstruction:** logical diagram, verified workflow, inferred boundaries.
4. **Data and search:** acquisition, entity resolution, enrichment, freshness, retrieval, provenance, economics.
5. **AI/model strategy:** stages, owned/hosted inference, adaptation, routing, evaluation, unknowns.
6. **Application and infrastructure:** API, frontend/backend clues, auth, storage, jobs, delivery, observability.
7. **Development and operations:** coding tools, agent harnesses, memory/context, deployment, support, quality gates.
8. **Repository map:** official code, personal projects, dependencies, third-party integrations; confidence boundaries.
9. **Publications:** developer posts, social disclosures, talks/podcasts, inspected content and availability.
10. **Likely tools:** ranked table with concrete evidence and alternatives, not an invented dependency list.
11. **Strategic interpretation and implications:** explain what choices accomplish, their costs/constraints, and relevant actions for the user.
12. **Unresolved questions and coverage limits:** consequential missing facts, how they could change the conclusion, evidence needed to resolve them, blocked sources, search saturation.

For non-AI services, replace model sections with the relevant domain architecture. For a narrow follow-up, answer the question directly and update the existing report if useful.

## Actionable synthesis

For a decision brief, organize the report around the decision, supporting findings, tradeoffs, recommended next steps, and material unknowns. For deep investigations, add implications where they serve the user's purpose. A focused factual answer need not include recommendations.

Keep recommendations distinct from service findings. Explain why an action follows from the evidence, where it depends on inference, and what could change it. Do not recommend copying a tool solely because the service uses it. For similar-product work, identify transferable patterns, context-dependent choices, and experiments with an observable result that would inform the decision. Proposing an experiment does not authorize executing it.

Use a compact table when it makes the implications easier to compare:

| Finding | Implication for the user | Suggested action | Evidence / dependency |
|---|---|---|---|
| Documented jobs support long-running tasks | A similar workflow needs explicit execution state | Prototype job states and failure recovery | API establishes behavior; queue implementation remains unknown. |

For material unknowns, state the question, why its answer matters, and the specific disclosure or observation needed to resolve it. Prioritize these by their effect on the conclusion; avoid a generic backlog of every undisclosed component.

## Useful tables

Tool table:

| Function | Tool/category | Status | Evidence | Limitation |
|---|---|---|---|---|
| [Function] | [Name or category] | [Observed/claimed/likely/alternative/unknown] | [Primary source] | [Scope or competing explanation] |

Repo table:

| Repository | Owner relationship | What inspected code establishes | Production use |
|---|---|---|---|
| [Direct repo] | [Official/personal/external] | [Specific behavior] | [Established/unverified] |

## Verification and delivery

- Check every local artifact link resolves and every external link is a real retrieved/discovered source.
- Recheck high-impact claims against the source, especially identities, model names, counts, certification, and dates.
- Verify that component scope and temporal applicability match the evidence; refresh material claims when newer releases, migrations, acquisitions, or conflicting disclosures could change them.
- Use exact language for audited/certified versus preparing/claiming compliance. Disclosure gaps do not establish missing controls.
- Validate arithmetic and label workload/cost scenarios as illustrative rather than measured benchmarks.
- Ensure the main report is readable without the appendix and chat synthesis is readable without collapsed progress updates.
- State what was inspected; never claim code execution, transcript review, authenticated testing, or exhaustive coverage that did not occur.
- Link any saved report in chat and open it in the host editor when supported and useful.
- End with concrete findings, relevant actions, and material unknowns. Do not stop at a plan or offer to perform research already requested.
