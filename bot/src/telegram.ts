// ZhuLi Bot — Telegram-API-Wrapper (Long-Polling)
import { config } from "./config.ts";

const API = `https://api.telegram.org/bot${config.telegram.token}`;

export interface TgUpdate {
  update_id: number;
  message?: {
    message_id: number;
    from?: { id: number; username?: string; first_name?: string };
    chat: { id: number };
    text?: string;
    date: number;
  };
  callback_query?: {
    id: string;
    from: { id: number };
    message?: { message_id: number; chat: { id: number } };
    data?: string;
  };
}

export interface InlineButton { text: string; callback_data: string }

async function call(method: string, body: Record<string, unknown>): Promise<unknown> {
  const res = await fetch(`${API}/${method}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!data.ok) throw new Error(`[TG] ${method}: ${JSON.stringify(data)}`);
  return data.result;
}

export const tg = {
  send: (chatId: number, text: string, opts: Record<string, unknown> = {}): Promise<unknown> =>
    call("sendMessage", { chat_id: chatId, text, parse_mode: "HTML", ...opts }),

  sendButtons: (chatId: number, text: string, buttons: InlineButton[][]): Promise<unknown> =>
    call("sendMessage", {
      chat_id: chatId,
      text,
      parse_mode: "HTML",
      reply_markup: { inline_keyboard: buttons },
    }),

  answerCallback: (callbackId: string, text = ""): Promise<unknown> =>
    call("answerCallbackQuery", { callback_query_id: callbackId, text }),

  editMessage: (chatId: number, messageId: number, text: string): Promise<unknown> =>
    call("editMessageText", { chat_id: chatId, message_id: messageId, text, parse_mode: "HTML" }),

  /** Long-Polling: holt Updates ab letztem Offset, blockiert bis zu 30s. */
  async poll(offset: number): Promise<TgUpdate[]> {
    const res = await fetch(`${API}/getUpdates?offset=${offset}&timeout=30`);
    const data = await res.json();
    if (!data.ok) throw new Error(`[TG] poll: ${JSON.stringify(data)}`);
    return data.result as TgUpdate[];
  },

  /** Verifiziert: wir kommen an die API ran und der Token ist gültig. */
  async whoami(): Promise<{ username: string; id: number }> {
    const me = await call("getMe", {}) as { username: string; id: number };
    return me;
  },
};
