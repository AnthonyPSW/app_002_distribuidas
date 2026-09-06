/*
    EJECUTAR EN LA MAQUINA DEL SITIO B.

    Reemplace:
      <IP_TAILSCALE_SITIO_A> por la IP 100.x.x.x de la maquina Sitio A.
      1433 por el puerto TCP fijo de la instancia SITIO_AD_A, si es diferente.
      <CONTRASENA_SA_SITIO_A> por la clave real de sa en Sitio A.

    No use localhost: Sitio A esta en otra maquina de la red Tailscale.
*/

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LS_SITIO_A')
BEGIN
    EXEC master.dbo.sp_addlinkedserver
        @server = N'LS_SITIO_A',
        @srvproduct = N'',
        @provider = N'SQLNCLI',
        @datasrc = N'<IP_TAILSCALE_SITIO_A>,1433',
        @provstr = N'encrypt=yes;trustservercertificate=yes';

    EXEC master.dbo.sp_addlinkedsrvlogin
        @rmtsrvname = N'LS_SITIO_A',
        @useself = N'false',
        @locallogin = NULL,
        @rmtuser = N'sa',
        @rmtpassword = N'<CONTRASENA_SA_SITIO_A>';

    EXEC master.dbo.sp_serveroption
        @server = N'LS_SITIO_A',
        @optname = N'data access',
        @optvalue = N'true';
END;
GO

EXEC master.dbo.sp_testlinkedserver N'LS_SITIO_A';

SELECT * FROM [LS_SITIO_A].[MEDICITY_A].[dbo].[CIUDAD_SA];
SELECT * FROM [LS_SITIO_A].[MEDICITY_A].[dbo].[PACIENTE_SA];
SELECT * FROM [LS_SITIO_A].[MEDICITY_A].[dbo].[CITA_MEDICA_SA];
GO
