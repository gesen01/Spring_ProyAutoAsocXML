SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpSAMDesasociaXML')
DROP PROCEDURE xpSAMDesasociaXML
GO
CREATE PROCEDURE xpSAMDesasociaXML
@ID		  INT,
@Nombre	  VARCHAR(255),
@RFC		  VARCHAR(30),
@Modulo	  VARCHAR(5),
@Empresa	  VARCHAR(5)
AS
BEGIN
	
	DECLARE @Ruta		   VARCHAR(150),
		   @RutaValidos   VARCHAR(150),
		   @RutaValidar   VARCHAR(150),
		   @RutaProcXML   VARCHAR(500),
		   @RutaProcPDF   VARCHAR(500),
		   @RutaDocXML	   VARCHAR(500),
		   @RutaDocPDF	   VARCHAR(500),
		   @cmd		   VARCHAR(500),
		   @Ejercicio	   VARCHAR(5),
		   @Periodo	   VARCHAR(3)
		   
	SELECT @Ruta=RutaAsoc
	      ,@RutaValidos=RutaRepositorioVal
	 FROM ConfigAsociacionXMLSAM
	 WHERE Empresa=@Empresa
	 
	 IF @Modulo='COMS'
		SELECT @Ejercicio=CAST(YEAR(FechaEmision) AS VARCHAR(5))
			 ,@Periodo=CAST(MONTH(FechaEmision) AS VARCHAR(3))
		FROM Compra AS c
		WHERE c.ID=@ID
	
	IF @Modulo='GAS'
		SELECT @Ejercicio=CAST(YEAR(FechaEmision) AS VARCHAR(5))
			 ,@Periodo=CAST(MONTH(FechaEmision) AS VARCHAR(3))
		FROM Gasto AS c
		WHERE c.ID=@ID
	
	IF @Modulo='CXC'
		SELECT @Ejercicio=CAST(YEAR(FechaEmision) AS VARCHAR(5))
			 ,@Periodo=CAST(MONTH(FechaEmision) AS VARCHAR(3))
		FROM Cxc AS c
		WHERE c.ID=@ID
		
	IF @Modulo='CXP'
		SELECT @Ejercicio=CAST(YEAR(FechaEmision) AS VARCHAR(5))
			 ,@Periodo=CAST(MONTH(FechaEmision) AS VARCHAR(3))
		FROM Cxp AS c
		WHERE c.ID=@ID
		
	IF @Modulo='DIN'
		SELECT @Ejercicio=CAST(YEAR(FechaEmision) AS VARCHAR(5))
			 ,@Periodo=CAST(MONTH(FechaEmision) AS VARCHAR(3))
		FROM Dinero AS c
		WHERE c.ID=@ID
	 
	 --Se reemplaza la etiqueta rfc de la ruta de documentos validos por el frc del proveedor o acreedor
	 SET @RutaValidos=REPLACE(@RutaValidos,'<rfc>',@RFC)
	 
	 --se sustituye la etiqueta <rfc> con el rfc del proveedor o acreedor al que se asocian sus documentos
	 SET @Ruta=REPLACE(@Ruta,'<rfc>',@RFC)
	 
	 --Se reemplaza la etiqueta con ejercicio correspondiente
	 SET @Ruta=REPLACE(@Ruta,'<ejercicio>',@Ejercicio)
	 
	  --Se reemplaza la etiqueta con ejercicio correspondiente
	 SET @Ruta=REPLACE(@Ruta,'<periodo>',@Periodo)
	
	IF EXISTS(SELECT 1 FROM AsociadoXMLSAM WHERE LOWER(Nombre)=LOWER(@nombre)+'.xml')
	BEGIN
	    --Se borra del anexomov el archivo xml y pdf
	    DELETE FROM AnexoMov WHERE ID=@ID AND Rama=@Modulo AND Nombre=@Nombre
	
	    --Se actualiza el documento xml asociado en 0 para que este disponible nuevamente
	    UPDATE AsociadoXMLSAM SET Asociado=0
	    WHERE LOWER(Nombre)=LOWER(@Nombre)+'.xml'
	
	    --Se regresa los ocumentos a su posicion original
	    --Se asigna la ruta destino de los documentos XML y PDF
	    SET @RutaDocXML=@Ruta+'\'+@Nombre+'.xml'
	    SET @RutaDocPDF=@Ruta+'\'+@Nombre+'.PDF'
				
	    --Se asigna la ruta origen de los documentos XML y pdf
	    SET @RutaProcXML=@RutaValidos+'\'+@Nombre+'.xml'
	    SET @RutaProcPDF=@RutaValidos+'\'+@Nombre+'.PDF'
	
		SET @CMD='COPY '+@RutaDocXML+' '+@RutaProcXML
		EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT 
		SET @CMD='DEL '+@RutaDocXML
		EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT 
     
		SET @CMD='COPY '+@RutaDocPDF+' '+@RutaProcPDF
		EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT 
		SET @CMD='DEL '+@RutaDocPDF
		EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT 
	END
	
RETURN
END