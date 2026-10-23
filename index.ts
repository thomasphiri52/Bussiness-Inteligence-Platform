// Supabase Edge Function: v25-scheduled-report
// Invoke from a trusted scheduler only. Required server secrets:
// SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, RESEND_API_KEY, REPORT_FROM_EMAIL, V25_SCHEDULER_SECRET.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-scheduler-secret", "Access-Control-Allow-Methods": "POST, OPTIONS", "Content-Type": "application/json" };
const json = (b: unknown, s=200) => new Response(JSON.stringify(b), {status:s, headers:cors});
Deno.serve(async req => {
 if (req.method === "OPTIONS") return new Response("ok", {headers:cors});
 if (req.method !== "POST") return json({error:"Method not allowed"},405);
 const expected = Deno.env.get("V25_SCHEDULER_SECRET");
 if (!expected || req.headers.get("x-scheduler-secret") !== expected) return json({error:"Forbidden"},403);
 try {
  const url=Deno.env.get("SUPABASE_URL")!, key=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, resend=Deno.env.get("RESEND_API_KEY"), from=Deno.env.get("REPORT_FROM_EMAIL");
  if(!url||!key||!resend||!from) return json({error:"Required server secrets are missing"},500);
  const admin=createClient(url,key,{auth:{persistSession:false}});
  const now=new Date().toISOString();
  const {data:schedules,error}=await admin.from("report_schedules").select("id,owner_id,organisation_id,recipient_email,frequency").eq("enabled",true).lte("next_run_at",now).limit(50);
  if(error) throw error;
  const outcomes=[];
  for(const s of schedules??[]) {
   // Advance due time before sending to reduce duplicate sends if the scheduler overlaps.
   const next=new Date(); if(s.frequency==="daily")next.setUTCDate(next.getUTCDate()+1);else if(s.frequency==="weekly")next.setUTCDate(next.getUTCDate()+7);else next.setUTCMonth(next.getUTCMonth()+1);
   const {error:claimError}=await admin.from("report_schedules").update({next_run_at:next.toISOString(),last_run_at:now,last_status:"pending",last_error_code:null}).eq("id",s.id).lte("next_run_at",now);
   if(claimError){outcomes.push({id:s.id,status:"claim_failed"});continue;}
   try {
    const [pr,ta,mi]=await Promise.all([
     admin.from("projects").select("id,name,status,health,progress,due_date,created_at").eq("organisation_id",s.organisation_id).limit(500),
     admin.from("tasks").select("id,title,status,due_date,created_at").eq("organisation_id",s.organisation_id).limit(1000),
     admin.from("milestones").select("id,title,status,due_date,created_at").eq("organisation_id",s.organisation_id).limit(1000)
    ]);
    for(const r of [pr,ta,mi])if(r.error)throw r.error;
    const projects=pr.data??[],tasks=ta.data??[],milestones=mi.data??[];
    const today=new Date().toISOString().slice(0,10);
    const overdue=[...tasks,...milestones].filter(x=>x.due_date&&x.due_date<today&&!['done','completed','complete','approved'].includes(String(x.status??'').toLowerCase())).length;
    const avg=projects.length?Math.round(projects.reduce((a,x)=>a+Number(x.progress??0),0)/projects.length):0;
    const esc=(v:unknown)=>String(v??'').replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
    const html=`<div style="font-family:Arial,sans-serif;color:#172033;max-width:680px;margin:auto"><h1>Executive project summary</h1><p>Scheduled ${esc(s.frequency)} report · ${new Date().toISOString()}</p><ul><li>Projects: ${projects.length}</li><li>Average progress: ${avg}%</li><li>Tasks: ${tasks.length}</li><li>Milestones: ${milestones.length}</li><li>Overdue tasks and milestones: ${overdue}</li></ul><h2>Recent projects</h2><ul>${projects.slice(0,15).map(p=>`<li>${esc(p.name)} — ${esc(p.status)} — ${Number(p.progress??0)}%</li>`).join('')||'<li>No projects found</li>'}</ul><p>Sent to your own configured staff account. Review this report before sharing outside your organisation.</p></div>`;
    const resp=await fetch('https://api.resend.com/emails',{method:'POST',headers:{Authorization:`Bearer ${resend}`,'Content-Type':'application/json'},body:JSON.stringify({from,to:[s.recipient_email],subject:`${s.frequency[0].toUpperCase()+s.frequency.slice(1)} executive project report`,html})});
    const result=await resp.json(); if(!resp.ok)throw new Error(String(result?.name??'resend_failed'));
    await admin.from('report_schedules').update({last_status:'sent',last_error_code:null}).eq('id',s.id);outcomes.push({id:s.id,status:'sent'});
   } catch(e) { const code=String((e as Error)?.message??'send_failed').slice(0,80);await admin.from('report_schedules').update({last_status:'failed',last_error_code:code}).eq('id',s.id);outcomes.push({id:s.id,status:'failed'}); }
  }
  return json({ok:true,processed:outcomes.length,outcomes});
 } catch(e) { console.error('v25-scheduled-report failed',e);return json({error:'Scheduled report run failed; inspect function logs'},500); }
});
