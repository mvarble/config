/**
 * /explain extension.
 *
 * Registers `/explain <title>`, where <title> is the title of a source
 * document (the part of its filename after the YYYY-MM-DD- date prefix). The
 * command's entire procedure lives in `procedure.md` next to this file; edit
 * that document to evolve the command. It is re-read on every invocation, so
 * edits take effect immediately (no reload required). Every `{{title}}` token
 * in the document is replaced with the title argument before the procedure is
 * handed to the agent as a user message.
 *
 * Tab-completion suggests titles from <cwd>/source/*.md, matching on either
 * the title or the full date-prefixed filename, newest first.
 */

import { existsSync, readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const extensionDir = dirname(fileURLToPath(import.meta.url));
const procedurePath = join(extensionDir, "procedure.md");

/** Source documents in <cwd>/source/, newest date first. */
function sourceDocuments(): string[] {
	try {
		const dir = join(process.cwd(), "source");
		if (!existsSync(dir)) return [];
		return readdirSync(dir)
			.filter((f) => f.endsWith(".md"))
			.sort()
			.reverse();
	} catch {
		return [];
	}
}

/** Strip the YYYY-MM-DD- prefix and .md suffix from a source filename. */
function titleFromFilename(filename: string): string {
	return filename.replace(/^\d{4}-\d{2}-\d{2}-/, "").replace(/\.md$/, "");
}

export default function explainCommand(pi: ExtensionAPI) {
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

		handler: async (args, ctx) => {
			const title = args.trim();
			if (!title) {
				ctx.ui.notify("Usage: /explain <title> — e.g. /explain bayes-rule", "warning");
				return;
			}

			let procedure: string;
			try {
				procedure = readFileSync(procedurePath, "utf-8");
			} catch (error) {
				ctx.ui.notify(`Could not read ${procedurePath}: ${String(error)}`, "error");
				return;
			}

			const message = ["Running /explain " + title + ".", "", procedure.replaceAll("{{title}}", title)].join("\n");

			if (ctx.isIdle()) {
				pi.sendUserMessage(message);
			} else {
				pi.sendUserMessage(message, { deliverAs: "followUp" });
				ctx.ui.notify("Queued /explain as a follow-up", "info");
			}
		},
	});
}
