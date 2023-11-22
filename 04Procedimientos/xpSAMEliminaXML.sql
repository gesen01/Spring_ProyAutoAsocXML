SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--exec xpSAMEliminaXML 2,'SHMEX'
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpSAMEliminaXML')
DROP PROCEDURE xpSAMEliminaXML
GO
CREATE PROCEDURE xpSAMEliminaXML
@Estacion	  INT,
@Empresa	  VARCHAR(10)
AS
BEGIN
	
	DECLARE @Contador	   INT=1,
		   @TotalXML	   INT,
		   @Consecutivo   INT,
		   @DocumentoXML  VARCHAR(255),
		   @RFC		   VARCHAR(30),
		   @RutaInvalido   VARCHAR(255),
		   @RutaDocXML	VARCHAR(1500),
		   @RutaDocPDF VARCHAR(1500),
		   @CMD		VARCHAR(500)	 
	
	DECLARE @DocsXML TABLE (
		  ID			   INT IDENTITY(1,1) NOT NULL,
		  Consecutivo	   INT
	)
	
	DECLARE @ProvAcre    TABLE (
	   ID		 INT IDENTITY(1,1) NOT NULL,
	   Proveedor	 VARCHAR(10),
	   RFC		 VARCHAR(15)
	)
	
	INSERT INTO @ProvAcre
	   SELECT p.Proveedor,p.RFC
	   FROM Prov AS p
	   WHERE p.RFC IS NOT NULL
	   UNION ALL
	   SELECT c.Cliente,c.RFC
	   FROM Cte AS c
	   WHERE c.RFC IS NOT NULL
	   
	INSERT INTO @DocsXML
	   SELECT ID 
	   FROM ListaID
	   WHERE Estacion=@Estacion
	
	
	SELECT @TotalXML=COUNT(dx.ID)
	FROM @DocsXML AS dx
			
	IF ISNULL(@TotalXML,0)<>0
	BEGIN
	   WHILE  @Contador <= @TotalXML
	   BEGIN
		  SELECT @Consecutivo=Consecutivo
		  FROM @DocsXML AS dx
		  WHERE ID=@Contador
		  
		  SELECT @DocumentoXML=a.Nombre,
			    @RFC=p.RFC
		  FROM AsocXMLSAMLog a
		  JOIN @ProvAcre AS p ON p.Proveedor=a.Proveedor
		  WHERE a.ID=@Consecutivo
		  
		  SELECT @RutaInvalido=REPLACE(RutaRepositorioInVal,'<rfc>',@RFC)
		  FROM ConfigAsociacionXMLSAM
		  WHERE Empresa=@Empresa
		  
		  SET @RutaDocXML=@RutaInvalido+'\'+@DocumentoXML
            SET @RutaDocPDF=@RutaInvalido+'\'+SUBSTRING(@DocumentoXML,1,CHARINDEX('.',@DocumentoXML,1))+'PDF'
		  		  
		  DELETE FROM AsocXMLSAMLog WHERE ID=@Consecutivo
		  
		  SET @CMD='DEL '+@RutaDocXML
            EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT	
            
            SET @CMD='DEL '+@RutaDocPDF
            EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT 
	   	
	   	SET @Contador=@Contador+1	
	   END	
	END   
	
RETURN
END