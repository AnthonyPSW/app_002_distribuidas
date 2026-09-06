/*
    PRACTICA MEDICITY - SITIO_A / SITIO_B

    Distribucion:
      SITIO_A.MEDICITY_A: CIUDAD_SA, PACIENTE_SA, CITA_MEDICA_SA
      SITIO_B.MEDICITY_B: ESPECIALIDAD_SB, DOCTOR_SB, DIAGNOSTICO_SB

    Este script no elimina ni migra nuevamente los datos existentes.
*/

/* ================================================================
   1. EJECUTAR CONECTADO A localhost\SITIO_B
   Crear el enlace inverso hacia la instancia que realmente existe.
   Sustituya <CONTRASENA_SA> antes de ejecutar esta seccion manualmente.
   ================================================================ */

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LS_SITIO_A')
BEGIN
    EXEC master.dbo.sp_addlinkedserver
        @server = N'LS_SITIO_A',
        @srvproduct = N'',
        @provider = N'SQLNCLI',
        @datasrc = N'localhost\SITIO_A',
        @provstr = N'encrypt=yes;trustservercertificate=yes';

    EXEC master.dbo.sp_addlinkedsrvlogin
        @rmtsrvname = N'LS_SITIO_A',
        @useself = N'false',
        @locallogin = NULL,
        @rmtuser = N'sa',
        @rmtpassword = N'<CONTRASENA_SA>';

    EXEC master.dbo.sp_serveroption
        @server = N'LS_SITIO_A',
        @optname = N'data access',
        @optvalue = N'true';
END;
GO

EXEC master.dbo.sp_testlinkedserver N'LS_SITIO_A';
SELECT * FROM [LS_SITIO_A].[MEDICITY_A].[dbo].[CIUDAD_SA];
GO

/* ================================================================
   2. EJECUTAR CONECTADO A localhost\SITIO_A
   Objetos de la practica en MEDICITY_A.
   ================================================================ */

USE MEDICITY_A;
GO

CREATE OR ALTER VIEW dbo.consulta_general
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY CM.FECHAHORA, CM.ID) AS NUM,
    P.NOMBRE AS PACIENTE,
    P.FECHA_NACIMIENTO,
    P.DIRECCION,
    C.NOMBRE AS CIUDAD_PACIENTE,
    D.NOMBRE AS DOCTOR,
    CD.NOMBRE AS CIUDAD_DOCTOR,
    E.NOMBRE AS ESPECIALIDAD,
    CM.FECHAHORA,
    COALESCE(DI.DESCRIPCION, 'S/I') AS DESCRIPCION,
    COALESCE(DI.TRATAMIENTO, 'S/I') AS TRATAMIENTO
FROM dbo.CITA_MEDICA_SA AS CM
INNER JOIN dbo.PACIENTE_SA AS P
    ON P.ID = CM.ID_PACIENTE
INNER JOIN dbo.CIUDAD_SA AS C
    ON C.ID = P.ID_CIUDAD
INNER JOIN [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB] AS D
    ON D.ID = CM.ID_DOCTOR
INNER JOIN dbo.CIUDAD_SA AS CD
    ON CD.ID = D.ID_CIUDAD
INNER JOIN [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB] AS E
    ON E.ID = D.ID_ESPECIALIDAD
LEFT JOIN [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB] AS DI
    ON DI.ID_CITA = CM.ID;
GO

CREATE OR ALTER PROCEDURE dbo.sp_InsertarDoctor
    @NOMBRE NVARCHAR(100),
    @ID_ESPECIALIDAD INT,
    @ID_CIUDAD INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@NOMBRE)), N'') IS NULL
        THROW 50001, 'El nombre del doctor es obligatorio.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.CIUDAD_SA
        WHERE ID = @ID_CIUDAD
    )
        THROW 50002, 'La ciudad ingresada no existe en Sitio A.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB]
        WHERE ID = @ID_ESPECIALIDAD
    )
        THROW 50003, 'La especialidad ingresada no existe en Sitio B.', 1;

    INSERT INTO [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
        (NOMBRE, ID_ESPECIALIDAD, ID_CIUDAD)
    VALUES
        (LTRIM(RTRIM(@NOMBRE)), @ID_ESPECIALIDAD, @ID_CIUDAD);

    SELECT 'Doctor registrado correctamente en Sitio B.' AS MENSAJE;
END;
GO

CREATE OR ALTER VIEW dbo.vw_DoctorDetalle
AS
SELECT
    D.ID,
    D.NOMBRE AS DOCTOR,
    D.ID_ESPECIALIDAD,
    E.NOMBRE AS ESPECIALIDAD,
    D.ID_CIUDAD,
    C.NOMBRE AS CIUDAD
FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB] AS D
INNER JOIN [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB] AS E
    ON E.ID = D.ID_ESPECIALIDAD
