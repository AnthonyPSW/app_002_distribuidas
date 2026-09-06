# app_002_distribuidas

Práctica de aplicaciones distribuidas MEDICITY. El repositorio contiene el
backend ASP.NET Core y el script SQL Server para trabajar con dos sitios
conectados mediante Linked Server.

## Estructura

- `backend/`: API REST con los endpoints CRUD.
- `database/MEDICITY_FINAL.sql`: vistas, procedimientos almacenados y
  configuración de los Linked Servers.

## Base de datos

Entorno probado:

- Sitio A: `Anthony\\SITIO_A`, base `MEDICITY_A`.
- Sitio B: `Anthony\\SITIO_B`, base `MEDICITY_B`.
- Linked Servers: `LS_SITIO_A` y `LS_SITIO_B`.

Antes de ejecutar la API, revise las contraseñas indicadas como
`<CONTRASENA_SA>` en `database/MEDICITY_FINAL.sql` y ejecute el script desde
SQL Server Management Studio.

## Ejecutar el backend

Requiere .NET 10 SDK. Configure la conexión local en PowerShell sin guardar la
contraseña en Git:

```powershell
$env:ConnectionStrings__testConnection = "Server=localhost,1440;Database=MEDICITY_A;User Id=sa;Password=SU_CONTRASENA;Encrypt=False;TrustServerCertificate=True;"
cd backend
dotnet restore
dotnet run --launch-profile http
```

- API: `http://localhost:5086`
- Swagger: `http://localhost:5086/swagger`
- Salud: `http://localhost:5086/api/medicity/distribuida/health`

## CRUD disponible

La ruta base es `/api/medicity/distribuida`.

| Método | Ruta | Operación |
|---|---|---|
| GET | `/health` | Verificar base y conexiones |
| GET | `/resumen` | Consulta distribuida general |
| GET | `/catalogos/ciudades` | Listar ciudades |
| GET | `/catalogos/pacientes` | Listar pacientes |
| GET | `/catalogos/especialidades` | Listar especialidades remotas |
| GET/POST | `/doctores` | Listar y crear doctores |
| GET/PUT/DELETE | `/doctores/{id}` | Consultar, actualizar y eliminar doctor |
| GET/POST | `/citas` | Listar y crear citas |
| GET/PUT/DELETE | `/citas/{id}` | Consultar, actualizar y eliminar cita |
| GET/POST | `/diagnosticos` | Listar y crear diagnósticos |
| GET/PUT/DELETE | `/diagnosticos/{id}` | Consultar, actualizar y eliminar diagnóstico |

También se mantienen las rutas del ejemplo original para compatibilidad.

## Estado de la práctica

- Backend CRUD: completo.
- Vistas y procedimientos almacenados: incluidos en el script SQL.
- Funcionamiento distribuido Sitio A/Sitio B: probado.
- Aplicación Flutter: pendiente de integrar en este repositorio.
