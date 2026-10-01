/**
 * /explain extension.
 *
 * Registers two commands:
 *
 * - `/explain <title>` explains a source document and writes a companion in
 *   `docs/writeups/<slug>/`. Its procedure lives in `procedure.md` next to this file,
 *   and every `{{title}}` token in that document is replaced with the title
 *   argument.
 * - `/explain-concept <description>` assesses the reader's knowledge of a
 *   concept and writes one or more documents that teach it, one folder each in
 *   `docs/concepts/`. Its procedure
 *   lives in `concept-procedure.md` next to this file, and every
 *   `{{description}}` token is replaced with the description argument.
 *
 * Both procedures are re-read on every invocation, so edits take effect
 * immediately (no reload required).
 *
 * Tab-completion for `/explain` suggests titles from <cwd>/source/*.md,
 * matching on either the title or the full date-prefixed filename, newest
 * first. For `/explain-concept` it suggests documented concepts from
 * <cwd>/docs/concepts/<slug>/index.{md,svx}, by title.
 *
 * Documents follow the layout of a mesearch site; see the project's AGENTS.md.
 */

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

const extensionDir = dirname(fileURLToPath(import.meta.url));

/** Markdown files directly inside `dir`, or [] when the directory is absent. */
function markdownFiles(dir: string): string[] {
	try {
		if (!existsSync(dir)) return [];
		return readdirSync(dir).filter((f) => f.endsWith(".md"));
	} catch {
		return [];
	}
}

/** Source documents in <cwd>/source/, newest date first. */
function sourceDocuments(): string[] {
	return markdownFiles(join(process.cwd(), "source")).sort().reverse();
}

interface Concept {
	slug: string;
	title: string;
}

/** The `title` in a document's frontmatter, if it has one. */
function frontmatterTitle(file: string): string | undefined {
	try {
		const head = /^---\r?\n([\s\S]*?)\r?\n---/.exec(readFileSync(file, "utf-8"))?.[1] ?? "";
		const title = /^title:\s*(.+?)\s*$/m.exec(head)?.[1];
		return title?.replace(/^(['"])(.*)\1$/, "$2");
	} catch {
		return undefined;
	}
}

/** Concept folders in <cwd>/docs/concepts/, alphabetical, with their titles. */
function conceptDocuments(): Concept[] {
	const dir = join(process.cwd(), "docs", "concepts");
	try {
		if (!existsSync(dir)) return [];
		return readdirSync(dir, { withFileTypes: true })
			.filter((entry) => entry.isDirectory())
			.map((entry) => {
				const index = ["index.md", "index.svx"]
					.map((name) => join(dir, entry.name, name))
					.find((file) => existsSync(file));
				return index ? { slug: entry.name, title: frontmatterTitle(index) ?? entry.name } : undefined;
			})
			.filter((concept): concept is Concept => !!concept)
			.sort((a, b) => a.slug.localeCompare(b.slug));
	} catch {
		return [];
	}
}

/** Strip the YYYY-MM-DD- prefix and .md suffix from a source filename. */
function titleFromFilename(filename: string): string {
	return filename.replace(/^\d{4}-\d{2}-\d{2}-/, "").replace(/\.md$/, "");
}

export default function explainExtension(pi: ExtensionAPI) {
	/**
	 * Read a procedure document, substitute its placeholder, and hand the
	 * result to the agent as a user message (or queue it as a follow-up).
	 */
	async function runProcedure(
		command: string,
		procedureFile: string,
		placeholder: string,
		usage: string,
		args: string,
		ctx: ExtensionCommandContext,
	): Promise<void> {
		const value = args.trim();
		if (!value) {
			ctx.ui.notify(usage, "warning");
			return;
		}

		const procedurePath = join(extensionDir, procedureFile);
		let procedure: string;
		try {
			procedure = readFileSync(procedurePath, "utf-8");
		} catch (error) {
			ctx.ui.notify(`Could not read ${procedurePath}: ${String(error)}`, "error");
			return;
		}

		const message = [`Running ${command} ${value}.`, "", procedure.replaceAll(placeholder, value)].join("\n");

		if (ctx.isIdle()) {
			pi.sendUserMessage(message);
		} else {
			pi.sendUserMessage(message, { deliverAs: "followUp" });
			ctx.ui.notify(`Queued ${command} as a follow-up`, "info");
		}
	}

	pi.registerCommand("explain", {
		description: "Explain a source/ document and write a docs/writeups/ companion",

		getArgumentCompletions: (prefix) => {
			const p = prefix.trim().toLowerCase();
			const matches = sourceDocuments().filter((f) => {
				const title = titleFromFilename(f);
				return f.toLowerCase().startsWith(p) || title.toLowerCase().includes(p);
			});
			if (matches.length === 0) return null;
			return matches.slice(0, 20).map((f) => ({
				value: titleFromFilename(f),
				label: titleFromFilename(f),
				description: f,
			}));
		},

		handler: (args, ctx) =>
			runProcedure(
				"/explain",
				"procedure.md",
				"{{title}}",
				"Usage: /explain <title> — e.g. /explain bayes-rule",
				args,
				ctx,
			),
	});

	pi.registerCommand("explain-concept", {
		description: "Assess my knowledge of a concept and write docs/concepts/ document(s)",

		getArgumentCompletions: (prefix) => {
			const p = prefix.trim().toLowerCase();
			const matches = conceptDocuments().filter(
				(c) => c.slug.includes(p) || c.title.toLowerCase().includes(p),
			);
			if (matches.length === 0) return null;
			return matches.slice(0, 20).map((c) => ({
				value: c.title,
				label: c.title,
				description: `docs/concepts/${c.slug}/`,
			}));
		},

		handler: (args, ctx) =>
			runProcedure(
				"/explain-concept",
				"concept-procedure.md",
				"{{description}}",
				"Usage: /explain-concept <description> — e.g. /explain-concept covered interest parity",
				args,
				ctx,
			),
	});
}
