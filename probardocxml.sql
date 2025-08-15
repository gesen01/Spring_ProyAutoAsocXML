DECLARE @xml	VARCHAR(MAX),
		@CadenaSQL VARCHAR(MAX),
		@Apostofre VARCHAR(1),
		@RutaDoc   VARCHAR(MAX),
		@encode		VARCHAR(50),
		@docXML		XML,
		@ok		INT,
		@okref	VARCHAR(255)

DECLARE @value  AS VARCHAR(MAX) = '%[^a-z A-Z 0-9 </>=:?",.]%'

SET @encode='<?xml version="1.0" encoding="utf-8"?>'
CREATE TABLE #XMLData(
        DocXML  XML
    )	
    
SELECT @RutaDoc='D:\DesarrolloPST\SpringAir\Scripts\ProyCargaXMLAsocAut\DocsXML\F34488.xml'
	  ,@Apostofre=CHAR(39)
	  
SET @CadenaSQL='INSERT INTO #XMLData
                            SELECT P
                            FROM OPENROWSET(BULK '+@Apostofre+@RutaDoc+@Apostofre+', SINGLE_BLOB) AS Datos(P)'
                            
                            
EXEC (@CadenaSQL)


BEGIN TRY
	SELECT @xml=CAST(x.DocXML AS VARCHAR(MAX)) 
	FROM #XMLData AS x
	
	--SELECT LEFT(@xml,2280)
	
	SELECT @xml=dbo.fneDocQuitarAcentos(@xml)
	
	SELECT @docXML=@encode+@xml
	
	SELECT LEFT(CAST(@docXML AS VARCHAR(MAX)),2280)
	
	SELECT @docXML	
	
	--EXEC xpSAMValidaCFDEsp @xml,@ok OUTPUT,@okref OUTPUT
	--SELECT @ok,@okref	
	
	EXEC xpValSAMXMLCFDI 'SHMEX',@xml,@ok OUTPUT,@okref OUTPUT
	SELECT @ok,@okref
END TRY
BEGIN CATCH
		SELECT
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_MESSAGE() AS ErrorMessage

END CATCH

DROP TABLE #xmldata