/*
    EJECUTAR EN MEDICITY_A, DESPUES DE CONFIGURAR LS_SITIO_B.

    Entrega exacta:
      - 3 vistas.
      - 2 procesos entregados por el profesor.
      - 2 procesos propios.
      - Total expuesto por el backend: 7 endpoints.

    Este script no elimina tablas ni informacion.
*/

USE MEDICITY_A;
GO

/* VISTA 1: consulta general distribuida. Tambien muestra los cambios
   realizados por los dos procesos propios de diagnosticos. */
CREATE OR ALTER VIEW dbo.consulta_general
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY CM.FECHAHORA, CM.ID) AS NUM,
    CM.ID AS ID_CITA,
    DI.ID AS ID_DIAGNOSTICO,
    DI.NOMBRE AS NOMBRE_DIAGNOSTICO,
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

/* VISTA 2: visualiza el resultado del primer proceso del profesor. */
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

/* VISTA 3: visualiza el resultado del segundo proceso del profesor. */
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

/* PROCESO DEL PROFESOR 1: CREATE distribuido de doctor en Sitio B.
   Corrige el adjunto original, al cual le faltaba INSERT INTO. */
CREATE OR ALTER PROCEDURE dbo.sp_InsertarDoctor
    @NOMBRE VARCHAR(200),
    @ID_ESPECIALIDAD INT,
    @ID_CIUDAD INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@NOMBRE)), '') IS NULL
        THROW 50001, 'El nombre del doctor es obligatorio.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.CIUDAD_SA WHERE ID = @ID_CIUDAD)
        THROW 50002, 'La ciudad ingresada no existe.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB]
        WHERE ID = @ID_ESPECIALIDAD
    )
        THROW 50003, 'La especialidad ingresada no existe.', 1;

    INSERT INTO [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
        (NOMBRE, ID_ESPECIALIDAD, ID_CIUDAD)
    VALUES
        (LTRIM(RTRIM(@NOMBRE)), @ID_ESPECIALIDAD, @ID_CIUDAD);

    SELECT 'Doctor registrado correctamente.' AS MENSAJE;
END;
GO

/* PROCESO DEL PROFESOR 2: UPDATE de cita en Sitio A, validando el
   paciente local y el doctor remoto. */
CREATE OR ALTER PROCEDURE dbo.sp_ActualizarCitaMedica
    @ID INT,
    @ID_PACIENTE INT,
    @ID_DOCTOR INT,
    @FECHAHORA DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.CITA_MEDICA_SA WHERE ID = @ID)
        THROW 50011, 'La cita medica no existe.', 1;

    IF @FECHAHORA < GETDATE()
        THROW 50012, 'La fecha y hora no puede ser anterior a la fecha actual.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.PACIENTE_SA WHERE ID = @ID_PACIENTE)
        THROW 50013, 'El paciente ingresado no existe.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
        WHERE ID = @ID_DOCTOR
    )
        THROW 50014, 'El doctor ingresado no existe.', 1;

    UPDATE dbo.CITA_MEDICA_SA
    SET ID_PACIENTE = @ID_PACIENTE,
        ID_DOCTOR = @ID_DOCTOR,
        FECHAHORA = @FECHAHORA
    WHERE ID = @ID;

    SELECT @ID AS ID_ACTUALIZADO,
           'Cita medica actualizada correctamente.' AS MENSAJE;
END;
GO

/* PROCESO PROPIO 1: CREATE distribuido de diagnostico en Sitio B. */
CREATE OR ALTER PROCEDURE dbo.sp_InsertarDiagnostico
    @ID_CITA INT,
    @NOMBRE VARCHAR(50),
    @DESCRIPCION VARCHAR(200),
    @TRATAMIENTO VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.CITA_MEDICA_SA WHERE ID = @ID_CITA)
        THROW 50021, 'La cita medica no existe.', 1;

    IF NULLIF(LTRIM(RTRIM(@DESCRIPCION)), '') IS NULL
        THROW 50022, 'La descripcion del diagnostico es obligatoria.', 1;

    INSERT INTO [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB]
        (ID_CITA, NOMBRE, DESCRIPCION, TRATAMIENTO)
    VALUES
        (@ID_CITA,
         NULLIF(LTRIM(RTRIM(@NOMBRE)), ''),
         LTRIM(RTRIM(@DESCRIPCION)),
         NULLIF(LTRIM(RTRIM(@TRATAMIENTO)), ''));

    SELECT 'Diagnostico registrado correctamente.' AS MENSAJE;
END;
GO

/* PROCESO PROPIO 2: UPDATE distribuido de diagnostico en Sitio B. */
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
        THROW 50301, 'El diagnostico no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.CITA_MEDICA_SA WHERE ID = @ID_CITA)
        THROW 50302, 'La cita medica no existe.', 1;

    IF NULLIF(LTRIM(RTRIM(@DESCRIPCION)), '') IS NULL
        THROW 50303, 'La descripcion del diagnostico es obligatoria.', 1;

    UPDATE [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB]
    SET ID_CITA = @ID_CITA,
        NOMBRE = NULLIF(LTRIM(RTRIM(@NOMBRE)), ''),
        DESCRIPCION = LTRIM(RTRIM(@DESCRIPCION)),
        TRATAMIENTO = NULLIF(LTRIM(RTRIM(@TRATAMIENTO)), '')
    WHERE ID = @ID;

    SELECT @ID AS ID_ACTUALIZADO,
           'Diagnostico actualizado correctamente.' AS MENSAJE;
END;
GO

/* PRUEBAS DE LAS TRES VISTAS: no modifican datos. */
SELECT * FROM dbo.consulta_general ORDER BY NUM;
SELECT * FROM dbo.vw_DoctorDetalle ORDER BY ID;
SELECT * FROM dbo.vw_CitasMedicas ORDER BY ID_CITA;
GO

/*
    DEMOSTRACION DE LOS CUATRO PROCESOS (descomentar uno por uno):

    -- Profesor: CREATE
    EXEC dbo.sp_InsertarDoctor 'LUIS', 1, 1;

    -- Profesor: UPDATE
    EXEC dbo.sp_ActualizarCitaMedica 1, 2, 2, '2026-12-09T10:00:00';

    -- Propio: CREATE
    EXEC dbo.sp_InsertarDiagnostico
        2, 'GRIPE', 'PACIENTE PRESENTA SINTOMAS DE GRIPE', 'REPOSO';

    -- Propio: UPDATE
    EXEC dbo.sp_ActualizarDiagnostico
        1, 1, 'CONTROL', 'PACIENTE EN CONTROL', 'CONTINUAR TRATAMIENTO';
*/
