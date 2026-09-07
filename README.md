# app_002_distribuidas

Práctica MEDICITY distribuida entre dos instancias de SQL Server conectadas
mediante Tailscale. El backend ASP.NET Core se ejecuta en la computadora del
Sitio A y expone exactamente **7 endpoints** para el futuro cliente Flutter.

## 1. Estado actual verificado

| Componente | Configuración actual |
|---|---|
| Backend | `http://100.99.13.87:5086` |
| Swagger | `http://100.99.13.87:5086/swagger` |
| Sitio A | `ANTHONY\SITIO_A` |
| Base del Sitio A | `MEDICITY_A` |
| Tailscale del Sitio A | `100.99.13.87` |
| Puerto SQL del Sitio A | `1440` |
| Sitio B usado en SSMS | `XABI\SITIOB` |
| Nombre reportado por SQL en Sitio B | `WIN-MOJAG62QD68\SITIOB` |
| Base del Sitio B | `MEDICITY_B` |
| Tailscale del Sitio B | `100.87.218.93` |
| Puerto SQL del Sitio B | `1441` |
| Enlace desde A | `LS_SITIO_B → 100.87.218.93,1441` |
| Enlace desde B | `LS_SITIO_A → 100.99.13.87,1440` |

Pruebas realizadas el 6 de septiembre de 2026:

- Los puertos `100.99.13.87:1440` y `100.87.218.93:1441` responden por TCP.
- Sitio A consulta correctamente las tablas remotas del Sitio B.
- Sitio B consulta correctamente las tablas remotas del Sitio A.
- Las tres vistas del backend responden con HTTP `200`.
- Swagger muestra los 7 endpoints de la entrega y los endpoints de consulta
  adicionales descritos en la sección 10.
- Datos comprobados sin modificarlos: 2 ciudades, 2 pacientes, 2 citas,
  2 doctores, 2 especialidades y 1 diagnóstico.

## 2. Arquitectura

```text
Flutter / Postman / navegador
              |
              | HTTP por Tailscale
              | http://100.99.13.87:5086
              v
      Backend ASP.NET Core
              |
              | SQL local: localhost,1440
              v
   ANTHONY\SITIO_A / MEDICITY_A
              |
              | LS_SITIO_B por Tailscale
              | 100.87.218.93,1441
              v
       XABI\SITIOB / MEDICITY_B
```

La conexión inversa también está configurada:

```text
XABI\SITIOB / MEDICITY_B
              |
              | LS_SITIO_A por Tailscale
              | 100.99.13.87,1440
              v
ANTHONY\SITIO_A / MEDICITY_A
```

## 3. Distribución de las tablas

### Sitio A — `MEDICITY_A`

- `CIUDAD_SA`
- `PACIENTE_SA`
- `CITA_MEDICA_SA`

### Sitio B — `MEDICITY_B`

- `ESPECIALIDAD_SB`
- `DOCTOR_SB`
- `DIAGNOSTICO_SB`

Las vistas y procedimientos se crean en `MEDICITY_A`. Cuando necesitan datos
del Sitio B utilizan nombres de cuatro partes, por ejemplo:

```sql
[LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
```

## 4. Archivos del repositorio

```text
app_002_distribuidas/
├── app_02.slnx
├── app_02.csproj
├── Program.cs
├── appsettings.json
├── app_02.http
├── Controllers/MedicityController.cs
├── Data/AppDbContext.cs
├── DTO/
├── Views/
├── Properties/
└── database/
    ├── 01_SITIO_A_LINKED_SERVER.sql
    ├── 02_SITIO_B_LINKED_SERVER.sql
    ├── 03_OBJETOS_7_ENDPOINTS.sql
    └── 04_VISTAS_ADICIONALES.sql
```

Después de clonar el repositorio, abra `app_02.slnx` para cargar directamente
la solución completa en Visual Studio 2026. No es necesario buscar el proyecto
dentro de otra subcarpeta.

## 5. Valores que se deben cambiar

Esta es la guía rápida cuando se use otra computadora, IP, puerto o
contraseña.

