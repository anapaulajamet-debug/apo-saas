import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });

  try {
    const { to, subject, html, prospect } = await req.json();

    if (!to || !html) {
      return new Response(JSON.stringify({ error: 'Champs manquants: to, html' }), {
        status: 400, headers: { ...CORS, 'Content-Type': 'application/json' },
      });
    }

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Cappolia Propreté <o.jamet@cappolia-proprete.fr>',
        to: [to],
        subject: subject || `Devis Cappolia${prospect ? ' — ' + prospect : ''}`,
        html,
      }),
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.message || 'Erreur Resend');

    return new Response(JSON.stringify({ ok: true, id: data.id }), {
      headers: { ...CORS, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500, headers: { ...CORS, 'Content-Type': 'application/json' },
    });
  }
});
