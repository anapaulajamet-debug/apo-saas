import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const RESEND_KEY   = Deno.env.get("RESEND_API_KEY") ?? "";
const DIRECTEUR_EMAIL = "o.jamet@cappolia-proprete.fr";
const TENANT_ID = "aaaaaaaa-0000-0000-0000-000000000001";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function fetchParams() {
  const r = await fetch(
    `${SUPABASE_URL}/rest/v1/parametres_cappolia?tenant_id=eq.${TENANT_ID}&select=*&limit=1`,
    { headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` } }
  );
  const rows = await r.json();
  return rows[0] ?? null;
}

async function updateParams(patch: Record<string, unknown>) {
  await fetch(
    `${SUPABASE_URL}/rest/v1/parametres_cappolia?tenant_id=eq.${TENANT_ID}`,
    {
      method: "PATCH",
      headers: {
        apikey: SUPABASE_KEY,
        Authorization: `Bearer ${SUPABASE_KEY}`,
        "Content-Type": "application/json",
        Prefer: "return=minimal",
      },
      body: JSON.stringify({ ...patch, updated_at: new Date().toISOString() }),
    }
  );
}

async function envoyerEmail(sujet: string, corps: string) {
  if (!RESEND_KEY) {
    console.warn("RESEND_API_KEY non configurée — email non envoyé");
    return false;
  }
  const r = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${RESEND_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: "CAPPOLIA Propreté <noreply@cappolia-proprete.fr>",
      to: [DIRECTEUR_EMAIL],
      subject: sujet,
      html: corps,
    }),
  });
  return r.ok;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const params = await fetchParams();
  if (!params) {
    return new Response(JSON.stringify({ error: "Paramètres introuvables" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 404,
    });
  }

  const echeance = new Date(params.assurance_echeance);
  const aujourd_hui = new Date();
  aujourd_hui.setHours(0, 0, 0, 0);
  const joursRestants = Math.ceil((echeance.getTime() - aujourd_hui.getTime()) / 86_400_000);
  const echeanceFr = echeance.toLocaleDateString("fr-FR", { day: "2-digit", month: "long", year: "numeric" });

  const alertes: string[] = [];

  // Alerte 60 jours
  if (joursRestants <= 60 && joursRestants > 0 && !params.assurance_alerte_60j) {
    const ok = await envoyerEmail(
      `⚠️ Assurance RC Pro — échéance dans ${joursRestants} jours (${echeanceFr})`,
      `<p>Bonjour Olivier,</p>
       <p>L'attestation d'assurance RC Professionnelle de <strong>Cappolia Propreté</strong>
       (MATMUT — N° ${params.assurance_num_contrat}) arrive à échéance le <strong>${echeanceFr}</strong>,
       soit dans <strong>${joursRestants} jours</strong>.</p>
       <p>Merci de contacter votre conseiller MATMUT (Félix Hemery — 02 35 00 50 50)
       pour renouveler votre contrat et mettre à jour l'attestation dans l'application.</p>
       <p style="margin-top:24px;color:#888;font-size:12px;">Message automatique — Cappolia SaaS</p>`
    );
    if (ok) await updateParams({ assurance_alerte_60j: true });
    alertes.push(`60j: email ${ok ? "envoyé" : "échec (RESEND non configuré)"}`);
  }

  // Alerte 30 jours
  if (joursRestants <= 30 && joursRestants > 0 && !params.assurance_alerte_30j) {
    const ok = await envoyerEmail(
      `🚨 URGENT — Assurance RC Pro expire dans ${joursRestants} jours (${echeanceFr})`,
      `<p>Bonjour Olivier,</p>
       <p><strong>URGENT :</strong> L'attestation d'assurance RC Professionnelle de <strong>Cappolia Propreté</strong>
       expire le <strong>${echeanceFr}</strong>, soit dans seulement <strong>${joursRestants} jours</strong>.</p>
       <p>Sans attestation valide, vos contrats clients pourraient être remis en cause.
       Contactez immédiatement votre conseiller MATMUT :</p>
       <p><strong>Félix Hemery — 02 35 00 50 50 — pro@matmut.fr</strong></p>
       <p style="margin-top:24px;color:#888;font-size:12px;">Message automatique — Cappolia SaaS</p>`
    );
    if (ok) await updateParams({ assurance_alerte_30j: true });
    alertes.push(`30j: email ${ok ? "envoyé" : "échec (RESEND non configuré)"}`);
  }

  // Remise à zéro des flags si la date a été renouvelée (écheance future > 60j)
  if (joursRestants > 60 && (params.assurance_alerte_60j || params.assurance_alerte_30j)) {
    await updateParams({ assurance_alerte_60j: false, assurance_alerte_30j: false });
    alertes.push("Flags réinitialisés — nouvelle échéance détectée");
  }

  return new Response(JSON.stringify({
    echeance: params.assurance_echeance,
    joursRestants,
    alertes,
    status: joursRestants <= 0 ? "EXPIRÉE" : joursRestants <= 30 ? "CRITIQUE" : joursRestants <= 60 ? "ALERTE" : "OK",
  }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
});