| Cambio | Archivo | Valor que debe editarse |
|---|---|---|
| IP o puerto de Sitio B | `database/01_SITIO_A_LINKED_SERVER.sql` | `@datasrc` |
| Contraseña de Sitio B | `database/01_SITIO_A_LINKED_SERVER.sql` | `<CONTRASENA_SA_SITIO_B>` |
| IP o puerto de Sitio A | `database/02_SITIO_B_LINKED_SERVER.sql` | `@datasrc` |
| Contraseña de Sitio A | `database/02_SITIO_B_LINKED_SERVER.sql` | `<CONTRASENA_SA_SITIO_A>` |
| Puerto local de SQL A | Variable de entorno del backend | `Server=localhost,PUERTO` |
| IP o puerto del backend | `app_02.http` | Variable `@host` |
| Puerto donde escucha la API | `appsettings.json` | Propiedad `Urls` |
| IP usada por Flutter | Archivo de configuración de Flutter | `baseUrl` |

### Valores actuales de los dos Linked Servers

En Sitio A:

```sql
@server = N'LS_SITIO_B'
@datasrc = N'100.87.218.93,1441'
```

En Sitio B:

```sql
@server = N'LS_SITIO_A'
@datasrc = N'100.99.13.87,1440'
```

No coloque `localhost` en `@datasrc` cuando el destino está en otra máquina.
`localhost` siempre representa la computadora donde se está ejecutando SQL
Server.

### Si cambia una IP después de crear el Linked Server

Los scripts no sobrescriben un Linked Server existente. Primero elimine
solamente su configuración y después vuelva a ejecutar el script correcto.
Esto no elimina bases, tablas ni registros.

En Sitio A, para recrear `LS_SITIO_B`:

```sql
USE master;
GO
EXEC master.dbo.sp_dropserver
    @server = N'LS_SITIO_B',
    @droplogins = 'droplogins';
GO
```

Después edite y ejecute `database/01_SITIO_A_LINKED_SERVER.sql`.

En Sitio B, para recrear `LS_SITIO_A`:

```sql
USE master;
GO
EXEC master.dbo.sp_dropserver
    @server = N'LS_SITIO_A',
    @droplogins = 'droplogins';
GO
```

Después edite y ejecute `database/02_SITIO_B_LINKED_SERVER.sql`.

## 6. Preparar Tailscale y SQL Server

Realice estos pasos en las dos computadoras:

1. Inicie sesión en Tailscale y confirme que ambas máquinas estén conectadas
   al mismo Tailnet.
2. En SQL Server Configuration Manager, habilite `TCP/IP` para la instancia.
3. Configure un puerto TCP fijo: `1440` en Sitio A y `1441` en Sitio B.
4. Reinicie el servicio de la instancia después de cambiar TCP/IP o el puerto.
5. Permita el puerto correspondiente en el firewall para la red Tailscale.
6. Habilite el modo de autenticación de SQL Server y confirme que el usuario
   remoto pueda iniciar sesión.

Comprobaciones desde la computadora del Sitio A:

```powershell
Test-NetConnection 100.87.218.93 -Port 1441
Test-NetConnection 100.99.13.87 -Port 1440
```

El resultado correcto es:

```text
TcpTestSucceeded : True
```

El `ping` puede estar bloqueado por el firewall. Para esta práctica, la prueba
importante es que el puerto TCP de SQL Server responda.

## 7. Crear los Linked Servers

Orden obligatorio:

1. Abra SSMS conectado a `ANTHONY\SITIO_A`.
2. Reemplace `<CONTRASENA_SA_SITIO_B>` y ejecute
   `database/01_SITIO_A_LINKED_SERVER.sql`.
3. Abra SSMS conectado a `XABI\SITIOB`.
4. Reemplace `<CONTRASENA_SA_SITIO_A>` y ejecute
   `database/02_SITIO_B_LINKED_SERVER.sql`.

Prueba desde Sitio A:

```sql
EXEC master.dbo.sp_testlinkedserver N'LS_SITIO_B';

SELECT * FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB];
SELECT * FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB];
SELECT * FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB];
```