INNER JOIN dbo.CIUDAD_SA AS C
    ON C.ID = D.ID_CIUDAD;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ActualizarCitaMedica
    @ID INT,
    @ID_PACIENTE INT,
    @ID_DOCTOR INT,
    @FECHAHORA DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.CITA_MEDICA_SA
        WHERE ID = @ID
    )
        THROW 50011, 'La cita medica no existe en Sitio A.', 1;

    IF @FECHAHORA < GETDATE()
        THROW 50012, 'La fecha y hora de la cita no puede ser anterior a la fecha actual.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PACIENTE_SA
        WHERE ID = @ID_PACIENTE
    )
        THROW 50013, 'El paciente ingresado no existe en Sitio A.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
        WHERE ID = @ID_DOCTOR
    )
        THROW 50014, 'El doctor ingresado no existe en Sitio B.', 1;

    UPDATE dbo.CITA_MEDICA_SA
    SET
        ID_PACIENTE = @ID_PACIENTE,
        ID_DOCTOR = @ID_DOCTOR,
        FECHAHORA = @FECHAHORA
    WHERE ID = @ID;

    SELECT @ID AS ID_ACTUALIZADO,
           'Cita medica actualizada correctamente en Sitio A.' AS MENSAJE;
END;
GO

CREATE OR ALTER VIEW dbo.vw_CitasMedicas
AS
SELECT
    CM.ID AS ID_CITA,
    CM.ID_PACIENTE,
    P.NOMBRE AS PACIENTE,
    CM.ID_DOCTOR,
    D.NOMBRE AS DOCTOR,
    D.ID_ESPECIALIDAD,
    E.NOMBRE AS ESPECIALIDAD,
    CM.FECHAHORA
FROM dbo.CITA_MEDICA_SA AS CM
INNER JOIN dbo.PACIENTE_SA AS P
    ON P.ID = CM.ID_PACIENTE
INNER JOIN [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB] AS D
    ON D.ID = CM.ID_DOCTOR
INNER JOIN [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB] AS E
    ON E.ID = D.ID_ESPECIALIDAD;
GO

CREATE OR ALTER PROCEDURE dbo.sp_InsertarDiagnostico
    @ID_CITA INT,
    @NOMBRE VARCHAR(50),
    @DESCRIPCION VARCHAR(200),
    @TRATAMIENTO VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.CITA_MEDICA_SA
        WHERE ID = @ID_CITA
    )
        THROW 50021, 'La cita medica no existe en Sitio A.', 1;

    IF NULLIF(LTRIM(RTRIM(@DESCRIPCION)), '') IS NULL
        THROW 50022, 'La descripcion del diagnostico es obligatoria.', 1;

    INSERT INTO [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB]
        (ID_CITA, NOMBRE, DESCRIPCION, TRATAMIENTO)
    VALUES
        (@ID_CITA, NULLIF(LTRIM(RTRIM(@NOMBRE)), ''),
         LTRIM(RTRIM(@DESCRIPCION)), NULLIF(LTRIM(RTRIM(@TRATAMIENTO)), ''));

    SELECT 'Diagnostico registrado correctamente en Sitio B.' AS MENSAJE;
END;
GO

CREATE OR ALTER VIEW dbo.vw_Diagnosticos
AS
SELECT
    DI.ID AS ID_DIAGNOSTICO,
    CM.ID AS ID_CITA,
    CM.ID_PACIENTE,
    P.NOMBRE AS PACIENTE,
    CM.ID_DOCTOR,
    D.NOMBRE AS DOCTOR,
    CM.FECHAHORA,
    DI.NOMBRE AS DIAGNOSTICO,
    DI.DESCRIPCION,
    DI.TRATAMIENTO
FROM dbo.CITA_MEDICA_SA AS CM
INNER JOIN dbo.PACIENTE_SA AS P
    ON P.ID = CM.ID_PACIENTE
INNER JOIN [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB] AS D
    ON D.ID = CM.ID_DOCTOR
INNER JOIN [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB] AS DI
    ON DI.ID_CITA = CM.ID;
GO

/* ================================================================
   3. PROCEDIMIENTOS COMPLEMENTARIOS PARA EL CRUD DEL BACKEND
   ================================================================ */

