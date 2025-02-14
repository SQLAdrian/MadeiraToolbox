:setvar CertificateName AutoBackup_Certificate
:setvar CertificateDescription "Automatic Backup Certificate"
:setvar MasterKeyPassword paste_password_here
:setvar CertificatePassword paste_password_here
:setvar BackupFolderPath c:\temp\
:setvar NewExpiryDate 20991231
USE [master]
GO
SET NOCOUNT, ARITHABORT, XACT_ABORT ON;
DECLARE @ToDate VARCHAR(10), @CertificateFromDate VARCHAR(10), @PKeyFromDate VARCHAR(10)

SET @ToDate = CONVERT(nvarchar(10), GETDATE(), 112);

SELECT @CertificateFromDate = CONVERT(nvarchar(10), [start_date], 112), @PKeyFromDate = CONVERT(nvarchar(10), pvt_key_last_backup_date, 112)
FROM sys.certificates
WHERE [name] = '$(CertificateName)'

SELECT @CertificateFromDate AS [@CertificateFromDate], @PKeyFromDate AS [@PKeyFromDate], @ToDate AS [@ToDate], '$(NewExpiryDate)' AS [NewExpiryDate]

RAISERROR(N'Opening master key...',0,1) WITH NOWAIT;
OPEN MASTER KEY DECRYPTION BY PASSWORD = '$(MasterKeyPassword)';

DECLARE @CMD NVARCHAR(MAX), @Path NVARCHAR(4000), @Path2 NVARCHAR(4000)

SET @Path = '$(BackupFolderPath)$(CertificateName)_' + @CertificateFromDate + '_' + @ToDate + '.cer'
SET @Path2 = '$(BackupFolderPath)$(CertificateName)_' + @PKeyFromDate + '_' + @ToDate + '.pkey'

RAISERROR(N'Backing up certificate to: %s',0,1,@Path) WITH NOWAIT;
RAISERROR(N'Backing up certificate private key to: %s',0,1,@Path2) WITH NOWAIT;

SET @CMD = N'BACKUP CERTIFICATE [$(CertificateName)] TO FILE = ' + QUOTENAME(@Path, '''') + N'
    WITH PRIVATE KEY ( 
    FILE = ' + QUOTENAME(@Path2, '''') + N' ,   
    ENCRYPTION BY PASSWORD = ''$(CertificatePassword)'' );  '

EXEC (@CMD);
	
RAISERROR(N'Dropping old certificate...',0,1) WITH NOWAIT;
DROP CERTIFICATE [$(CertificateName)];

RAISERROR(N'Creating new certificate...',0,1) WITH NOWAIT;

CREATE CERTIFICATE [$(CertificateName)]   
   WITH SUBJECT = '$(CertificateDescription)',   
   EXPIRY_DATE = '$(NewExpiryDate)'; 
   
   
SET @Path = '$(BackupFolderPath)$(CertificateName)_' + @ToDate + '_$(NewExpiryDate).cer'
SET @Path2 = '$(BackupFolderPath)$(CertificateName)_' + @ToDate + '_$(NewExpiryDate).pkey'

RAISERROR(N'Backing up NEW certificate to: %s',0,1,@Path) WITH NOWAIT;
RAISERROR(N'Backing up NEW certificate private key to: %s',0,1,@Path2) WITH NOWAIT;

SET @CMD = N'BACKUP CERTIFICATE [$(CertificateName)] TO FILE = ' + QUOTENAME(@Path, '''') + N'
    WITH PRIVATE KEY ( 
    FILE = ' + QUOTENAME(@Path2, '''') + N' ,   
    ENCRYPTION BY PASSWORD = ''$(CertificatePassword)'' );  '

EXEC (@CMD);

CLOSE MASTER KEY;

PRINT N'Done.'
GO