Prueba desde Sitio B:

```sql
EXEC master.dbo.sp_testlinkedserver N'LS_SITIO_A';

SELECT * FROM [LS_SITIO_A].[MEDICITY_A].[dbo].[CIUDAD_SA];
SELECT * FROM [LS_SITIO_A].[MEDICITY_A].[dbo].[PACIENTE_SA];
SELECT * FROM [LS_SITIO_A].[MEDICITY_A].[dbo].[CITA_MEDICA_SA];
```

## 8. Crear las vistas y procedimientos

Conéctese a Sitio A y ejecute:

```text
database/03_OBJETOS_7_ENDPOINTS.sql
```

El script utiliza `CREATE OR ALTER`, por lo que puede ejecutarse nuevamente
para actualizar el código. No elimina tablas ni registros.

### Tres vistas

| Vista | Función |
|---|---|
| `consulta_general` | Une citas, pacientes y ciudades de A con doctores, especialidades y diagnósticos de B |
| `vw_DoctorDetalle` | Visualiza el resultado de insertar un doctor remoto |
| `vw_CitasMedicas` | Visualiza el resultado de actualizar una cita |

### Dos procesos entregados por el profesor

| Procedimiento | Tipo | Ubicación afectada |
|---|---|---|
| `sp_InsertarDoctor` | CREATE | `DOCTOR_SB` en Sitio B |
| `sp_ActualizarCitaMedica` | UPDATE | `CITA_MEDICA_SA` en Sitio A |

El procedimiento `sp_InsertarDoctor` del material P002 estaba incompleto: le
faltaba `INSERT INTO DOCTOR_SB`. La versión del repositorio ya está corregida.

### Dos procesos propios

| Procedimiento | Tipo | Ubicación afectada |
|---|---|---|
| `sp_InsertarDiagnostico` | CREATE | `DIAGNOSTICO_SB` en Sitio B |
| `sp_ActualizarDiagnostico` | UPDATE | `DIAGNOSTICO_SB` en Sitio B |

### Cuatro vistas adicionales

Después del script anterior, ejecute también en Sitio A:

```text
database/04_VISTAS_ADICIONALES.sql
```

Crea las vistas que usan los endpoints de consulta adicionales. También usa
`CREATE OR ALTER` y no toca las tres vistas ni los cuatro procedimientos de la
entrega.

| Vista | Función |
|---|---|
| `vw_DiagnosticoDetalle` | Cada diagnóstico del Sitio B junto a su cita, paciente y ciudad del Sitio A |
| `vw_Ciudades` | Ciudades del Sitio A con sus pacientes locales y sus doctores remotos |
| `vw_Especialidades` | Especialidades del Sitio B con la cantidad de doctores de cada una |
| `vw_Pacientes` | Catálogo de pacientes con su ciudad |

## 9. Configurar y ejecutar el backend

Requisitos:

- .NET 10 SDK.
- Sitio A ejecutándose en `localhost,1440`.
- `LS_SITIO_B` funcionando.
- Las tres vistas y los cuatro procedimientos creados.

La contraseña no debe subirse a GitHub. Configure la conexión solamente en la
terminal desde la cual iniciará la API:

```powershell
$env:ConnectionStrings__testConnection = "Server=localhost,1440;Database=MEDICITY_A;User Id=sa;Password=SU_CONTRASENA;Encrypt=False;TrustServerCertificate=True;"
dotnet restore
dotnet run --project app_02.csproj --launch-profile http
```

La consola debe mostrar:

```text
Now listening on: http://0.0.0.0:5086
```

Direcciones de prueba:

- Swagger: `http://100.99.13.87:5086/swagger`
- Vista general:
  `http://100.99.13.87:5086/api/medicity/distribuida/vistas/general`

El backend escucha en `0.0.0.0`, por lo que acepta conexiones desde localhost,
la red local y Tailscale. Si cambia el puerto `5086`, actualice estos archivos:

1. `appsettings.json`.
2. `Properties/launchSettings.json`.
3. `app_02.http`.
4. La constante `baseUrl` de Flutter.

