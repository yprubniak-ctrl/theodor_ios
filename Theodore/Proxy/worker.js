/**
 * Theodore API Proxy — Cloudflare Worker
 *
 * Sits between the iOS app and the Claude API.
 * Keeps your API key off the device.
 *
 * Deploy:
 *   1. npm install -g wrangler
 *   2. wrangler login
 *   3. wrangler secret put ANTHROPIC_API_KEY   ← paste your key when prompted
 *   4. wrangler deploy
 *
 * The deployed URL goes into TheodoreService.swift → proxyURL
 */

const CLAUDE_API = "https://api.anthropic.com/v1/messages";
const ALLOWED_MODELS = ["claude-sonnet-4-6", "claude-haiku-4-5-20251001"];

// Chapter generation with 8 photos needs ~4k tokens of output.
// Conversation turns can stay lower at 2048.
const MAX_TOKENS_HARD_CAP = 4096;

// Per-user rate limiting (stored in Workers KV — optional but recommended)
const RATE_LIMIT_REQUESTS = 20;   // max requests
const RATE_LIMIT_WINDOW   = 3600; // per hour (seconds)

export default {
  async fetch(request, env) {
    // ── CORS ────────────────────────────────────────────────
    if (request.method === "OPTIONS") {
      return corsResponse();
    }

    if (request.method \!== "POST") {
      return errorResponse(405, "Method not allowed");
    }

    // ── Parse & validate body ────────────────────────────────
    let body;
    try {
      body = await request.json();
    } catch {
      return errorResponse(400, "Invalid JSON");
    }

    // Enforce allowed models — never let the client choose claude-opus
    if (\!ALLOWED_MODELS.includes(body.model)) {
      body.model = "claude-sonnet-4-6";
    }

    // Cap token usage — allow up to 4096 for chapter generation (vision requests)
    body.max_tokens = Math.min(body.max_tokens ?? 1024, MAX_TOKENS_HARD_CAP);

    // ── Rate limiting (requires KV binding named RATE_LIMITER) ──
    if (env.RATE_LIMITER) {
      const clientIP = request.headers.get("CF-Connecting-IP") ?? "unknown";
      const key = `rl:${clientIP}`;
      const current = parseInt(await env.RATE_LIMITER.get(key) ?? "0");

      if (current >= RATE_LIMIT_REQUESTS) {
        return errorResponse(429, "Rate limit exceeded. Theodore needs a moment.");
      }

      await env.RATE_LIMITER.put(key, String(current + 1), {
        expirationTtl: RATE_LIMIT_WINDOW
      });
    }

    // ── Forward to Claude API ────────────────────────────────
    const claudeResponse = await fetch(CLAUDE_API, {
      method: "POST",
      headers: {
        "Content-Type":      "application/json",
        "x-api-key":         env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify(body),
    });

    // ── Stream or return ─────────────────────────────────────
    if (body.stream) {
      // Pass the SSE stream straight through
      return new Response(claudeResponse.body, {
        status: claudeResponse.status,
        headers: {
          "Content-Type":                "text/event-stream",
          "Cache-Control":               "no-cache",
          "Access-Control-Allow-Origin": "*",
        },
      });
    } else {
      const data = await claudeResponse.json();
      return new Response(JSON.stringify(data), {
        status: claudeResponse.status,
        headers: {
          "Content-Type":                "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }
  },
};

// ── Helpers ───────────────────────────────────────────────────────

function corsResponse() {
  return new Response(null, {
    headers: {
      "Access-Control-Allow-Origin":  "*",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  });
}

function errorResponse(status, message) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: {
      "Content-Type":                "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
