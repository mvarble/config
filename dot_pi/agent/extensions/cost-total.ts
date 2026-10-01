/**
 * /cost-total — total model cost from every saved session file.
 *
 * Usage:
 *   /cost-total          all time
 *   /cost-total today    since local midnight
 *   /cost-total 7d       last N days (any number, e.g. 30d)
 *   /cost-total month    since the 1st of this month
 *
 * Adds up usage.cost.total from assistant messages, tool results with usage,
 * usage entries (e.g. cache warming), and compaction/branch summaries.
 * Entries copied into /fork or /clone sessions are counted only once.
 * Figures come from Pi's model pricing, not from your provider's bill.
 */

import { promises as fs } from "node:fs";
import * as path from "node:path";
import {
    getAgentDir,
    type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";

type Totals = { cost: number; tokens: number; calls: number };

async function findJsonl(dir: string, out: string[] = []): Promise<string[]> {
    let entries;
    try {
        entries = await fs.readdir(dir, { withFileTypes: true });
    } catch {
        return out;
    }
    for (const e of entries) {
        const p = path.join(dir, e.name);
        if (e.isDirectory()) await findJsonl(p, out);
        else if (e.isFile() && e.name.endsWith(".jsonl")) out.push(p);
    }
    return out;
}

function sessionsRoot(
    sessionDir: string | undefined,
    usesDefault: boolean,
): string {
    if (usesDefault || !sessionDir) {
        return (
            process.env.PI_CODING_AGENT_SESSION_DIR ||
            path.join(getAgentDir(), "sessions")
        );
    }
    // Default layout nests per-cwd folders named --<path>--; scan their parent.
    const base = path.basename(sessionDir);
    return base.startsWith("--") && base.endsWith("--")
        ? path.dirname(sessionDir)
        : sessionDir;
}

function parseSince(
    arg: string,
): { since?: number; label: string } | undefined {
    const a = arg.trim().toLowerCase();
    if (!a || a === "all") return { label: "all time" };
    const now = new Date();
    if (a === "today") {
        return {
            since: new Date(
                now.getFullYear(),
                now.getMonth(),
                now.getDate(),
            ).getTime(),
            label: "today",
        };
    }
    if (a === "month") {
        return {
            since: new Date(now.getFullYear(), now.getMonth(), 1).getTime(),
            label: "this month",
        };
    }
    const m = a.match(/^(\d+)d$/);
    if (m)
        return {
            since: Date.now() - Number(m[1]) * 86_400_000,
            label: `last ${m[1]} days`,
        };
    return undefined;
}

function usageOf(entry: any): { usage: any; model: string } | undefined {
    if (entry?.type === "message" && entry.message?.usage) {
        const msg = entry.message;
        return {
            usage: msg.usage,
            model: msg.model ? `${msg.provider ?? "?"}/${msg.model}` : "(tool usage)",
        };
    }
    if (
        (entry?.type === "usage" ||
            entry?.type === "compaction" ||
            entry?.type === "branch_summary") &&
        entry.usage
    ) {
        const model = entry.model
            ? `${entry.provider ?? "?"}/${entry.model}`
            : `(${entry.type})`;
        return { usage: entry.usage, model };
    }
    return undefined;
}

const fmt$ = (n: number) => `$${n.toFixed(n < 1 ? 4 : 2)}`;
const fmtTok = (n: number) =>
    n >= 1e6
        ? `${(n / 1e6).toFixed(2)}M`
        : n >= 1e3
            ? `${(n / 1e3).toFixed(1)}k`
            : `${n}`;

export default function(pi: ExtensionAPI) {
    pi.registerCommand("cost-total", {
        description:
            "Show total cost across all saved sessions (args: today | month | Nd | all)",
        getArgumentCompletions: (prefix) => {
            const opts = ["all", "today", "7d", "30d", "month"].filter((o) =>
                o.startsWith(prefix),
            );
            return opts.length ? opts.map((o) => ({ value: o, label: o })) : null;
        },
        handler: async (args, ctx) => {
            const range = parseSince(args ?? "");
            if (!range) {
                ctx.ui.notify(
                    "Usage: /cost-total [all | today | month | <N>d]",
                    "warning",
                );
                return;
            }

            const sm = ctx.sessionManager as any;
            const root = sessionsRoot(
                sm.getSessionDir?.(),
                sm.usesDefaultSessionDir?.() ?? true,
            );
            const files = await findJsonl(root);

            const seen = new Set<string>();
            const total: Totals = { cost: 0, tokens: 0, calls: 0 };
            const byModel = new Map<string, Totals>();
            let sessionsWithCost = 0;
            let badLines = 0;

            for (const file of files) {
                let text: string;
                try {
                    text = await fs.readFile(file, "utf8");
                } catch {
                    continue;
                }
                let fileHadCost = false;
                for (const line of text.split("\n")) {
                    if (!line.trim()) continue;
                    let entry: any;
                    try {
                        entry = JSON.parse(line);
                    } catch {
                        badLines++;
                        continue;
                    }
                    const u = usageOf(entry);
                    if (!u) continue;

                    // Forks/clones copy entries; count each one once.
                    const key = `${entry.id}|${entry.timestamp}`;
                    if (seen.has(key)) continue;
                    seen.add(key);

                    if (range.since !== undefined) {
                        const t = Date.parse(entry.timestamp);
                        if (!Number.isFinite(t) || t < range.since) continue;
                    }

                    const cost = Number(u.usage.cost?.total) || 0;
                    const tokens = Number(u.usage.totalTokens) || 0;
                    total.cost += cost;
                    total.tokens += tokens;
                    total.calls++;
                    const m = byModel.get(u.model) ?? { cost: 0, tokens: 0, calls: 0 };
                    m.cost += cost;
                    m.tokens += tokens;
                    m.calls++;
                    byModel.set(u.model, m);
                    if (cost > 0) fileHadCost = true;
                }
                if (fileHadCost) sessionsWithCost++;
            }

            const lines = [
                `Total cost (${range.label}): ${fmt$(total.cost)}`,
                `${fmtTok(total.tokens)} tokens · ${total.calls} calls · ${sessionsWithCost} sessions with cost · ${files.length} files scanned`,
            ];
            const models = [...byModel.entries()].sort(
                (a, b) => b[1].cost - a[1].cost,
            );
            if (models.length) {
                lines.push("", "By model:");
                for (const [name, t] of models) {
                    lines.push(
                        `  ${fmt$(t.cost).padStart(10)}  ${fmtTok(t.tokens).padStart(7)} tok  ${name}`,
                    );
                }
            }
            if (badLines) lines.push("", `(${badLines} unreadable lines skipped)`);
            lines.push(
                "",
                `Source: ${root}`,
                "Estimated from Pi's model pricing; not your provider bill.",
            );

            ctx.ui.notify(lines.join("\n"), "info");
        },
    });
}
