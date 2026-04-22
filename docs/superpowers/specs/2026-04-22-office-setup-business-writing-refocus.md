# Office-Setup — Business-Writing Refocus

**Date:** 2026-04-22
**Status:** Accepted
**Related issue:** #31

## Context

`office-setup` Q1 lumped three unrelated use cases into one skill: emails, reports, presentations. The Q1 answer was a label only — it did not functionally bifurcate the emitted CLAUDE.md guidelines. The Google-Drive MCP offer was gated on the "reports" answer in a way that felt arbitrary next to a generic guideline body that never separated email and report advice.

## Decision

**Option B — refocus.** Keep the single `office-setup` skill. Commit its scope to business writing only (emails, memos, reports, proposals). Drop presentation scope entirely. Make Q1 functionally branch the emitted rules and align the MCP gates with the narrower scope.

## Option A — considered and rejected

Split into three skills (`email-setup`, `report-writing-setup`, `presentation-setup`).

- Rejected because none of the three sub-skills is large enough to justify a standalone setup flow — splitting would triple the install/upgrade overhead for marginal separation.
- Rejected because the onboarding Step 3 list is already near capacity (11 numbered options + aside). Adding two more dilutes the category structure established in #26/#27.
- Rejected because presentation work is not well served by a rule-file approach — slide design depends on the template toolchain (Keynote / PowerPoint / Google Slides / reveal.js), not on written-style rules. A dedicated skill can be spun off later if demand emerges.

## Option B — concrete changes

1. **Frontmatter & intro** (`skills/office-setup/SKILL.md`). Scope line narrowed to "business writing (emails, memos, reports, proposals). Presentations and slide decks are explicitly out of scope."

2. **Q1 rewrite.** Three choices (A: emails/short messages, B: reports/proposals, C: mix). Presentation option removed. Answer stored as `document_focus` for downstream branching.

3. **MCP gates.**
   - Gmail offered when `document_focus` is `A` or `C`.
   - Google Calendar offered only if Gmail was offered (chained).
   - Google Drive offered when `document_focus` is `B` or `C`.

4. **Emitted CLAUDE.md.** `## Guidelines` has a shared header (style, proofread, ask-on-ambiguity) plus one or two subheadings keyed on `document_focus`:
   - `A` → only `### Emails and short messages`.
   - `B` → only `### Reports and proposals`.
   - `C` → both subheadings in order.
   Presentation guidelines (slide structure, speaker notes) are removed entirely.

5. **Completion summary.** Scope line names the narrower focus and explicitly states presentations are not covered. Next-steps examples branch on `document_focus`.

6. **Onboarding Step 3 option 9** relabelled to "Business Writing — emails, memos, reports, proposals (Office setup)". Slug unchanged.

7. **Onboarding Step 4 Q2 B-c** reworded to "Business writing — emails, memos, reports, proposals → recommend `office-setup`". Tree depth unchanged.

8. **README** "What's Inside" row updated to match the narrower scope; no other structural change.

## Acceptance criteria (from issue)

- No single skill tries to serve three unrelated use cases with one generic ruleset. ✓ Presentation scope removed; guidelines branch on `document_focus`.
- Q1 (or skill choice) actually produces different artifacts per path. ✓ Q1 answer controls the emitted subheadings and the MCP-offer gates.
- MCP offer gates are consistent with the chosen scope. ✓ Gmail + Calendar gated on email path; Drive gated on report path.

## Risks

- Users who previously ran `office-setup` for presentation work get guidelines that no longer match. Mitigation: `/upgrade-setup` regenerates CLAUDE.md cleanly; completion summary states the narrower scope so returning users see the change immediately.
- A standalone presentation-setup skill is not currently on the roadmap. If demand emerges, it can be added later without breaking this refocus.
