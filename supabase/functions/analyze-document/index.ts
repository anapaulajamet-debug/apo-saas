import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const { url, document_id } = await req.json();

  // Télécharge le fichier
  const fileRes = await fetch(url);
  const buffer = await fileRes.arrayBuffer();
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  const base64 = btoa(binary);

  const isPDF = url.match(/\.pdf$/i);
  const mimeType = isPDF
    ? "application/pdf"
    : url.match(/\.png$/i) ? "image/png" : "image/jpeg";

  const prompt = `Analyse ce document professionnel. Réponds UNIQUEMENT en JSON valide avec ces champs :
{
  "type_detecte": "contrat|devis|email|bon_commande|facture|autre",
  "signature": true ou false (y a-t-il une signature visible ou mention de signature ?),
  "parties": ["Nom Société 1", "Nom Société 2"],
  "date_document": "JJ/MM/AAAA ou null",
  "montant": "montant détecté ou null",
  "resume": "1-2 phrases résumant le document"
}`;

  const contentItem = isPDF
    ? { type: "document", source: { type: "base64", media_type: mimeType, data: base64 } }
    : { type: "image", source: { type: "base64", media_type: mimeType, data: base64 } };

  const claudeRes = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": Deno.env.get("ANTHROPIC_API_KEY") ?? "",
      "anthropic-version": "2023-06-01",
      "anthropic-beta": "pdfs-2024-09-25",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5",
      max_tokens: 600,
      messages: [{ role: "user", content: [contentItem, { type: "text", text: prompt }] }],
    }),
  });

  const claudeData = await claudeRes.json();
  const text = claudeData.content?.[0]?.text ?? "{}";

  let analyse: Record<string, unknown> = {};
  try {
    const match = text.match(/\{[\s\S]*\}/);
    if (match) analyse = JSON.parse(match[0]);
  } catch {
    analyse = { resume: text };
  }

  // Sauvegarde en base
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

  await fetch(`${supabaseUrl}/rest/v1/site_documents?id=eq.${document_id}`, {
    method: "PATCH",
    headers: {
      apikey: supabaseKey,
      Authorization: `Bearer ${supabaseKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      analyse_ia: analyse,
      signature_detectee: analyse.signature === true,
    }),
  });

  return new Response(JSON.stringify(analyse), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
