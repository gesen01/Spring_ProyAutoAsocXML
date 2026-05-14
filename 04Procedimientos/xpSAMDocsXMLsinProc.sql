SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--EXEC xpSAMDocsXMLsinProc 'SAM'
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpSAMDocsXMLsinProc')
DROP PROCEDURE xpSAMDocsXMLsinProc
GO
CREATE PROCEDURE xpSAMDocsXMLsinProc
@Empresa	VARCHAR(5)
AS
BEGIN
	

DECLARE @RutaRepositorio VARCHAR(255),
        @cmd            VARCHAR(500),
        @TotalRFC       INT,
        @Contador       INT=1,
        @TotalDocsXML	INT,
        @RFC			VARCHAR(15),
        @Ruta			VARCHAR(255)
        
DECLARE @RepositorioRFC TABLE(
	ID		INT IDENTITY(1,1) NOT NULL,
    RFC     VARCHAR(20)			NULL
)

DECLARE @DocsXML TABLE (                
        DocXML  VARCHAR(255)                 
)                

TRUNCATE TABLE SAMCantidadDocsXMLproc

SELECT @RutaRepositorio=RutaRepositorio  
FROM ConfigAsociacionXMLSAM                      
WHERE Empresa=@Empresa  

SELECT @cmd='DIR '+@RutaRepositorio+' /B'                      
                          
--Se lee la carpeta y se insertan el nombre de las carpetas (RFC) del repositorio                      
    INSERT INTO @RepositorioRFC(RFC)                      
    EXEC MASTER..xp_cmdshell @cmd    
    
IF EXISTS(SELECT 1 FROM @RepositorioRFC)
BEGIN
	
	SELECT @TotalRFC=COUNT(RFC)
	FROM @RepositorioRFC AS rr
	
	WHILE @Contador<=@TotalRFC
	BEGIN
		
		SELECT @RFC=RFC
		FROM @RepositorioRFC AS rr
		WHERE rr.ID=@Contador
		
		
		SELECT @Ruta=REPLACE(RutaRepositorioProc,'<rfc>',@RFC)                 
        FROM ConfigAsociacionXMLSAM                
        WHERE Empresa=@Empresa    
		
		SELECT @cmd='DIR '+@Ruta+' /B'  
		
		INSERT INTO @DocsXML(DocXML)                
			EXEC MASTER..xp_cmdshell @cmd
		
		 IF EXISTS(SELECT 1 FROM @DocsXML)
		  SELECT @TotalDocsXML=COUNT(DocXML)
		  FROM @DocsXML AS dx
		  
		 INSERT INTO SAMCantidadDocsXMLproc
		 SELECT @Empresa,@RFC,@TotalDocsXML
		 
		 DELETE FROM @DocsXML		
		
		SET @Contador=@Contador+1
	END
	
END
RETURN
END


