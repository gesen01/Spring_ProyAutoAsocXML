SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpSAMAsociarDocs')
DROP PROCEDURE xpSAMAsociarDocs
GO
CREATE PROCEDURE xpSAMAsociarDocs
@ID		  INT,
@Estacion	  INT,
@Modulo	  VARCHAR(10),
@RFC		  VARCHAR(20),
@Empresa	  VARCHAR(5),
@Sucursal	  INT
AS
BEGIN
	DECLARE @Archivo	VARCHAR(150),
		   @AlmacenarXML  BIT,
		   @AlmacenarPDF  BIT,
		   @Ejercicio	   VARCHAR(5),
		   @Periodo	   VARCHAR(3),
		   @Ruta		VARCHAR(150),
		   @RutaValidos   VARCHAR(150),
		   @RutaValidar   VARCHAR(150),
		   @RutaProcXML   VARCHAR(500),
		   @RutaProcPDF   VARCHAR(500),
		   @RutaDocXML	   VARCHAR(500),
		   @RutaDocPDF	   VARCHAR(500),
		   @cmd		   VARCHAR(500),
		   @Contador	   INT=1,
		   @NumArchivos   INT,
		   @OK		   INT,
		   @OKRef		   VARCHAR(500),
		   @Existe	   BIT
		   
	DECLARE @Documentos	   TABLE(
		  ID			   INT IDENTITY(1,1)	NOT NULL,
		  Documento	   VARCHAR(150)
	)
		   
	 SELECT @AlmacenarXML=ISNULL(AlmacenarXML,0)
	       ,@AlmacenarPDF=ISNULL(AlmacenarPDF,0)
	       ,@Ruta=RutaAsoc
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
	 
	 
	 IF @Ruta IS NULL
	   SELECT @OK=100010,
			@OKRef='No se ha difinido la ruta de almacenamiento de documentos'
	
	 IF @OK IS NULL AND @Modulo IN ('COMS','GAS','DIN','CXC','CXP')
	 BEGIN
	 	
	 	--Se reemplaza la etiqueta rfc de la ruta de documentos validos por el frc del proveedor o acreedor
	 	SET @RutaValidos=REPLACE(@RutaValidos,'<rfc>',@RFC)
	 	
	 	--Se reemplza la etiqueta modulo con las siglas del rfc a asociar
	 	SET @Ruta=REPLACE(@Ruta,'<rfc>',@RFC)
	 	
	 	--Se extrae la ruta en donde se incluye la ubicacion de la carpeta del modulo
	 	SET @RutaValidar=SUBSTRING(@Ruta,1,LEN(@Ruta)-LEN('<ejercicio>\<periodo>'))
	 	
	 	--Se valida que la ruta a validar tenga datos para validar que exista la carpeta
	 	IF LEN(@RutaValidar) > 0
	 	  EXEC spFolderExiste @RutaValidar,@Existe OUTPUT,@Ok OUTPUT,@OkRef OUTPUT
	 	   	
	 	--Si la carpeta del rfc no existe se crea
	 	IF @Existe=0 AND @OK IS NULL
	 	  EXEC spCrearDirectorio @RutaValidar,@Ok OUTPUT,@OkRef OUTPUT
	 	  
	 	--se sustituye la etiqueta <ejercicio> con el ejercicio correspondiente
	 	SET @Ruta=REPLACE(@Ruta,'<ejercicio>',@Ejercicio)
	 	SET @RutaValidar=SUBSTRING(@Ruta,1,LEN(@Ruta)-LEN('<periodo>'))
	 	
	 	--Se valida que la ruta a validar tenga datos para validar que exista la carpeta
	 	IF LEN(@RutaValidar) > 0
	 	  EXEC spFolderExiste @RutaValidar,@Existe OUTPUT,@Ok OUTPUT,@OkRef OUTPUT
	 	   	
	 	--Si la carpeta del rfc no existe se crea
	 	IF @Existe=0 AND @OK IS NULL
	 	  EXEC spCrearDirectorio @RutaValidar,@Ok OUTPUT,@OkRef OUTPUT
	 	
	 	--se sustituye la etiqueta <periodo> con el periodo correspondiente
	 	SET @Ruta=REPLACE(@Ruta,'<periodo>',@Periodo)
	 	
	 	--Se valida que exista la carpeta con el ejercicio del proveedor o acreedor
	 	  EXEC spFolderExiste @Ruta,@Existe OUTPUT,@Ok OUTPUT,@OkRef OUTPUT
	 	
	 	--Si la carpeta del ejercicio no existe se crea
	 	IF @Existe=0 AND @OK IS NULL
	 	  EXEC spCrearDirectorio @Ruta,@Ok OUTPUT,@OkRef OUTPUT
	 	
	 	--Se llena la tabla con los documentos seleccionados desde la pantalla de la herramienta 		 
		INSERT INTO @Documentos
		SELECT Clave
		FROM ListaSt AS ls
		WHERE ls.Estacion=@Estacion
		
		SELECT @NumArchivos=COUNT(d.ID)
		FROM @Documentos AS d
				
		IF @NumArchivos > 0 AND @OK IS NULL
		BEGIN
			WHILE @Contador <=@NumArchivos
			BEGIN
				
				SELECT @Archivo=Documento
				FROM @Documentos AS d
				WHERE d.ID=@Contador
				
				--Se asigna la ruta destino de los documentos XML y PDF
				SET @RutaDocXML=@Ruta+'\'+@Archivo
				SET @RutaDocPDF=@Ruta+'\'+SUBSTRING(@Archivo,1,CHARINDEX('.',@Archivo,1))+'PDF'
				
				--Se asigna la ruta origen de los documentos XML y pdf
				SET @RutaProcXML=@RutaValidos+'\'+@Archivo
                    SET @RutaProcPDF=@RutaValidos+'\'+SUBSTRING(@Archivo,1,CHARINDEX('.',@Archivo,1))+'PDF'
                   
                    --Se valida que se tenga prendido el bit para almacenar XML y copiarlo a la carpeta 
                    IF @AlmacenarXML <> 0
                    BEGIN
				     SET @CMD='COPY '+@RutaProcXML+' '+@RutaDocXML
					EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT 
				     SET @CMD='DEL '+@RutaProcXML
				     EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT      
				     
				     INSERT INTO AnexoMov(Rama, ID, Nombre, Direccion, Icono,Tipo,Sucursal)
							    SELECT @Modulo,@ID,SUBSTRING(@Archivo,1,CHARINDEX('.',@Archivo,1)-1),@RutaDocXML,'66','Archivo',@Sucursal        	
                    END
                    
                    --Se valida que se tenga prendido el bit para almacenar PDF y copiarlo a la carpeta 
				IF @AlmacenarPDF <> 0
				BEGIN
			
				    SET @CMD='COPY '+@RutaProcPDF+' '+@RutaDocPDF
				    EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT 
				    SET @CMD='DEL '+@RutaProcPDF
				    EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT 
				    
				    INSERT INTO AnexoMov(Rama, ID, Nombre, Direccion, Icono,Tipo,Sucursal)
							    SELECT @Modulo,@ID,SUBSTRING(@Archivo,1,CHARINDEX('.',@Archivo,1)-1),@RutaDocPDF,'66','Archivo',@Sucursal        			
				END
											
				UPDATE AsociadoXMLSAM SET Asociado=1
				WHERE Nombre=@Archivo
                        
				SET @Contador=@Contador+1
			END
		END
		
		IF @OK IS NOT NULL
		  SELECT CAST(@OK AS VARCHAR(15))+' - '+@OKRef
		ELSE
		  SELECT 'Proceso Concluido'
		  
	 
	 END
	   
	 
	
	/*Logica del procedimiento Intelisis*/
RETURN
END