<!--
This document defines the /explain command. Edit it freely: the extension
re-reads it on every invocation, so changes take effect on the next /explain
run with no reload needed. Before the procedure is handed to the agent, every
{{title}} token below is replaced with the command's title argument.
-->

I want you to help me understand a document titled "{{title}}". Work through the following three phases in order.

# Parse the document

Attempt to find the document at `source/YYYY-MM-DD-{{title}}.{md|html}` or something close to it. If it is not clear from my title which document I mean, ask me to confirm the exact path before going further. Once you have identified the document, read it in full and understand its contents. In particular, consider:

- What is the overall message and the argument it makes?
- What supporting material does the argument rest on?
- What assumptions does the document make?
- What knowledge and context does the author assume the reader already has?

# Assess my understanding

Do not assume I have already read the document. For each concept or piece of contextual information the author assumed of the reader, ask me about my level of understanding of it. If my answers warrant further inquiry, keep asking me follow-up questions until you have a good sense of what I actually understand. Before asking about a concept, check `docs/concepts/*`: for any concept documented there, you may assume I already understand it to the extent that its document covers, and you do not need to ask me about that material.

# Write me a follow-up document

Once you understand both the source document and my level of knowledge, write a document at `docs/writeups/YYYY-MM-DD-{{title}}.md`, where the date and title are taken from the source document's filename. The document is an analysis of the source document: notes for me to read alongside it so that I can understand it more easily. Its purpose is to help me learn the foundational and contextual knowledge the author assumed of the reader, and to help me understand any complex or unclear concepts the document presents.

## Maintain the concept library

Every concept you address in the follow-up document must have its own document in `docs/concepts/`. Before writing, list the concepts the source document requires and check each against `docs/concepts/*`:

- If a concept is already documented there, link to that existing document. Never rewrite, replace, or duplicate an existing concept document.
- If a concept is **new** — it is worth addressing for my understanding but was not already present in `docs/concepts/` — it deserves its own new file. Do not treat the follow-up document as a substitute for it, and do not fold it into an existing concept document. Create `docs/concepts/<concept>.md` and link to it from the follow-up document.

The bar for "worth addressing" is exactly whether the follow-up document needs to explain the concept to me: any concept that earns a paragraph, section, or explicit definition is worth its own file. A term that is merely mentioned in passing without being explained need not become a concept document. When in doubt, create the file — a concept that helped me understand this document is likely to recur in others.

A concept document must be self-contained, written as paragraph prose, and explain the concept on its own terms rather than only as it appears in the source document. Name the file after the concept (for example, `docs/concepts/net-interest-margin.md`) so later /explain runs can discover it.

Wherever you explain a concept — here or in the follow-up document — prefer a concrete example if a suitable one is available: use an example from the source document when it provides one, and otherwise construct a simple illustration of your own. A concept is best understood through an example, so do not settle for an abstract definition when an example would make it clearer.

## Structure and prose

Begin the follow-up document by stating which document you are summarizing, with a markdown link to the source in `source/`, followed by a list of the concepts discussed, each linked to its document in `docs/concepts`. Every entry in that list must resolve to a real file — an existing concept document or one you created in the previous step.

Write the document as paragraph prose, referring to "the document" and "the author": from the writing alone it must be obvious that it discusses another document. Other than referencing the source document itself, the document must be completely self-contained — do not reference anything from this conversation or session.
