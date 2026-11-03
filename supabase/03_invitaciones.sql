-- =====================================================================
-- Invitaciones: coordinación pre-aprueba correos con su empresa.
-- Quien ingresa con un correo invitado queda aprobado automáticamente.
-- Ejecutar en Supabase → SQL Editor (después de 01_esquema.sql).
-- =====================================================================

create table if not exists public.invitaciones (
  email   text primary key check (email = lower(email)),
  empresa text not null,
  creado  timestamptz not null default now()
);

alter table public.invitaciones enable row level security;
drop policy if exists "admin gestiona invitaciones" on public.invitaciones;
create policy "admin gestiona invitaciones" on public.invitaciones
  for all to authenticated using (public.es_admin()) with check (public.es_admin());

-- Al registrarse: si el correo estaba invitado, el perfil nace con su empresa
create or replace function public.crear_perfil() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.perfiles (id, email, empresa)
  values (new.id, new.email,
          (select empresa from public.invitaciones where email = lower(new.email)))
  on conflict (id) do nothing;
  return new;
end $$;

-- Al invitar a alguien que ya ingresó antes: se aprueba en ese momento
create or replace function public.aplicar_invitacion() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    update public.perfiles set empresa = null
     where lower(email) = old.email and empresa = old.empresa and not es_admin;
    return old;
  end if;
  update public.perfiles set empresa = new.empresa
   where lower(email) = new.email and not es_admin;
  return new;
end $$;

drop trigger if exists aplicar_invitacion on public.invitaciones;
create trigger aplicar_invitacion after insert or update or delete on public.invitaciones
  for each row execute function public.aplicar_invitacion();
