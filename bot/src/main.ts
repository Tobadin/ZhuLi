// ZhuLi Bot — Entry Point
// Long-Polling-Loop, Session-Cleanup, Healthcheck
import { config, assertConfig } from "./config.ts";
import { tg, type TgUpdate } from "./telegram.ts";
import { db } from "./db.ts";
import { sessions } from "./sessions.ts";

async function main() {
  console.log("[ZhuLi] starting …");

  const missing = assertConfig();
  if (missing.length) {
    console.error(`[ZhuLi] Fehlende env vars: ${missing.join(", ")}`);
    console.error("[ZhuLi] Lege ~/ZhuLi/.env an (siehe .env.example)");
    Deno.exit(1);
  }

  // Healthcheck DB
  const dbOk = await db.ping().catch(() => false);
  if (!dbOk) {
    console.error("[ZhuLi] DB-Healthcheck fehlgeschlagen — läuft die Migration?");
    Deno.exit(1);
  }
  console.log("[ZhuLi] DB OK");

  // Healthcheck Telegram
  const me = await tg.whoami();
  console.log(`[ZhuLi] Telegram OK: @${me.username} (${me.id})`);

  console.log("[ZhuLi] ready — polling …");

  let offset = 0;
  let cleanupCounter = 0;

  while (true) {
    try {
      const updates = await tg.poll(offset);
      for (const u of updates) {
        offset = u.update_id + 1;
        await handleUpdate(u).catch((e) => console.error("[ZhuLi] handleUpdate:", e));
      }

      // Session-Cleanup alle ~60 Iterationen
      if (++cleanupCounter > 60) {
        cleanupCounter = 0;
        await sessions.cleanup().catch(() => {});
      }
    } catch (e) {
      console.error("[ZhuLi] poll error:", e);
      await new Promise((r) => setTimeout(r, 5000));
    }
  }
}

async function handleUpdate(u: TgUpdate): Promise<void> {
  // Authorization: nur erlaubter User
  const userId = u.message?.from?.id ?? u.callback_query?.from.id;
  if (!userId) return;

  const allowed = config.telegram.userId;
  if (allowed && String(userId) !== allowed) {
    console.log(`[ZhuLi] ignoring update from ${userId} (not authorized)`);
    return;
  }

  if (u.message?.text) {
    await handleMessage(u);
  } else if (u.callback_query) {
    await handleCallback(u);
  }
}

async function handleMessage(u: TgUpdate): Promise<void> {
  const msg = u.message!;
  const chatId = msg.chat.id;
  const text = msg.text!.trim();

  // Bot-Commands
  if (text === "/start" || text === "/help") {
    await tg.send(chatId, [
      "<b>ZhuLi</b> — deine persönliche AI-Assistenz 🤖",
      "",
      "Status: <i>in Aufbau</i>",
      "",
      "Verfügbare Commands (Phase 1):",
      "• /start — diese Hilfe",
      "• /ping — Healthcheck",
      "",
      "Mehr Features kommen in Phase 2.",
    ].join("\n"));
    return;
  }

  if (text === "/ping") {
    const dbOk = await db.ping();
    await tg.send(chatId, `🏓 pong\nDB: ${dbOk ? "✅" : "❌"}`);
    return;
  }

  // Default
  await tg.send(chatId, "Hi 👋 — ZhuLi ist noch in Phase 1. Versuche /help");
}

async function handleCallback(u: TgUpdate): Promise<void> {
  const cb = u.callback_query!;
  await tg.answerCallback(cb.id);
  // TODO Phase 2: Button-Handler
}

main().catch((e) => {
  console.error("[ZhuLi] fatal:", e);
  Deno.exit(1);
});
