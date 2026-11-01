import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { agent_id, redirect_url } = await req.json()
    if (!agent_id) return new Response(JSON.stringify({ error: 'agent_id manquant' }), { status: 400, headers: corsHeaders })

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { data: agent, error: agentErr } = await supabase
      .from('agents')
      .select('email, prenom, nom')
      .eq('id', agent_id)
      .single()

    if (agentErr || !agent?.email) {
      return new Response(JSON.stringify({ error: 'Email du collaborateur manquant' }), { status: 400, headers: corsHeaders })
    }

    const { error } = await supabase.auth.admin.inviteUserByEmail(agent.email, {
      data: { role: 'agent', agent_id, prenom: agent.prenom, nom: agent.nom },
      redirectTo: redirect_url || 'https://apo-saas.vercel.app/clients/cappolia/pointage.html',
    })

    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: corsHeaders })

    return new Response(JSON.stringify({ success: true, email: agent.email }), { headers: corsHeaders })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500, headers: corsHeaders })
  }
})
