-- =====================================================================
-- Empresas del grupo: lista administrada por coordinación desde el tablero.
-- Solo las empresas "activas" aparecen al crear iniciativas, solicitar
-- acceso o invitar responsables. Ejecutar una vez en SQL Editor.
-- =====================================================================

create table if not exists public.empresas (
  nombre text primary key check (length(trim(nombre)) > 0),
  activa boolean not null default true,
  creado timestamptz not null default now()
);

alter table public.empresas enable row level security;
drop policy if exists "todos leen empresas"     on public.empresas;
drop policy if exists "admin gestiona empresas" on public.empresas;
create policy "todos leen empresas" on public.empresas
  for select to anon, authenticated using (true);
create policy "admin gestiona empresas" on public.empresas
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

do $$ begin
  alter publication supabase_realtime add table public.empresas;
exception when duplicate_object then null; end $$;

-- Lista inicial (la del Excel). Luego se ajusta desde el tablero.
insert into public.empresas (nombre) values
  ('Interbank'),('Interseguro'),('Financiera Oh!'),('Inkafarma'),('Mifarma'),('Farmacias Peruanas'),
  ('Supermercados Peruanos'),('Plaza Vea'),('Vivanda'),('Promart'),('Oxxo'),('Real Plaza'),('NGR'),('Sip'),
  ('Inspira/Intercorp Retail'),('Universidad Tecnológica del Perú (UTP)'),('Innova Schools'),('Colegios Peruanos'),
  ('Peruplast'),('StoreCenter'),('Urbanova'),('Casa Andina'),('Intercorp Retail (Corporativo)'),('Intercorp Perú (Corporativo)')
on conflict (nombre) do nothing;
