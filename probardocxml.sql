DECLARE @xml	VARCHAR(MAX),
		@CadenaSQL VARCHAR(MAX),
		@Apostofre VARCHAR(1),
		@RutaDoc   VARCHAR(MAX),
		@ok		INT,
		@okref	VARCHAR(255)
CREATE TABLE #XMLData(
        DocXML  XML
    )	
    
SELECT @RutaDoc='D:\DesarrolloPST\SpringAir\Scripts\ProyCargaXMLAsocAut\DocsXML\F34957.xml'
	  ,@Apostofre=CHAR(39)
	  
SET @CadenaSQL='INSERT INTO #XMLData
                            SELECT P
                            FROM OPENROWSET(BULK '+@Apostofre+@RutaDoc+@Apostofre+', SINGLE_BLOB) AS Datos(P)'
EXEC (@CadenaSQL)

SELECT @xml=CAST(x.DocXML AS VARCHAR(MAX))
FROM #XMLData AS x
	
EXEC xpSAMValidaCFDEsp @xml,@ok OUTPUT,@okref OUTPUT

--EXEC xpValSAMXMLCFDI 'SHMEX',@xml,@ok OUTPUT,@okref OUTPUT

SELECT @ok
DROP TABLE #xmldata