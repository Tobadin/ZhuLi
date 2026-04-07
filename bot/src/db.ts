// ZhuLi Bot — Supabase PostgREST Client (Schema zhuli.*)
import { config } from "./config.ts";

const REST = `${config.supabase.url}/rest/v1`;
const HEADERS = {
  "apikey": config.supabase.serviceKey,
  "Authorization": `Bearer ${config.supabase.serviceKey}`,
  "Content-Type": "application/json",
  "Accept-Profile": "zhuli",      // schema selector für GET
  "Content-Profile": "zhuli",     // schema selector für POST/PATCH/DELETE
};

type Json = Record<string, unknown>;

async function req(method: string, path: string, body?: Json | Json[], extra: Record<string,string> = {}): Promise<unknown> {
  const res = await fetch(`${REST}/${path}`, {
    method,
    headers: { ...HEADERS, ...extra },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const txt = await res.text();
    throw new Error(`[DB] ${method} ${path} → ${res.status}: ${txt}`);
  }
  if (res.status === 204) return null;
  return res.json();
}

export const db = {
  select: (table: string, query = ""): Promise<unknown[]> =>
    req("GET", `${table}${query}`) as Promise<unknown[]>,

  insert: (table: string, row: Json | Json[]): Promise<unknown> =>
    req("POST", table, row, { "Prefer": "return=representation" }),

  update: (table: string, query: string, patch: Json): Promise<unknown> =>
    req("PATCH", `${table}${query}`, patch, { "Prefer": "return=representation" }),

  delete: (table: string, query: string): Promise<unknown> =>
    req("DELETE", `${table}${query}`),

  /** Healthcheck — pingt das schema_migrations table */
  ping: async (): Promise<boolean> => {
    try {
      await req("GET", "schema_migrations?limit=1");
      return true;
    } catch (_e) {
      return false;
    }
  },
};
