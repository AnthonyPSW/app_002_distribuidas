# app_002_distribuidas

Práctica MEDICITY distribuida entre dos servidores SQL Server comunicados por
Tailscale. El backend ASP.NET Core se ejecuta como servidor HTTP para que
Flutter lo consuma mediante la IP Tailscale de la máquina del backend.

## Arquitectura

```text
Flutter
   |
   | http://<IP_TAILSCALE_BACKEND>:5086
   v
Backend ASP.NET Core
   |
   | SQL local: localhost:1440
   v
SITIO_AD_A / MEDICITY_A
   |
   | LS_SITIO_B: 100.87.218.93:1441 por Tailscale
   v
XABI\SITIOB / MEDICITY_B
```

Sitio B también tiene `LS_SITIO_A` para comprobar la conexión inversa. En los
Linked Servers se usa la IP `100.x.x.x` y un puerto TCP fijo; no se usa
`localhost` porque cada sitio está en una máquina diferente.

Datos confirmados del Sitio B:

- Servidor SQL: `XABI\SITIOB`.
- Base de datos: `MEDICITY_B`.
- IP Tailscale: `100.87.218.93`.
- Puerto SQL Server: `1441`.

## Scripts SQL y orden de ejecución

1. En Sitio A, editar y ejecutar `database/01_SITIO_A_LINKED_SERVER.sql`.
2. En Sitio B, editar y ejecutar `database/02_SITIO_B_LINKED_SERVER.sql`.
3. En `MEDICITY_A`, ejecutar `database/03_OBJETOS_7_ENDPOINTS.sql`.

Antes de ejecutarlos, reemplace las IP, los puertos y las contraseñas marcadas
entre `< >`. Los scripts no eliminan tablas ni datos.

## Alcance exacto de la entrega

### Tres vistas

1. `consulta_general`: información distribuida completa y diagnósticos.
2. `vw_DoctorDetalle`: comprueba el CREATE de doctor.
3. `vw_CitasMedicas`: comprueba el UPDATE de cita.

### Cuatro procedimientos almacenados

Entregados por el profesor:

1. `sp_InsertarDoctor` — CREATE remoto en `DOCTOR_SB`.
2. `sp_ActualizarCitaMedica` — UPDATE en `CITA_MEDICA_SA` validando Sitio B.

Procesos propios:

3. `sp_InsertarDiagnostico` — CREATE remoto en `DIAGNOSTICO_SB`.
4. `sp_ActualizarDiagnostico` — UPDATE remoto en `DIAGNOSTICO_SB`.

El procedimiento `sp_InsertarDoctor` del adjunto P002 estaba incompleto porque
faltaba la sentencia `INSERT INTO DOCTOR_SB`; aquí ya está corregido.

## Los siete endpoints

Ruta base:

```text
http://<IP_TAILSCALE_BACKEND>:5086/api/medicity/distribuida
```

| # | Método | Ruta | Objeto SQL |
|---:|---|---|---|
| 1 | GET | `/vistas/general` | `consulta_general` |
| 2 | GET | `/vistas/doctores` | `vw_DoctorDetalle` |
| 3 | GET | `/vistas/citas` | `vw_CitasMedicas` |
| 4 | POST | `/procesos/doctores/crear` | `sp_InsertarDoctor` |
| 5 | PUT | `/procesos/citas/{id}/actualizar` | `sp_ActualizarCitaMedica` |
| 6 | POST | `/procesos/diagnosticos/crear` | `sp_InsertarDiagnostico` |
| 7 | PUT | `/procesos/diagnosticos/{id}/actualizar` | `sp_ActualizarDiagnostico` |

Los ejemplos listos para ejecutar están en `backend/app_02.http` y también se
pueden probar desde Swagger.

## Configurar y ejecutar el backend

El backend escucha en todas las interfaces (`0.0.0.0:5086`), incluida
Tailscale. Como el backend y Sitio A se ejecutan en esta misma computadora, la
conexión SQL se realiza localmente por el puerto `1440`. Configure la contraseña
sin guardarla en Git:

```powershell
$env:ConnectionStrings__testConnection = "Server=localhost,1440;Database=MEDICITY_A;User Id=sa;Password=<CONTRASENA>;Encrypt=False;TrustServerCertificate=True;"
cd backend
dotnet restore
dotnet run --launch-profile http
```

Desde Flutter o desde otra máquina del mismo Tailnet:

```text
http://<IP_TAILSCALE_BACKEND>:5086/swagger
```

No debe usarse `localhost` en Flutter, porque `localhost` sería el teléfono o
la computadora donde corre Flutter, no el servidor del backend.
