-- =====================================================================
-- Textos del tablero (título, descripción, etc.), editables por
-- coordinación desde el panel. Ejecutar una vez en SQL Editor.
-- =====================================================================

create table if not exists public.configuracion (
  clave       text primary key,
  valor       text not null default '',
  actualizado timestamptz not null default now()
);

alter table public.configuracion enable row level security;
drop policy if exists "todos leen configuracion"     on public.configuracion;
drop policy if exists "admin gestiona configuracion" on public.configuracion;
create policy "todos leen configuracion" on public.configuracion
  for select to anon, authenticated using (true);
create policy "admin gestiona configuracion" on public.configuracion
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

do $$ begin
  alter publication supabase_realtime add table public.configuracion;
exception when duplicate_object then null; end $$;

insert into public.configuracion (clave, valor) values
  ('linea_superior', 'Grupo Intercorp · Fenómeno El Niño 2026–27'),
  ('titulo',         'Respuesta Solidaria FEN'),
  ('descripcion',    'Aportes de las empresas del grupo a la respuesta humanitaria, actualizados por cada empresa.'),
  ('nota_fuente',    'Fuente: reportes de avance de cada empresa (base inicial importada del Excel “Avances Respuesta Solidaria FEN – Intercorp”, 2 nov 2026). Valorizado = monto invertido o valor de lo donado en soles. Beneficiarios = beneficiarios directos reportados.')
on conflict (clave) do nothing;
