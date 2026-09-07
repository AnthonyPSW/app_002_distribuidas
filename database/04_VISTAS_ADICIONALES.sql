/*
    EJECUTAR EN MEDICITY_A, DESPUES DE 03_OBJETOS_7_ENDPOINTS.SQL.

    Vistas de consulta que usan los endpoints adicionales del backend.
    No modifican la entrega: las 3 vistas y los 4 procedimientos del
    script 03 quedan intactos.

    Este script no elimina tablas, vistas, procedimientos ni informacion.
*/

USE MEDICITY_A;
GO

/* VISTA 4: detalle completo de cada diagnostico del Sitio B acompanado
   de su cita, paciente y ciudad del Sitio A. Permite consultar un
   diagnostico por ID y filtrar por texto. */
CREATE OR ALTER VIEW dbo.vw_DiagnosticoDetalle
AS
SELECT
    DI.ID AS ID_DIAGNOSTICO,
    DI.ID_CITA,
    COALESCE(DI.NOMBRE, 'S/I') AS NOMBRE_DIAGNOSTICO,
    COALESCE(DI.DESCRIPCION, 'S/I') AS DESCRIPCION,
    COALESCE(DI.TRATAMIENTO, 'S/I') AS TRATAMIENTO,
    CM.FECHAHORA,
    P.ID AS ID_PACIENTE,
    P.NOMBRE AS PACIENTE,
    C.NOMBRE AS CIUDAD_PACIENTE,
    D.ID AS ID_DOCTOR,
    D.NOMBRE AS DOCTOR,
    E.NOMBRE AS ESPECIALIDAD
FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB] AS DI
INNER JOIN dbo.CITA_MEDICA_SA AS CM
    ON CM.ID = DI.ID_CITA
INNER JOIN dbo.PACIENTE_SA AS P
    ON P.ID = CM.ID_PACIENTE
INNER JOIN dbo.CIUDAD_SA AS C
    ON C.ID = P.ID_CIUDAD
INNER JOIN [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB] AS D
    ON D.ID = CM.ID_DOCTOR
INNER JOIN [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB] AS E
    ON E.ID = D.ID_ESPECIALIDAD;
GO

/* VISTA 5: catalogo de ciudades del Sitio A con la cantidad de
   pacientes locales y de doctores remotos asignados a cada una. */
CREATE OR ALTER VIEW dbo.vw_Ciudades
AS
SELECT
    C.ID,
    C.NOMBRE AS CIUDAD,
    COALESCE(P.TOTAL, 0) AS TOTAL_PACIENTES,
    COALESCE(D.TOTAL, 0) AS TOTAL_DOCTORES
FROM dbo.CIUDAD_SA AS C
LEFT JOIN
(
    SELECT ID_CIUDAD, COUNT(*) AS TOTAL
    FROM dbo.PACIENTE_SA
    GROUP BY ID_CIUDAD
) AS P
    ON P.ID_CIUDAD = C.ID
LEFT JOIN
(
    SELECT ID_CIUDAD, COUNT(*) AS TOTAL
    FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
    GROUP BY ID_CIUDAD
) AS D
    ON D.ID_CIUDAD = C.ID;
GO

/* VISTA 6: catalogo de especialidades del Sitio B con la cantidad de
   doctores registrados en cada una. */
CREATE OR ALTER VIEW dbo.vw_Especialidades
AS
SELECT
    E.ID,
    E.NOMBRE AS ESPECIALIDAD,
    COALESCE(D.TOTAL, 0) AS TOTAL_DOCTORES
FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB] AS E
LEFT JOIN
(
    SELECT ID_ESPECIALIDAD, COUNT(*) AS TOTAL
    FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB]
    GROUP BY ID_ESPECIALIDAD
) AS D
    ON D.ID_ESPECIALIDAD = E.ID;
GO

/* PRUEBAS DE LAS TRES VISTAS: no modifican datos. */
SELECT * FROM dbo.vw_DiagnosticoDetalle ORDER BY ID_DIAGNOSTICO;
SELECT * FROM dbo.vw_Ciudades ORDER BY CIUDAD;
SELECT * FROM dbo.vw_Especialidades ORDER BY ESPECIALIDAD;
GO
