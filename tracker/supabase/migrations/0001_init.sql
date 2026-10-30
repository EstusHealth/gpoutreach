-- Driving OT Tracker schema (Supabase project xlxqukjktwkcpyjghwqs, ap-southeast-2)
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table private.app_owners (email text primary key);

create or replace function private.is_owner()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from private.app_owners o
    where lower(o.email) = lower(coalesce((select auth.jwt() ->> 'email'), '')));
$$;
revoke all on function private.is_owner() from public, anon;
grant execute on function private.is_owner() to authenticated;

create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;

create table public.gp_practices (
  id uuid primary key default gen_random_uuid(),
  name text not null, suburb text, address text, phone text, email text, fax text, practice_manager text,
  status text not null default 'cold' check (status in ('cold','contacted','engaged','lunch_booked','lunch_done','referring','dormant')),
  next_action text, next_action_date date, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table public.gps (
  id uuid primary key default gen_random_uuid(),
  practice_id uuid references public.gp_practices(id) on delete set null,
  name text not null, email text, phone text,
  interest text not null default 'unknown' check (interest in ('unknown','low','medium','high','champion')),
  notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index on public.gps(practice_id);

create table public.leads (
  id uuid primary key default gen_random_uuid(),
  first_name text not null, last_name text, phone text, email text, suburb text,
  age int check (age is null or age between 10 and 110),
  contact_person text,
  service text not null default 'unsure' check (service in ('medical_fitness','potential_to_drive','lessons','unsure')),
  funding text not null default 'unknown' check (funding in ('ndis_self','ndis_plan','private','other','unknown')),
  source text not null default 'other' check (source in ('gp','support_coordinator','self','family','website','social','other_ot','other')),
  referring_practice_id uuid references public.gp_practices(id) on delete set null,
  referring_gp_id uuid references public.gps(id) on delete set null,
  stage text not null default 'new' check (stage in ('new','contacted','quoted','booked','assessed','report_sent','won','lost','nurture')),
  value numeric(10,2), next_action text, next_action_date date, assessment_date date,
  gp_report_status text not null default 'not_needed' check (gp_report_status in ('not_needed','pending','sent','acknowledged','chased')),
  gp_report_sent_on date, gp_followup_due date, lost_reason text, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index on public.leads(referring_practice_id);
create index on public.leads(referring_gp_id);
create index on public.leads(stage);

create table public.touchpoints (
  id uuid primary key default gen_random_uuid(),
  happened_on date not null default current_date,
  kind text not null default 'call' check (kind in ('call','email','sms','visit','lunch_learn','fax','letter','meeting','other')),
  summary text not null,
  lead_id uuid references public.leads(id) on delete cascade,
  practice_id uuid references public.gp_practices(id) on delete cascade,
  gp_id uuid references public.gps(id) on delete set null,
  created_at timestamptz not null default now()
);
create index on public.touchpoints(lead_id);
create index on public.touchpoints(practice_id);
create index on public.touchpoints(gp_id);

create trigger t_practices before update on public.gp_practices for each row execute function public.touch_updated_at();
create trigger t_gps before update on public.gps for each row execute function public.touch_updated_at();
create trigger t_leads before update on public.leads for each row execute function public.touch_updated_at();

alter table public.gp_practices enable row level security;
alter table public.gps enable row level security;
alter table public.leads enable row level security;
alter table public.touchpoints enable row level security;

create policy owner_all on public.gp_practices for all to authenticated using ((select private.is_owner())) with check ((select private.is_owner()));
create policy owner_all on public.gps for all to authenticated using ((select private.is_owner())) with check ((select private.is_owner()));
create policy owner_all on public.leads for all to authenticated using ((select private.is_owner())) with check ((select private.is_owner()));
create policy owner_all on public.touchpoints for all to authenticated using ((select private.is_owner())) with check ((select private.is_owner()));

revoke all on public.gp_practices, public.gps, public.leads, public.touchpoints from anon;
