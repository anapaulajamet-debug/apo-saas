// api/creer-compte-client.js — Vercel Serverless Function
// Crée un compte Supabase Auth + profil users pour un client
// Appelé depuis fiche-client.html après validation du contrat

const SUPABASE_URL = 'https://zqehxwggzyepiftjrkxq.supabase.co';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
  if (!SERVICE_KEY) {
    return res.status(500).json({ error: 'Configuration serveur manquante' });
  }

  const { email, password, nom, prenom, site_id, tenant_id } = req.body;
  if (!email || !password || !site_id) {
    return res.status(400).json({ error: 'Paramètres manquants' });
  }

  // 1. Créer l'utilisateur dans Supabase Auth
  const authRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
    },
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      user_metadata: { nom, prenom, role: 'client' },
    }),
  });

  const authData = await authRes.json();
  if (!authRes.ok) {
    // Si l'utilisateur existe déjà, on continue
    if (!authData.msg?.includes('already')) {
      return res.status(400).json({ error: authData.msg || authData.message || 'Erreur création compte' });
    }
  }

  const userId = authData.id;
  if (!userId) {
    // Chercher l'utilisateur existant par email
    const listRes = await fetch(
      `${SUPABASE_URL}/auth/v1/admin/users?email=${encodeURIComponent(email)}`,
      {
        headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}` },
      }
    );
    const listData = await listRes.json();
    const existing = listData.users?.find(u => u.email === email);
    if (!existing) return res.status(400).json({ error: 'Impossible de créer ou trouver le compte' });

    // Mettre à jour le mot de passe
    await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${existing.id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        apikey: SERVICE_KEY,
        Authorization: `Bearer ${SERVICE_KEY}`,
      },
      body: JSON.stringify({ password }),
    });

    // Upsert dans users
    await fetch(`${SUPABASE_URL}/rest/v1/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: SERVICE_KEY,
        Authorization: `Bearer ${SERVICE_KEY}`,
        Prefer: 'resolution=merge-duplicates',
      },
      body: JSON.stringify({
        id: existing.id,
        email,
        nom: nom || '',
        prenom: prenom || '',
        role: 'client',
        site_id,
        tenant_id: tenant_id || 'aaaaaaaa-0000-0000-0000-000000000001',
      }),
    });

    return res.status(200).json({ success: true, user_id: existing.id, existing: true });
  }

  // 2. Insérer dans la table users
  await fetch(`${SUPABASE_URL}/rest/v1/users`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      Prefer: 'resolution=merge-duplicates',
    },
    body: JSON.stringify({
      id: userId,
      email,
      nom: nom || '',
      prenom: prenom || '',
      role: 'client',
      site_id,
      tenant_id: tenant_id || 'aaaaaaaa-0000-0000-0000-000000000001',
    }),
  });

  return res.status(200).json({ success: true, user_id: userId });
}
