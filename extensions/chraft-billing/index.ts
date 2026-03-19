import fs from "node:fs";
import path from "node:path";
import type { OpenClawPluginApi } from "openclaw/plugin-sdk/chraft-billing";

type ChraftBillingConfig = {
  baseUrl?: string;
  timeoutMs?: number;
};

type UserContext = {
  chraftUseKey?: string;
  userId?: string;
  [key: string]: unknown;
};

function loadUserContext(): UserContext {
  try {
    const stateDir = process.env.OPENCLAW_STATE_DIR || "/data";
    const raw = fs.readFileSync(path.join(stateDir, "user-context.json"), "utf8");
    return JSON.parse(raw) as UserContext;
  } catch {
    return {};
  }
}

export default function register(api: OpenClawPluginApi) {
  const cfg = (api.pluginConfig ?? {}) as ChraftBillingConfig;

  const baseUrl = (cfg.baseUrl ?? process.env.CHRAFT_BASE_URL ?? "").replace(/\/$/, "");
  const timeoutMs = cfg.timeoutMs ?? 5000;

  if (!baseUrl) {
    api.logger.warn?.("chraft-billing: CHRAFT_BASE_URL not set — usage reporting disabled");
    return;
  }

  const endpoint = `${baseUrl}/api/openclaw/usage`;

  api.on("llm_output", async (event, ctx) => {
    if (!event.usage) return;

    const { input, output, cacheRead, cacheWrite } = event.usage;

    // Skip if all token counts are zero or missing
    const totalTokens = (input ?? 0) + (output ?? 0) + (cacheRead ?? 0) + (cacheWrite ?? 0);
    if (totalTokens === 0) return;

    // Read user context fresh each time to pick up any key rotation
    const userCtx = loadUserContext();
    const { chraftUseKey } = userCtx;

    if (!chraftUseKey) {
      api.logger.warn?.("chraft-billing: chraftUseKey not found in user-context.json — skipping");
      return;
    }

    const payload = {
      sessionId: event.sessionId,
      agentId: ctx.agentId,
      runId: event.runId,
      provider: event.provider,
      model: event.model,
      usage: {
        input: input ?? 0,
        output: output ?? 0,
        cacheRead: cacheRead ?? 0,
        cacheWrite: cacheWrite ?? 0,
        total: totalTokens,
      },
      timestamp: Date.now(),
    };

    // Fire-and-forget: never block the agent on billing
    fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${chraftUseKey}`,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(timeoutMs),
    }).catch((err: unknown) => {
      api.logger.warn?.(`chraft-billing: usage report failed — ${String(err)}`);
    });
  });
}
