/*
    EJECUTAR EN LA MAQUINA DEL SITIO A.

    Servidor remoto confirmado:
      Maquina/instancia: XABI\SITIOB
      IP Tailscale: 100.87.218.93
      Puerto TCP: 1441

    Reemplace <CONTRASENA_SA_SITIO_B> por la clave real de sa en Sitio B.

    No use localhost: Sitio B esta en otra maquina de la red Tailscale.
*/

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.servers WHERE name = N'LS_SITIO_B')
BEGIN
    EXEC master.dbo.sp_addlinkedserver
        @server = N'LS_SITIO_B',
        @srvproduct = N'',
        @provider = N'SQLNCLI',
        @datasrc = N'100.87.218.93,1441',
        @provstr = N'encrypt=yes;trustservercertificate=yes';

    EXEC master.dbo.sp_addlinkedsrvlogin
        @rmtsrvname = N'LS_SITIO_B',
        @useself = N'false',
        @locallogin = NULL,
        @rmtuser = N'sa',
        @rmtpassword = N'sa';

    EXEC master.dbo.sp_serveroption
        @server = N'LS_SITIO_B',
        @optname = N'data access',
        @optvalue = N'true';
END;
GO

EXEC master.dbo.sp_testlinkedserver N'LS_SITIO_B';

SELECT * FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DIAGNOSTICO_SB];
SELECT * FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[DOCTOR_SB];
SELECT * FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB];
GO
