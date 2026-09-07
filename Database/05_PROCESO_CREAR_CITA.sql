/*
    EJECUTAR EN MEDICITY_A, DESPUES DE CONFIGURAR LS_SITIO_B.

    Agrega el proceso adicional para crear citas medicas.
    CREATE OR ALTER no elimina tablas ni informacion.
*/

USE MEDICITY_A;
GO

CREATE OR ALTER PROCEDURE dbo.sp_InsertarCitaMedica
    @ID_PACIENTE INT,
    @ID_DOCTOR INT,
    @FECHAHORA DATETIME2(0),
    @ID_CREADO INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @FECHAHORA <= SYSDATETIME()
        THROW 50101, 'La fecha y hora debe ser posterior a la fecha actual.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PACIENTE_SA
        WHERE ID = @ID_PACIENTE
    )
        THROW 50102, 'El paciente ingresado no existe.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
        WHERE ID = @ID_DOCTOR
    )
        THROW 50103, 'El doctor ingresado no existe.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.CITA_MEDICA_SA
        WHERE ID_DOCTOR = @ID_DOCTOR
          AND FECHAHORA = @FECHAHORA
    )
        THROW 50104, 'El doctor ya tiene una cita registrada en esa fecha y hora.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.CITA_MEDICA_SA
        WHERE ID_PACIENTE = @ID_PACIENTE
          AND FECHAHORA = @FECHAHORA
    )
        THROW 50105, 'El paciente ya tiene una cita registrada en esa fecha y hora.', 1;

    INSERT INTO dbo.CITA_MEDICA_SA
        (ID_PACIENTE, ID_DOCTOR, FECHAHORA)
    VALUES
        (@ID_PACIENTE, @ID_DOCTOR, @FECHAHORA);

    SET @ID_CREADO = CONVERT(INT, SCOPE_IDENTITY());

    SELECT
        @ID_CREADO AS ID_CREADO,
        'Cita medica registrada correctamente.' AS MENSAJE;
END;
GO

/* PRUEBA MANUAL: inserta una cita; ajuste la fecha antes de ejecutarla.
DECLARE @ID_CREADO INT;
EXEC dbo.sp_InsertarCitaMedica
    @ID_PACIENTE = 1,
    @ID_DOCTOR = 1,
    @FECHAHORA = '2027-01-15T10:00:00',
    @ID_CREADO = @ID_CREADO OUTPUT;
SELECT @ID_CREADO AS ID_CREADO;
*/
