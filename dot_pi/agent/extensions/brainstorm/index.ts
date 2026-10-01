/**
 * /brainstorm extension.
 *
 * Registers `/brainstorm <slug>`, where <slug> is a kebab-case title. The
 * command's entire procedure lives in `procedure.md` next to this file; edit
 * that document to evolve the command. It is re-read on every invocation, so
 * edits take effect immediately (no reload required). Every `{{slug}}` token
 * in the document is replaced with the slug argument before the procedure is
 * handed to the agent as a user message.
 */

import { existsSync, readFileSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const extensionDir = dirname(fileURLToPath(import.meta.url));
const procedurePath = join(extensionDir, "procedure.md");

/** Kebab-case: lowercase letters or digits, single hyphens, none leading/trailing. */
const SLUG_PATTERN = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

/** Slugs that already exist under <cwd>/docs/brainstorm, for argument completion. */
function existingSlugs(): string[] {
	try {
		const dir = join(process.cwd(), "docs", "brainstorm");
		if (!existsSync(dir)) return [];
		return readdirSync(dir, { withFileTypes: true })
			.filter((entry) => entry.isDirectory() && SLUG_PATTERN.test(entry.name))
			.map((entry) => entry.name)
			.sort();
	} catch {
		return [];
	}
}

export default function brainstormCommand(pi: ExtensionAPI) {
	pi.registerCommand("brainstorm", {
		description: "Run the brainstorm procedure in docs/brainstorm/<slug>/",
		getArgumentCompletions: (prefix) => {
			const matches = existingSlugs().filter((slug) => slug.startsWith(prefix));
			return matches.length > 0 ? matches.map((slug) => ({ value: slug, label: slug })) : null;
		},
		handler: async (args, ctx) => {
			const slug = args.trim();
			if (!SLUG_PATTERN.test(slug)) {
				ctx.ui.notify(
					"Usage: /brainstorm <slug> — the slug must be kebab-case, e.g. /brainstorm fast-matrix-mult",
					"warning",
				);
				return;
			}

			if (!ctx.isIdle()) {
				ctx.ui.notify("The agent is busy; run /brainstorm again once it is idle.", "warning");
				return;
			}

			let procedure: string;
			try {
				procedure = readFileSync(procedurePath, "utf-8");
			} catch (error) {
				ctx.ui.notify(`Could not read ${procedurePath}: ${String(error)}`, "error");
				return;
			}

			pi.sendUserMessage([`Running /brainstorm ${slug}.`, "", procedure.replaceAll("{{slug}}", slug)].join("\n"));
		},
	});
}