## 10. Los siete endpoints

Ruta base actual:

```text
http://100.99.13.87:5086/api/medicity/distribuida
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

Estos siete endpoints son la entrega evaluada y conservan su ruta, su verbo y
su formato de respuesta.

### Endpoints de consulta adicionales

El backend expone además estas consultas de solo lectura. Ninguna inserta,
actualiza ni elimina información, y todas dependen de
`database/04_VISTAS_ADICIONALES.sql`.

| Método | Ruta | Qué entrega |
|---|---|---|
| GET | `/vistas/doctores/{id}` | Un doctor, con `404` controlado |
| GET | `/vistas/citas/{id}` | Una cita médica, con `404` controlado |
| GET | `/vistas/diagnosticos` | Diagnósticos distribuidos, filtrables por `idCita` y por `texto` |
| GET | `/vistas/diagnosticos/{id}` | Un diagnóstico, con `404` controlado |
| GET | `/vistas/ciudades` | Catálogo de ciudades del Sitio A |
| GET | `/vistas/especialidades` | Catálogo de especialidades del Sitio B |
| GET | `/vistas/pacientes` | Catálogo de pacientes con su ciudad |

Los catálogos entregan los identificadores que necesitan los formularios de
Flutter. Ciudades y especialidades permiten crear doctores, mientras que
pacientes permite seleccionar la persona al crear o actualizar una cita.

### Identificador en los procesos UPDATE

Los dos endpoints de actualización reciben el identificador del registro en
la URL, mediante `{id}`. No se repite el ID dentro del JSON:

```text
PUT /api/medicity/distribuida/procesos/citas/1/actualizar
PUT /api/medicity/distribuida/procesos/diagnosticos/1/actualizar
```

El controlador envía ese valor como `@ID` al procedimiento almacenado. Tanto
`sp_ActualizarCitaMedica` como `sp_ActualizarDiagnostico` comprueban primero
que el registro exista y actualizan únicamente la fila que cumple
`WHERE ID = @ID`.

Los siete ejemplos completos están en `app_02.http`.

### Crear doctor

```http
POST /api/medicity/distribuida/procesos/doctores/crear
Content-Type: application/json

{
  "nombre": "LUIS",
  "idEspecialidad": 1,
  "idCiudad": 1
}
```

Después compruebe el resultado con `GET /vistas/doctores`.

### Actualizar cita

```http
PUT /api/medicity/distribuida/procesos/citas/1/actualizar
Content-Type: application/json

{
  "idPaciente": 2,
  "idDoctor": 2,
  "fechaHora": "2026-12-09T10:00:00"
}
```

Después compruebe el resultado con `GET /vistas/citas`.

### Crear diagnóstico

```http
POST /api/medicity/distribuida/procesos/diagnosticos/crear
Content-Type: application/json

{
  "idCita": 2,
  "nombre": "GRIPE",
  "descripcion": "PACIENTE PRESENTA SINTOMAS DE GRIPE",
  "tratamiento": "REPOSO Y MEDICACION"
}
```

Después compruebe el resultado con `GET /vistas/general`.

### Actualizar diagnóstico

```http
PUT /api/medicity/distribuida/procesos/diagnosticos/1/actualizar
Content-Type: application/json

{
  "idCita": 1,
  "nombre": "CONTROL",
  "descripcion": "PACIENTE EN CONTROL",
  "tratamiento": "CONTINUAR TRATAMIENTO"
}
```

Después compruebe el resultado con `GET /vistas/general`.

## 11. Configuración futura de Flutter

Flutter debe usar la IP Tailscale del servidor del backend, nunca `localhost`:

```dart
const String baseUrl =
    'http://100.99.13.87:5086/api/medicity/distribuida';
