import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

// Sources à scraper pour la grille propreté IDCC 3043
const SOURCES = [
  "https://www.lemondedelaproperete.com/convention-collective-proprete-salaires",
  "https://www.lemondedelaproperete.com/grille-salaires-proprete",
];

// Mapping des qualifications attendues dans la grille
const QUALIFICATION_PATTERNS: Record<string, RegExp[]> = {
  ASP1: [/asp\s*1|agent\s+de\s+service\s+propret[eé]\s+(?:niveau\s+)?1|asp\s+niveau\s+1/i],
  ASP2: [/asp\s*2|agent\s+de\s+service\s+propret[eé]\s+(?:niveau\s+)?2/i],
  ASP3: [/asp\s*3|agent\s+de\s+service\s+propret[eé]\s+(?:niveau\s+)?3/i],
  AQS1: [/aqs\s*1|agent\s+qualifi[eé]\s+de\s+service\s+(?:niveau\s+)?1/i],
  AQS2: [/aqs\s*2|agent\s+qualifi[eé]\s+de\s+service\s+(?:niveau\s+)?2/i],
  AQS3: [/aqs\s*3|agent\s+qualifi[eé]\s+de\s+service\s+(?:niveau\s+)?3/i],
  CE1:  [/ce\s*1|chef\s+d.?.quipe\s+(?:niveau\s+)?1/i],
  CE2:  [/ce\s*2|chef\s+d.?.quipe\s+(?:niveau\s+)?2/i],
  CE3:  [/ce\s*3|chef\s+d.?.quipe\s+(?:niveau\s+)?3/i],
  AM1:  [/am\s*1|agent\s+de\s+ma[îi]trise\s+(?:niveau\s+)?1/i],
  AM2:  [/am\s*2|agent\s+de\s+ma[îi]trise\s+(?:niveau\s+)?2/i],
};

// Extrait les taux horaires d'un texte HTML brut
function extraireTaux(html: string): Record<string, number> {
  const taux: Record<string, number> = {};
  const text = html.replace(/<[^>]+>/g, " ").replace(/&nbsp;/g, " ").replace(/\s+/g, " ");

  for (const [code, patterns] of Object.entries(QUALIFICATION_PATTERNS)) {
    for (const pattern of patterns) {
      const match = text.match(new RegExp(pattern.source + "[^0-9]{0,30}(\\d{1,2}[,.]\\d{2,4})", "i"));
      if (match) {
        const val = parseFloat(match[1].replace(",", "."));
        if (val >= 11 && val <= 35) { // garde-fou : taux plausibles €/h
          taux[code] = val;
          break;
        }
      }
    }
  }
  return taux;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const results: Record<string, unknown> = { scraped: {}, updated: [], errors: [] };

  // Tenter chaque source
  for (const url of SOURCES) {
    try {
      const res = await fetch(url, {
        headers: { "User-Agent": "Mozilla/5.0 (compatible; GrillePropreteBot/1.0)" },
        signal: AbortSignal.timeout(8000),
      });
      if (!res.ok) continue;
      const html = await res.text();
      const taux = extraireTaux(html);
      if (Object.keys(taux).length > 0) {
        Object.assign(results.scraped as object, taux);
      }
    } catch (e) {
      (results.errors as string[]).push(`${url}: ${(e as Error).message}`);
    }
  }

  // Mettre à jour Supabase pour chaque taux extrait
  const today = new Date().toISOString().slice(0, 10);
  for (const [code, tauxHoraire] of Object.entries(results.scraped as Record<string, number>)) {
    const resp = await fetch(`${SUPABASE_URL}/rest/v1/grille_convention_proprete?code_cc=eq.${code}`, {
      method: "PATCH",
      headers: {
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({ taux_horaire: tauxHoraire, date_maj: today }),
    });
    if (resp.ok) {
      (results.updated as string[]).push(`${code}: ${tauxHoraire} €/h`);
    }
  }

  // Si rien n'a pu être extrait, retourner la grille actuelle (pas d'erreur fatale)
  const { rows } = await fetch(`${SUPABASE_URL}/rest/v1/grille_convention_proprete?select=code_cc,taux_horaire,date_maj&order=coefficient`, {
    headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` },
  }).then(r => r.json()).then(data => ({ rows: data })).catch(() => ({ rows: [] }));

  return new Response(JSON.stringify({ ...results, grille_actuelle: rows }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