CREATE OR ALTER PROCEDURE dbo.sp_ActualizarDoctor
    @ID INT,
    @NOMBRE NVARCHAR(100),
    @ID_ESPECIALIDAD INT,
    @ID_CIUDAD INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
        WHERE ID = @ID
    )
        THROW 50101, 'El doctor no existe en Sitio B.', 1;

    IF NULLIF(LTRIM(RTRIM(@NOMBRE)), N'') IS NULL
        THROW 50102, 'El nombre del doctor es obligatorio.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.CIUDAD_SA WHERE ID = @ID_CIUDAD)
        THROW 50102, 'La ciudad ingresada no existe en Sitio A.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB]
        WHERE ID = @ID_ESPECIALIDAD
    )
        THROW 50103, 'La especialidad ingresada no existe en Sitio B.', 1;

    UPDATE [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
    SET NOMBRE = LTRIM(RTRIM(@NOMBRE)),
        ID_ESPECIALIDAD = @ID_ESPECIALIDAD,
        ID_CIUDAD = @ID_CIUDAD
    WHERE ID = @ID;

    SELECT @ID AS ID_ACTUALIZADO,
           'Doctor actualizado correctamente en Sitio B.' AS MENSAJE;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_EliminarDoctor
    @ID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
        WHERE ID = @ID
    )
        THROW 50104, 'El doctor no existe en Sitio B.', 1;

    IF EXISTS (SELECT 1 FROM dbo.CITA_MEDICA_SA WHERE ID_DOCTOR = @ID)
        THROW 50105, 'No se puede eliminar el doctor porque tiene citas asociadas.', 1;

    DELETE FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
    WHERE ID = @ID;

    SELECT @ID AS ID_ELIMINADO,
           'Doctor eliminado correctamente de Sitio B.' AS MENSAJE;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_InsertarCitaMedica
    @ID_PACIENTE INT,
    @ID_DOCTOR INT,
    @FECHAHORA DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.PACIENTE_SA WHERE ID = @ID_PACIENTE)
        THROW 50201, 'El paciente ingresado no existe en Sitio A.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
        WHERE ID = @ID_DOCTOR
    )
        THROW 50202, 'El doctor ingresado no existe en Sitio B.', 1;

    IF @FECHAHORA < GETDATE()
        THROW 50203, 'La fecha y hora de la cita debe ser futura.', 1;

    INSERT INTO dbo.CITA_MEDICA_SA (ID_PACIENTE, ID_DOCTOR, FECHAHORA)
    VALUES (@ID_PACIENTE, @ID_DOCTOR, @FECHAHORA);

    SELECT CAST(SCOPE_IDENTITY() AS INT) AS ID_INSERTADO,
           'Cita medica registrada correctamente en Sitio A.' AS MENSAJE;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_EliminarCitaMedica
    @ID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.CITA_MEDICA_SA WHERE ID = @ID)
        THROW 50204, 'La cita medica no existe en Sitio A.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB]
        WHERE ID_CITA = @ID
    )
        THROW 50205, 'No se puede eliminar la cita porque tiene diagnosticos asociados.', 1;

    DELETE FROM dbo.CITA_MEDICA_SA WHERE ID = @ID;

    SELECT @ID AS ID_ELIMINADO,
           'Cita medica eliminada correctamente de Sitio A.' AS MENSAJE;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ActualizarDiagnostico
    @ID INT,
    @ID_CITA INT,
    @NOMBRE VARCHAR(50),
    @DESCRIPCION VARCHAR(200),
    @TRATAMIENTO VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB]
        WHERE ID = @ID
    )
        THROW 50301, 'El diagnostico no existe en Sitio B.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.CITA_MEDICA_SA WHERE ID = @ID_CITA)
        THROW 50302, 'La cita medica no existe en Sitio A.', 1;

    IF NULLIF(LTRIM(RTRIM(@DESCRIPCION)), '') IS NULL
        THROW 50303, 'La descripcion del diagnostico es obligatoria.', 1;

    UPDATE [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB]
    SET ID_CITA = @ID_CITA,
        NOMBRE = NULLIF(LTRIM(RTRIM(@NOMBRE)), ''),
        DESCRIPCION = LTRIM(RTRIM(@DESCRIPCION)),
        TRATAMIENTO = NULLIF(LTRIM(RTRIM(@TRATAMIENTO)), '')
    WHERE ID = @ID;

    SELECT @ID AS ID_ACTUALIZADO,
           'Diagnostico actualizado correctamente en Sitio B.' AS MENSAJE;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_EliminarDiagnostico
    @ID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB]
        WHERE ID = @ID
    )
        THROW 50304, 'El diagnostico no existe en Sitio B.', 1;

    DELETE FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB]
    WHERE ID = @ID;

    SELECT @ID AS ID_ELIMINADO,
           'Diagnostico eliminado correctamente de Sitio B.' AS MENSAJE;
END;
GO

/* ================================================================
   4. CONSULTAS DE VERIFICACION SIN MODIFICAR DATOS
   ================================================================ */

SELECT * FROM dbo.consulta_general ORDER BY NUM;
SELECT * FROM dbo.vw_DoctorDetalle ORDER BY ID;
SELECT * FROM dbo.vw_CitasMedicas ORDER BY ID_CITA;
SELECT * FROM dbo.vw_Diagnosticos ORDER BY ID_DIAGNOSTICO;
GO

/*
   DEMOSTRACION PARA LA PRESENTACION (ejecutar cuando se quiera
   conservar estos cambios):

   EXEC dbo.sp_InsertarDoctor
       @NOMBRE = N'LUIS',
       @ID_ESPECIALIDAD = 1,
       @ID_CIUDAD = 1;

   EXEC dbo.sp_ActualizarCitaMedica
       @ID = 1,
       @ID_PACIENTE = 2,
       @ID_DOCTOR = 2,
       @FECHAHORA = '2026-09-12T10:00:00';

   EXEC dbo.sp_InsertarDiagnostico
       @ID_CITA = 2,
       @NOMBRE = 'GRIPE',
       @DESCRIPCION = 'PACIENTE PRESENTA SINTOMAS DE GRIPE',
       @TRATAMIENTO = 'REPOSO Y MEDICACION';
*/
