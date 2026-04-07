// ZhuLi Bot — Session-State in zhuli.sessions persistiert
import { db } from "./db.ts";

export interface Session {
  id: string;
  user_id: number;
  flow: string;
  step: string;
  state: Record<string, unknown>;
  expires_at: string;
  created_at: string;
  updated_at: string;
}

export const sessions = {
  /** Hole offene Session eines Users (oder null) */
  async get(userId: number): Promise<Session | null> {
    const rows = await db.select(
      "sessions",
      `?user_id=eq.${userId}&expires_at=gt.${new Date().toISOString()}&order=created_at.desc&limit=1`,
    ) as Session[];
    return rows[0] ?? null;
  },

  /** Starte einen neuen Flow (alte Sessions des Users werden gelöscht) */
  async start(userId: number, flow: string, step = "start", state: Record<string, unknown> = {}): Promise<Session> {
    await db.delete("sessions", `?user_id=eq.${userId}`);
    const rows = await db.insert("sessions", {
      user_id: userId, flow, step, state,
    }) as Session[];
    return rows[0];
  },

  /** Update Session — neuer Step + state-Merge */
  async update(sessionId: string, step: string, statePatch: Record<string, unknown> = {}): Promise<Session> {
    const cur = await db.select("sessions", `?id=eq.${sessionId}&limit=1`) as Session[];
    if (!cur[0]) throw new Error(`Session ${sessionId} nicht gefunden`);
    const newState = { ...cur[0].state, ...statePatch };
    const rows = await db.update("sessions", `?id=eq.${sessionId}`, {
      step, state: newState,
    }) as Session[];
    return rows[0];
  },

  /** Beendet eine Session (löscht sie) */
  async end(sessionId: string): Promise<void> {
    await db.delete("sessions", `?id=eq.${sessionId}`);
  },

  /** Aufräumen: alte Sessions entfernen */
  async cleanup(): Promise<void> {
    await db.delete("sessions", `?expires_at=lt.${new Date().toISOString()}`);
  },
};
