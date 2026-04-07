// ZhuLi Bot — Config (liest aus Umgebung / .env)
const env = (k: string, def = ""): string => Deno.env.get(k) ?? def;

export const config = {
  telegram: {
    token: env("TELEGRAM_BOT_TOKEN"),
    userId: env("TELEGRAM_USER_ID"),
  },
  supabase: {
    url: env("SUPABASE_URL", "https://baas.tobiasseidl.de"),
    serviceKey: env("SUPABASE_SERVICE_ROLE_KEY"),
  },
  anthropic: {
    apiKey: env("ANTHROPIC_API_KEY"),
    defaultModel: "claude-sonnet-4-6",
  },
};

export const DATA_DIR = `${Deno.env.get("HOME")}/ZhuLi/data`;

export function assertConfig(): string[] {
  const missing: string[] = [];
  if (!config.telegram.token) missing.push("TELEGRAM_BOT_TOKEN");
  if (!config.supabase.serviceKey) missing.push("SUPABASE_SERVICE_ROLE_KEY");
  if (!config.anthropic.apiKey) missing.push("ANTHROPIC_API_KEY");
  return missing;
}
