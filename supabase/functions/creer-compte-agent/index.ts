import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL      = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function genererMotDePasse(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#";
  let pwd = "";
  const arr = new Uint8Array(12);
  crypto.getRandomValues(arr);
  for (const v of arr) pwd += chars[v % chars.length];
  return pwd;
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const { agent_id } = await req.json();
  if (!agent_id) {
    return new Response(JSON.stringify({ error: "agent_id manquant" }), {
      headers: { ...cors, "Content-Type": "application/json" }, status: 400,
    });
  }

  const sb = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Récupérer l'agent
  const { data: agent, error: errAgent } = await sb
    .from("agents")
    .select("id, nom, prenom, email, compte_cree, demande_affiliation")
    .eq("id", agent_id)
    .single();

  if (errAgent || !agent) {
    return new Response(JSON.stringify({ error: "Agent introuvable" }), {
      headers: { ...cors, "Content-Type": "application/json" }, status: 404,
    });
  }

  if (!agent.email) {
    return new Response(JSON.stringify({ error: "L'agent n'a pas d'adresse email — ajoutez-la avant de créer le compte." }), {
      headers: { ...cors, "Content-Type": "application/json" }, status: 400,
    });
  }

  if (agent.compte_cree) {
    return new Response(JSON.stringify({ error: "Un compte existe déjà pour cet agent." }), {
      headers: { ...cors, "Content-Type": "application/json" }, status: 409,
    });
  }

  const motDePasse = genererMotDePasse();

  // Créer le compte Supabase Auth
  const { data: authData, error: errAuth } = await sb.auth.admin.createUser({
    email: agent.email,
    password: motDePasse,
    email_confirm: true,
    user_metadata: {
      role: "agent",
      agent_id: agent.id,
      nom: agent.nom,
      prenom: agent.prenom,
      demande_affiliation: agent.demande_affiliation ?? false,
    },
  });

  if (errAuth) {
    return new Response(JSON.stringify({ error: "Création Auth échouée : " + errAuth.message }), {
      headers: { ...cors, "Content-Type": "application/json" }, status: 500,
    });
  }

  // Mettre à jour l'agent
  await sb.from("agents").update({
    compte_cree:   true,
    contrat_signe: true,
    auth_user_id:  authData.user.id,
  }).eq("id", agent_id);

  return new Response(JSON.stringify({
    ok: true,
    email:      agent.email,
    mot_de_passe: motDePasse,
    nom:        agent.nom,
    prenom:     agent.prenom,
  }), { headers: { ...cors, "Content-Type": "application/json" } });
});
