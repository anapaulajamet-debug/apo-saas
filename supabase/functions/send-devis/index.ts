import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });

  try {
    const { to, subject, commercial, messageHtml, devisNum, client, pdfBase64, fileName } = await req.json();

    if (!to || !pdfBase64) {
      return new Response(JSON.stringify({ error: 'Champs manquants: to, pdfBase64' }), {
        status: 400, headers: { ...CORS, 'Content-Type': 'application/json' },
      });
    }

    const signataire = commercial || 'Olivier Jamet';
    const corps = messageHtml || `Madame, Monsieur,<br><br>Veuillez trouver ci-joint notre proposition commerciale.`;

    const html = `<!DOCTYPE html>
<html lang="fr">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#F3F4F6;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F3F4F6;padding:40px 0;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.08);">
        <!-- EN-TÊTE -->
        <tr>
          <td style="background:#1A3D28;padding:28px 36px;">
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td>
                  <div style="color:#ffffff;font-size:20px;font-weight:800;letter-spacing:1px;">CAPPOLIA PROPRETÉ</div>
                  <div style="color:#86EFAC;font-size:12px;margin-top:4px;">Humaine · Sociale · Écologique</div>
                </td>
                <td align="right">
                  <div style="color:#ffffff;font-size:12px;opacity:.8;">${devisNum || ''}</div>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <!-- CORPS -->
        <tr>
          <td style="padding:36px 36px 28px;">
            <p style="color:#1F2937;font-size:15px;line-height:1.7;margin:0 0 24px;">${corps}</p>
            <!-- ENCART DEVIS -->
            <table width="100%" cellpadding="0" cellspacing="0" style="background:#F0FDF4;border:1.5px solid #86EFAC;border-radius:8px;margin-bottom:28px;">
              <tr>
                <td style="padding:18px 22px;">
                  <div style="font-size:12px;font-weight:700;color:#059669;text-transform:uppercase;letter-spacing:1px;margin-bottom:6px;">📎 Document joint</div>
                  <div style="font-size:15px;font-weight:800;color:#1A3D28;">${subject || 'Devis Cappolia Propreté'}</div>
                  ${client ? `<div style="font-size:13px;color:#6B7280;margin-top:4px;">Client : ${client}</div>` : ''}
                  <div style="font-size:12px;color:#9CA3AF;margin-top:6px;">Format PDF · Valable 30 jours</div>
                </td>
              </tr>
            </table>
            <p style="color:#1F2937;font-size:14px;line-height:1.7;margin:0;">Nous restons à votre entière disposition pour toute question ou pour convenir d'un rendez-vous.</p>
          </td>
        </tr>
        <!-- SIGNATURE -->
        <tr>
          <td style="padding:0 36px 36px;">
            <table width="100%" cellpadding="0" cellspacing="0" style="border-top:1px solid #E5E7EB;padding-top:24px;">
              <tr>
                <td>
                  <div style="font-size:14px;font-weight:700;color:#1A3D28;">${signataire}</div>
                  <div style="font-size:12px;color:#6B7280;margin-top:2px;">Cappolia Propreté</div>
                  <div style="font-size:12px;color:#6B7280;">o.jamet@cappolia-proprete.fr</div>
                </td>
                <td align="right">
                  <div style="font-size:11px;color:#9CA3AF;">Allauch (13190) — Bouches-du-Rhône</div>
                  <div style="font-size:11px;color:#9CA3AF;margin-top:2px;">o.jamet@cappolia-proprete.fr</div>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <!-- PIED -->
        <tr>
          <td style="background:#F9FAFB;padding:16px 36px;border-top:1px solid #E5E7EB;">
            <p style="margin:0;font-size:11px;color:#9CA3AF;text-align:center;">Ce message et ses pièces jointes sont confidentiels. Si vous n'êtes pas le destinataire prévu, merci de le signaler à l'expéditeur.</p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;

    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: `${signataire} <o.jamet@cappolia-proprete.fr>`,
        to: [to],
        subject: subject || 'Devis Cappolia Propreté',
        html,
        attachments: [{
          filename: fileName || 'devis-cappolia.pdf',
          content: pdfBase64,
        }],
      }),
    });

    const data = await res.json();
    if (!res.ok) throw new Error(data.message || JSON.stringify(data));

    return new Response(JSON.stringify({ ok: true, id: data.id }), {
      headers: { ...CORS, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500, headers: { ...CORS, 'Content-Type': 'application/json' },
    });
  }
});
