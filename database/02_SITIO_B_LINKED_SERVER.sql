/*
    EJECUTAR EN LA MAQUINA DEL SITIO B.

    Servidor remoto confirmado:
      Maquina/instancia: ANTHONY\SITIO_A
      IP Tailscale: 100.99.13.87
      Puerto TCP: 1440

    Reemplace <CONTRASENA_SA_SITIO_A> por la clave real de sa en Sitio A.

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
        @datasrc = N'100.99.13.87,1440',
        @provstr = N'encrypt=yes;trustservercertificate=yes';

    EXEC master.dbo.sp_addlinkedsrvlogin
        @rmtsrvname = N'LS_SITIO_A',
        @useself = N'false',
        @locallogin = NULL,
        @rmtuser = N'sa',
        @rmtpassword = N'<sa>';

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
