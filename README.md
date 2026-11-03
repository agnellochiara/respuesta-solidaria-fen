# Respuesta Solidaria FEN · Grupo Intercorp

Tablero de los aportes de las empresas del Grupo Intercorp a la respuesta humanitaria frente al Fenómeno El Niño 2026–27.

- **Cualquiera con el enlace** ve el tablero completo (cifras, mapa, filtros, fotos) sin crear cuenta.
- **Responsables de cada empresa** ingresan con su correo (enlace mágico, sin contraseña), solicitan acceso y, una vez aprobados por coordinación, crean y editan **solo** las iniciativas de su empresa, y suben fotos.
- **Coordinación** aprueba accesos y puede editar todo.

Los permisos se aplican en la base de datos (Row Level Security de Supabase), no solo en la página.

## Archivos

| Archivo | Para qué sirve |
|---|---|
| `index.html` | El tablero completo |
| `config.js` | URL y clave pública de Supabase (se completa en el paso 3) |
| `supabase/01_esquema.sql` | Tablas, reglas de permisos y almacenamiento de fotos |
| `02_datos_iniciales.sql` (no está en el repo) | Las 23 iniciativas del Excel; se guarda fuera del repo porque incluye nombres de responsables |
| `datos-demo.json` | Datos de muestra que se ven mientras no hay conexión configurada |

## Puesta en marcha (una sola vez, ~15 minutos)

### 1. Crear el proyecto en Supabase
1. Entra a <https://supabase.com>, crea una cuenta gratuita y luego **New project**.
2. Nombre: `respuesta-solidaria-fen`. Región: **South America (São Paulo)**. Guarda la contraseña de la base de datos.

### 2. Crear las tablas y cargar los datos
1. En el proyecto: **SQL Editor → New query**.
2. Pega todo el contenido de `supabase/01_esquema.sql` y pulsa **Run**.
3. Nueva consulta: pega el archivo `02_datos_iniciales.sql` (entregado aparte) y pulsa **Run** (solo una vez).

### 3. Conectar la página
1. En Supabase: **Project Settings → API**. Copia **Project URL** y la clave **anon public**.
2. En GitHub, edita `config.js` y pega ambos valores entre las comillas. Guarda (commit).

### 4. Configurar el ingreso por correo
En Supabase: **Authentication → URL Configuration**
- **Site URL**: la dirección del tablero en GitHub Pages (por ejemplo `https://agnellochiara.github.io/respuesta-solidaria-fen/`).
- **Redirect URLs**: agrega esa misma dirección.

### 5. Publicar en GitHub Pages
En el repositorio: **Settings → Pages → Build and deployment → Source: Deploy from a branch → Branch: `main` / `(root)` → Save**. En 1–2 minutos aparece la dirección pública.

### 6. Hacerte coordinadora
1. Abre el tablero, pulsa **Ingresar** y entra con tu correo.
2. En Supabase, **SQL Editor**, ejecuta (con tu correo):
   ```sql
   update public.perfiles set es_admin = true where email = 'TU_CORREO_AQUI';
   ```
3. Recarga el tablero: verás el panel **Accesos de empresas**.

## Uso diario
1. Comparte el enlace con los responsables de cada empresa.
2. Ellos pulsan **Ingresar**, abren el enlace que les llega al correo y eligen su empresa en **Solicitar acceso**.
3. Tú los apruebas en **Accesos de empresas**. Desde ese momento pueden registrar, editar, marcar como culminadas y subir fotos de las iniciativas de su empresa.

## Notas
- **Correos de ingreso:** el plan gratuito de Supabase envía pocos correos por hora (pensado para pruebas). Si muchas personas van a ingresar el mismo día, configura un servidor de correo propio en **Authentication → Emails → SMTP Settings** (por ejemplo, Resend o el SMTP corporativo).
- **Privacidad:** el público no ve el nombre del responsable de cada iniciativa; solo quienes ingresan con su correo.
- **Fotos:** se reducen automáticamente a 1600 px; límite de 10 MB por archivo. El plan gratuito incluye 1 GB de almacenamiento.
- **Proyecto inactivo:** Supabase pausa los proyectos gratuitos tras 7 días sin uso; se reactivan desde el panel de Supabase.