```

En Flutter, `localhost` representa el teléfono, emulador o computadora donde
se ejecuta Flutter. No representa el servidor ASP.NET Core.

Si Android bloquea las solicitudes HTTP durante la práctica, revise que la
aplicación permita tráfico HTTP de desarrollo en su configuración Android. En
una entrega de producción se debe usar HTTPS.

## 12. Orden recomendado para la presentación

1. Mostrar Tailscale conectado en las dos computadoras.
2. Mostrar `MEDICITY_A` con sus tres tablas `_SA`.
3. Mostrar `MEDICITY_B` con sus tres tablas `_SB`.
4. Ejecutar las consultas de `LS_SITIO_B` desde Sitio A.
5. Ejecutar las consultas de `LS_SITIO_A` desde Sitio B.
6. Mostrar las tres vistas.
7. Ejecutar `sp_InsertarDoctor` y comprobar `vw_DoctorDetalle`.
8. Ejecutar `sp_ActualizarCitaMedica` y comprobar `vw_CitasMedicas`.
9. Ejecutar los dos procedimientos propios y comprobar `consulta_general`.
10. Abrir Swagger y demostrar los siete endpoints.
11. Mostrar Flutter consumiendo
    `http://100.99.13.87:5086/api/medicity/distribuida`.

Use datos de demostración que puedan conservarse. Las pruebas automáticas del
repositorio utilizan identificadores inexistentes para verificar errores sin
alterar la información real.

## 13. Problemas frecuentes

### `TcpTestSucceeded : False`

- Confirme que Tailscale esté conectado en las dos máquinas.
- Revise la IP `100.x.x.x` del destino.
- Confirme que SQL Server use el puerto fijo configurado.
- Revise el firewall de la computadora destino.
- Reinicie el servicio SQL Server después de cambiar TCP/IP.

### `Login failed for user 'sa'`

- Confirme la contraseña.
- Verifique que `sa` esté habilitado.
- Verifique que SQL Server permita autenticación de SQL Server.
- No confunda la contraseña de Sitio A con la de Sitio B.

### `Server 'LS_SITIO_A/LS_SITIO_B' already exists`

Elimine únicamente el Linked Server con `sp_dropserver` como se explica en la
sección 5 y vuelva a ejecutar su script.

### `Could not find server ... in sys.servers`

El Linked Server no fue creado en esa instancia. Ejecute el script correcto en
`master` y confirme que está conectado al sitio correspondiente.

### Error del proveedor `SQLNCLI`

El material del profesor utiliza `SQLNCLI`. Si la máquina no tiene ese
proveedor instalado, instale/configure el proveedor requerido por la materia o
cambie ambos scripts a un proveedor disponible, como `MSOLEDBSQL`. No mezcle
proveedores diferentes sin volver a probar las consultas distribuidas.

### La API abre localmente pero no desde otra máquina

- Confirme que la consola indique `http://0.0.0.0:5086`.
- Pruebe `Test-NetConnection 100.99.13.87 -Port 5086` desde la otra máquina.
- Revise Tailscale y el firewall del servidor del backend.
- Confirme que Flutter use `100.99.13.87`, no `localhost`.

### HTTP `503` en las vistas

Cuando la base o el Linked Server no responden, el backend ya no devuelve un
`500` vacío: responde `503` con un mensaje general, el número de error de SQL
Server y una sugerencia sencilla. Los detalles internos de la distribución no
se muestran al usuario:

```json
{
  "mensaje": "No se pudo completar la operacion. Verifique la conexion con la base de datos.",
  "numeroSql": 18456,
  "sugerencia": "Verifique la conexion y las credenciales de la base de datos."
}
```

Lista de comprobación:

- Ejecute `database/03_OBJETOS_7_ENDPOINTS.sql` en `MEDICITY_A`.
- Ejecute `database/04_VISTAS_ADICIONALES.sql` si falla una consulta adicional.
- Pruebe `LS_SITIO_B` directamente desde SSMS.
- Confirme que existan las seis tablas `_SA` y `_SB`.

## 14. Seguridad de la práctica

- No suba contraseñas reales al repositorio.
- Los archivos versionados contienen marcadores como `SU_CONTRASENA`.
- Configure la contraseña del backend mediante una variable de entorno.
- Restrinja los puertos SQL y del backend a las redes necesarias.
- El usuario `sa` se conserva por compatibilidad con el material académico; en
  un sistema real se debe usar un usuario con permisos mínimos.
