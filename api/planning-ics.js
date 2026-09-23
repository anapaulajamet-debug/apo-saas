// api/planning-ics.js — Vercel Serverless Function
// URL : /api/planning-ics?agent_id=xxx&mois=2026-09   (mois optionnel, défaut = 12 prochains mois)
// Retourne un flux iCalendar (.ics) abonnable depuis Outlook, Google Calendar, Apple Calendar

const SUPABASE_URL  = 'https://zqehxwggzyepiftjrkxq.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxZWh4d2dnenllcGlmdGpya3hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyMzUzNzksImV4cCI6MjA5NzgxMTM3OX0.Kr5bQlcw4_8Qk3eOyEJLYn3kivnlKhsUNNVcoavIpbc';
const TENANT        = 'aaaaaaaa-0000-0000-0000-000000000001';

async function supabase(table, params) {
  const qs = new URLSearchParams(params).toString();
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${qs}`, {
    headers: {
      apikey: SUPABASE_ANON,
      Authorization: `Bearer ${SUPABASE_ANON}`,
      Accept: 'application/json',
    },
  });
  if (!res.ok) return [];
  return res.json();
}

function fmtICSDate(dateStr, heureStr) {
  // dateStr = "2026-09-15", heureStr = "06:30:00" ou "06:30"
  const [y, mo, dd] = dateStr.split('-');
  const [h, mi] = (heureStr || '08:00').slice(0, 5).split(':');
  return `${y}${mo}${dd}T${h.padStart(2,'0')}${mi.padStart(2,'0')}00`;
}

function addHours(heureStr, h) {
  const [hh, mm] = heureStr.slice(0, 5).split(':').map(Number);
  const total = hh * 60 + mm + h * 60;
  return `${String(Math.floor(total / 60) % 24).padStart(2,'0')}:${String(total % 60).padStart(2,'0')}`;
}

function escapeICS(str) {
  return (str || '').replace(/\\/g, '\\\\').replace(/;/g, '\\;').replace(/,/g, '\\,').replace(/\n/g, '\\n');
}

function uid(dateStr, agentId, i) {
  return `${dateStr}-${agentId}-${i}@cappolia-planning`;
}

function nowStamp() {
  return new Date().toISOString().replace(/[-:.]/g, '').slice(0, 15) + 'Z';
}

export default async function handler(req, res) {
  const { agent_id, mois } = req.query || {};

  if (!agent_id) {
    res.status(400).send('Paramètre agent_id requis');
    return;
  }

  // Période : mois précisé ou 6 mois glissants
  let debut, fin;
  if (mois && /^\d{4}-\d{2}$/.test(mois)) {
    const [y, mo] = mois.split('-').map(Number);
    debut = `${y}-${String(mo).padStart(2,'0')}-01`;
    const dernierJour = new Date(y, mo, 0).getDate();
    fin   = `${y}-${String(mo).padStart(2,'0')}-${dernierJour}`;
  } else {
    const now = new Date();
    const past = new Date(now); past.setMonth(past.getMonth() - 1);
    const future = new Date(now); future.setMonth(future.getMonth() + 6);
    debut = past.toISOString().slice(0, 10);
    fin   = future.toISOString().slice(0, 10);
  }

  // Récupération agent + planning + site principal
  const [agents, plans] = await Promise.all([
    supabase('agents', {
      select: 'id,nom,prenom,jours_travailles,heures_par_jour,volume_horaire,site_principal_id',
      id: `eq.${agent_id}`,
      tenant_id: `eq.${TENANT}`,
      limit: 1,
    }),
    supabase('planning', {
      select: 'date,heure_debut,heure_fin,site_id',
      agent_id: `eq.${agent_id}`,
      date: `gte.${debut}`,
      'date.lte': fin,
      order: 'date.asc',
    }),
  ]);

  const agent = agents[0];
  if (!agent) { res.status(404).send('Agent introuvable'); return; }

  const nomAgent = `${agent.prenom || ''} ${agent.nom || ''}`.trim();

  // Récupérer les noms des sites du planning
  const siteIds = [...new Set((plans || []).map(p => p.site_id).filter(Boolean))];
  let sitesMap = {};
  if (siteIds.length) {
    const sites = await supabase('sites', {
      select: 'id,nom,adresse',
      id: `in.(${siteIds.join(',')})`,
      tenant_id: `eq.${TENANT}`,
    });
    (sites || []).forEach(s => { sitesMap[s.id] = s; });
  }

  // Site principal comme fallback
  let sitePrincipalNom = '';
  if (agent.site_principal_id) {
    const sp = await supabase('sites', {
      select: 'nom',
      id: `eq.${agent.site_principal_id}`,
      limit: 1,
    });
    sitePrincipalNom = sp?.[0]?.nom || '';
  }

  // Jours travaillés depuis le contrat (pour génération si pas de planning saisi)
  const JOUR_MAP = { 'Lun':1,'Mar':2,'Mer':3,'Jeu':4,'Ven':5,'Sam':6,'Dim':0 };
  const joursRaw = Array.isArray(agent.jours_travailles)
    ? agent.jours_travailles
    : (agent.jours_travailles ? agent.jours_travailles.split(',') : []);
  const joursTravailles = joursRaw.map(s => JOUR_MAP[String(s).trim()]).filter(j => j !== undefined);
  const hContrat = agent.heures_par_jour
    ? parseFloat(agent.heures_par_jour)
    : (parseFloat(agent.volume_horaire) && joursTravailles.length
        ? parseFloat(agent.volume_horaire) / joursTravailles.length
        : 0);

  const stamp = nowStamp();
  let events = '';

  if ((plans || []).length > 0) {
    // --- Événements depuis le planning Supabase ---
    plans.forEach((p, i) => {
      const site = sitesMap[p.site_id];
      const siteNom  = site?.nom  || sitePrincipalNom || 'Chantier';
      const siteAddr = site?.adresse || '';
      const heureDebut = p.heure_debut || '08:00:00';
      const heureFin   = p.heure_fin   || addHours(heureDebut, hContrat || 1);
      const dtStart = fmtICSDate(p.date, heureDebut);
      const dtEnd   = fmtICSDate(p.date, heureFin);
      events += [
        'BEGIN:VEVENT',
        `UID:${uid(p.date, agent_id, i)}`,
        `DTSTAMP:${stamp}`,
        `DTSTART;TZID=Europe/Paris:${dtStart}`,
        `DTEND;TZID=Europe/Paris:${dtEnd}`,
        `SUMMARY:${escapeICS(nomAgent)} — ${escapeICS(siteNom)}`,
        siteAddr ? `LOCATION:${escapeICS(siteAddr)}` : '',
        `DESCRIPTION:Planning CAPPOLIA — ${escapeICS(siteNom)}`,
        `CATEGORIES:CAPPOLIA,Planning`,
        'STATUS:CONFIRMED',
        'TRANSP:OPAQUE',
        'END:VEVENT',
      ].filter(Boolean).join('\r\n') + '\r\n';
    });
  } else if (joursTravailles.length) {
    // --- Génération depuis le contrat (jours × hContrat) ---
    const heureDebut = '08:00';
    const heureFin   = hContrat ? addHours(heureDebut, hContrat) : '12:00';
    const current = new Date(debut + 'T00:00:00');
    const end     = new Date(fin   + 'T23:59:59');
    let i = 0;
    while (current <= end) {
      const jourSem = current.getDay();
      if (joursTravailles.includes(jourSem)) {
        const dateStr = current.toISOString().slice(0, 10);
        events += [
          'BEGIN:VEVENT',
          `UID:${uid(dateStr, agent_id, i++)}`,
          `DTSTAMP:${stamp}`,
          `DTSTART;TZID=Europe/Paris:${fmtICSDate(dateStr, heureDebut)}`,
          `DTEND;TZID=Europe/Paris:${fmtICSDate(dateStr, heureFin)}`,
          `SUMMARY:${escapeICS(nomAgent)}${sitePrincipalNom ? ' — ' + escapeICS(sitePrincipalNom) : ''}`,
          sitePrincipalNom ? `DESCRIPTION:Planning contrat — ${escapeICS(sitePrincipalNom)}` : 'DESCRIPTION:Planning contrat CAPPOLIA',
          `CATEGORIES:CAPPOLIA,Planning`,
          'STATUS:CONFIRMED',
          'TRANSP:OPAQUE',
          'END:VEVENT',
        ].join('\r\n') + '\r\n';
      }
      current.setDate(current.getDate() + 1);
    }
  }

  const ical = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//CAPPOLIA//Planning Agent//FR',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    `X-WR-CALNAME:Planning ${escapeICS(nomAgent)}`,
    'X-WR-TIMEZONE:Europe/Paris',
    'X-WR-CALDESC:Planning CAPPOLIA - synchronisation automatique',
    'REFRESH-INTERVAL;VALUE=DURATION:PT1H',
    'X-PUBLISHED-TTL:PT1H',
    'BEGIN:VTIMEZONE',
    'TZID:Europe/Paris',
    'BEGIN:STANDARD',
    'TZOFFSETFROM:+0200',
    'TZOFFSETTO:+0100',
    'TZNAME:CET',
    'DTSTART:19701025T030000',
    'RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10',
    'END:STANDARD',
    'BEGIN:DAYLIGHT',
    'TZOFFSETFROM:+0100',
    'TZOFFSETTO:+0200',
    'TZNAME:CEST',
    'DTSTART:19700329T020000',
    'RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=3',
    'END:DAYLIGHT',
    'END:VTIMEZONE',
    events.trim(),
    'END:VCALENDAR',
  ].join('\r\n');

  res.setHeader('Content-Type', 'text/calendar; charset=utf-8');
  res.setHeader('Content-Disposition', `attachment; filename="planning_${agent_id}.ics"`);
  res.setHeader('Cache-Control', 'public, max-age=3600');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.status(200).send(ical);
}
