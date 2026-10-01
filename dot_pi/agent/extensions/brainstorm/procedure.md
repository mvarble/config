<!-- This document defines the /brainstorm command. Edit it freely: the
extension re-reads it on every invocation, so changes take effect on the next
/brainstorm run with no reload needed. Before the procedure is handed to the
agent, every {{slug}} token below is replaced with the command's slug
argument. -->

# Brainstorm procedure for `{{slug}}`

All documents for this brainstorm live under `docs/brainstorm/{{slug}}/`,
relative to the current working directory. Work through the steps below in
order, stopping wherever a step says to stop.

## Goal creation

If `docs/brainstorm/{{slug}}/goal.md` does not exist, create the file (empty)
and stop, after telling me to write the goal into it. Do nothing else in this
step: no clarifying questions, no proposal.

## Goal clarification

Read `docs/brainstorm/{{slug}}/goal.md`. Its content is a goal to solve;
goals tend to be general in nature and can admit multiple solutions.

If the goal is in any way vague or difficult to understand, ask me questions
until it is clear; group the questions into a single message rather than
asking them one at a time. Once the goal is clear, propose edits to
`docs/brainstorm/{{slug}}/goal.md` for me to approve. Only once the goal is
clearly specified may you proceed to Brainstorm Proposal.

## Brainstorm Proposal

Propose an approach to solve the goal; if there is no single canonical
solution, propose up to three distinct approaches. For each approach, state
how it works, what it costs, what it assumes, where it fails, and the precise
name of any technique I might not know, together with where to verify it
(paper, standard reference, or web resource).

If an approach builds upon a large foundation of knowledge, ask me whether I
am aware of the prerequisites; if I am not, write additional material that
explains them. You may use the web to search for existing solutions or
algorithms.

Once you have brainstormed this out, write the proposal to
`docs/brainstorm/{{slug}}/proposal.md`. Write every document you produce in
paragraph-based prose, like a textbook: complete sentences rather than
fragments, no excessive tables or itemized lists, and the source formatting
rules given under Constraints. If the proposal is very
large, split it into multiple documents in `docs/brainstorm/{{slug}}/`,
treating `proposal.md` as the index and each other document as a chapter or
appendix. Always summarize the goal in `proposal.md` and reference `goal.md`;
if any prerequisite material exists, write it to its own document (for
example, `qr-factorization.md`). Conclude the proposal by stating which
approach you would take and why.

## Re-running with an existing proposal

If `docs/brainstorm/{{slug}}/proposal.md` already exists, read the goal
summary in it and see whether it differs from `goal.md`. If the summary is
similar to `goal.md`, simply say so and stop for my response. Otherwise,
re-perform Goal clarification and Brainstorm Proposal, taking into account
where the solutions may change under the new goal.

## Constraints

- Only edit the contents of `docs/brainstorm/{{slug}}/`; never modify any
  other file. Reading other files is fine.
- Write every document with one sentence per line and no wrapping: place
  each sentence on its own line, however long it is, and never insert line
  breaks to wrap text at a fixed column width. Separate paragraphs with a
  single blank line. These line breaks live only in the source text;
  markdown renders them as spaces, so the documents still read as flowing
  prose rather than as lists.
- Never refer to the old goal or to previous versions of these documents.
  Every `docs/brainstorm/{{slug}}/` directory must be completely
  self-contained: when re-running, rewrite documents from scratch so that each
  one stands alone under the current goal, rather than describing changes
  against what was written before.
