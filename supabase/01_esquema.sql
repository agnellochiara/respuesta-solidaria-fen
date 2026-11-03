-- =====================================================================
-- Respuesta Solidaria FEN · esquema de base de datos (Supabase)
-- Ejecutar completo en: Supabase → SQL Editor → New query → Run
-- =====================================================================

-- ---------- Perfiles: una fila por persona que inicia sesión ----------
create table if not exists public.perfiles (
  id                 uuid primary key references auth.users(id) on delete cascade,
  email              text,
  nombre             text,
  empresa_solicitada text,          -- lo que la persona pide
  empresa            text,          -- lo que coordinación aprueba (null = sin acceso de edición)
  es_admin           boolean not null default false,
  creado             timestamptz not null default now()
);

-- ---------- Iniciativas ----------
create table if not exists public.iniciativas (
  id                uuid primary key default gen_random_uuid(),
  empresa           text not null,
  nombre            text not null,
  descripcion       text,
  aliado            text,
  region            text,
  zona              text,
  tipo              text,
  beneficiarios     numeric check (beneficiarios is null or beneficiarios >= 0),
  monto             numeric check (monto is null or monto >= 0),
  cantidad          text,
  unidad            text,
  fecha_inicio      date,
  fecha_culminacion date,
  estado            text not null default 'Planificado'
                    check (estado in ('Planificado','En curso','Culminado','Suspendido')),
  responsable       text,
  comentarios       text,
  fotos             text[] not null default '{}',
  creado_por        uuid references auth.users(id) on delete set null,
  creado            timestamptz not null default now(),
  actualizado       timestamptz not null default now()
);

-- ---------- Funciones de ayuda (leen el perfil de quien llama) ----------
create or replace function public.es_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select es_admin from public.perfiles where id = auth.uid()), false)
$$;

create or replace function public.mi_empresa() returns text
language sql stable security definer set search_path = public as $$
  select empresa from public.perfiles where id = auth.uid()
$$;

-- ---------- Crear el perfil automáticamente al registrarse ----------
create or replace function public.crear_perfil() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.perfiles (id, email) values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists al_crear_usuario on auth.users;
create trigger al_crear_usuario after insert on auth.users
  for each row execute function public.crear_perfil();

-- ---------- Nadie puede auto-asignarse empresa ni admin ----------
create or replace function public.proteger_perfil() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not public.es_admin() then
    new.empresa  := old.empresa;
    new.es_admin := old.es_admin;
    new.email    := old.email;
  end if;
  return new;
end $$;

drop trigger if exists proteger_perfil on public.perfiles;
create trigger proteger_perfil before update on public.perfiles
  for each row execute function public.proteger_perfil();

-- ---------- Sellos de fecha y autor en iniciativas ----------
create or replace function public.sellar_iniciativa() returns trigger
language plpgsql as $$
begin
  new.actualizado := now();
  if tg_op = 'INSERT' then
    new.creado_por := auth.uid();
  else
    new.creado_por := old.creado_por;
    new.creado     := old.creado;
  end if;
  return new;
end $$;

drop trigger if exists sellar_iniciativa on public.iniciativas;
create trigger sellar_iniciativa before insert or update on public.iniciativas
  for each row execute function public.sellar_iniciativa();

-- ---------- Seguridad a nivel de fila ----------
alter table public.perfiles    enable row level security;
alter table public.iniciativas enable row level security;

drop policy if exists "perfil propio o admin"      on public.perfiles;
drop policy if exists "editar perfil propio o admin" on public.perfiles;
drop policy if exists "admin borra perfiles"       on public.perfiles;
create policy "perfil propio o admin" on public.perfiles
  for select to authenticated using (id = auth.uid() or public.es_admin());
create policy "editar perfil propio o admin" on public.perfiles
  for update to authenticated using (id = auth.uid() or public.es_admin())
  with check (id = auth.uid() or public.es_admin());
create policy "admin borra perfiles" on public.perfiles
  for delete to authenticated using (public.es_admin());

drop policy if exists "todos leen iniciativas"      on public.iniciativas;
drop policy if exists "empresa crea las suyas"      on public.iniciativas;
drop policy if exists "empresa edita las suyas"     on public.iniciativas;
drop policy if exists "empresa borra las suyas"     on public.iniciativas;
create policy "todos leen iniciativas" on public.iniciativas
  for select to anon, authenticated using (true);
create policy "empresa crea las suyas" on public.iniciativas
  for insert to authenticated
  with check (public.es_admin() or (public.mi_empresa() is not null and empresa = public.mi_empresa()));
create policy "empresa edita las suyas" on public.iniciativas
  for update to authenticated
  using      (public.es_admin() or (public.mi_empresa() is not null and empresa = public.mi_empresa()))
  with check (public.es_admin() or (public.mi_empresa() is not null and empresa = public.mi_empresa()));
create policy "empresa borra las suyas" on public.iniciativas
  for delete to authenticated
  using (public.es_admin() or (public.mi_empresa() is not null and empresa = public.mi_empresa()));

-- El público (sin sesión) no ve el nombre del responsable
revoke select on public.iniciativas from anon;
grant select (id, empresa, nombre, descripcion, aliado, region, zona, tipo, beneficiarios, monto,
              cantidad, unidad, fecha_inicio, fecha_culminacion, estado, comentarios, fotos, creado, actualizado)
  on public.iniciativas to anon;

-- ---------- Tiempo real ----------
do $$ begin
  alter publication supabase_realtime add table public.iniciativas;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.perfiles;
exception when duplicate_object then null; end $$;

-- ---------- Fotos (Storage) ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos', 'fotos', true, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

drop policy if exists "fotos: suben empresas aprobadas" on storage.objects;
drop policy if exists "fotos: borra quien subio o admin" on storage.objects;
create policy "fotos: suben empresas aprobadas" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'fotos' and (public.es_admin() or public.mi_empresa() is not null));
create policy "fotos: borra quien subio o admin" on storage.objects
  for delete to authenticated
  using (bucket_id = 'fotos' and (owner = auth.uid() or public.es_admin()));
