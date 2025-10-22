
SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--EXEC xpProcesaXMLSAM 'sam'
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpProcesaXMLSAM')
DROP PROCEDURE xpProcesaXMLSAM
GO

CREATE PROCEDURE xpProcesaXMLSAM              
   @Empresa  VARCHAR(10)          
AS                    
BEGIN                    
 DECLARE                 
 @cmd    VARCHAR(500),                    
    @Ruta    VARCHAR(255),                    
    @RutaValido   VARCHAR(255),                    
    @RutaInvalido  VARCHAR(255),                    
    @NumProv   INT,                    
    @ContProv   INT=1,                    
    @NumDocsxML   INT,                    
    @ContXML   INT,                    
    @RFC    VARCHAR(15),                    
    @Proveedor   VARCHAR(10),                    
    @DocXML    VARCHAR(150),                    
    @cmdSQL    VARCHAR(MAX),                    
    @Apostofre   VARCHAR(1),                    
    @RutaDocXML   VARCHAR(1500),                    
    @RutaDocPDF   VARCHAR(1500),                    
    @RutaProcXML  VARCHAR(1500),                    
    @RutaProcPDF  VARCHAR(1500),                    
    @CadenaXML   VARCHAR(MAX),                    
    @XML    XML,                    
    @Folio    VARCHAR(15),                    
    @UUID    VARCHAR(50),                    
    @Fecha    DATETIME,                    
    @TipoComprobante    VARCHAR(10),                    
    @Total    FLOAT,                    
    @NombreDocXML   VARCHAR(255),   
    @NombreDocPDF   VARCHAR(255),                 
    @RFCProv   VARCHAR(20),                    
    @OK     INT,                    
    @OKref    VARCHAR(255)                    
                        
DECLARE @ProvAcre    TABLE (                    
    ID    INT IDENTITY(1,1) NOT NULL,                    
    Proveedor  VARCHAR(10),                    
    RFC    VARCHAR(15)                    
)                    
                    
--Se crea tabla para almacenar nombre de los documentos xml                    
DECLARE @DocsXML TABLE (                    
        DocXML  VARCHAR(255)                     
)                    
                    
DECLARE @ArchivosXML    TABLE (                    
        ID              INT,                    
        eDocName      VARCHAR(255)                    
)                    
                    
CREATE TABLE #XMLData(                    
        DocXML  XML                    
)                    
                    
SELECT @Apostofre=CHAR(39)                    
                    
--Se insertan los RFC y proveedores a procesar               
INSERT INTO @ProvAcre                    
SELECT p.Proveedor,p.RFC                    
FROM Prov AS p             
WHERE p.RFC IS NOT NULL 
AND p.RFC <>''
UNION ALL                    
SELECT c.Cliente,c.RFC                    
FROM Cte AS c                    
WHERE c.RFC IS NOT NULL   
AND c.RFC<>''
          
          
--Se contabiliza cuantos proveedores se van a procesar                    
SELECT @NumProv=COUNT(p.Proveedor)                    
FROM @ProvAcre AS p                    
                    
--Se genera un ciclo que permitira procesar cada proveedor                    
WHILE @ContProv <= @NumProv                    
BEGIN                    
 SELECT @Proveedor=Proveedor                    
  ,@RFC=p.RFC                    
 FROM @ProvAcre AS p                    
 WHERE p.ID=@ContProv                    
                    
    --Se obtinene las ruta de las carpetas  a donde se procesaran los documentos XML                     
    SELECT @Ruta=REPLACE(RutaRepositorioProc,'<rfc>',@RFC)                    
          ,@RutaValido=REPLACE(RutaRepositorioVal,'<rfc>',@RFC)                    
          ,@RutaInvalido=REPLACE(RutaRepositorioInVal,'<rfc>',@RFC)                    
    FROM ConfigAsociacionXMLSAM                    
    WHERE Empresa=@Empresa                    
                  
 --SELECT  @Ruta=REPLACE(@Ruta,'Y:\','\\192.168.9.245\ArchCFD\Proveedores\')                    
 --         ,@RutaValido=REPLACE(@RutaValido,'Y:\','\\192.168.9.245\ArchCFD\Proveedores\')                    
 --         ,@RutaInvalido=REPLACE(@RutaInvalido,'Y:\','\\192.168.9.245\ArchCFD\Proveedores\')                   
         
    --Se arma la cadena para la lectura de la carpeta                     
    SELECT @cmd='DIR '+@Ruta+' /B'                    
                        
    --Se lee la carpeta y se insertan los documentos que se tienen                    
    INSERT INTO @DocsXML(DocXML)                    
    EXEC MASTER..xp_cmdshell @cmd                    
                        
    --Se insertan los documentos XML enumerados para su procesamiento                    
    INSERT INTO @ArchivosXML                    
    SELECT ROW_NUMBER() OVER (ORDER BY dx.DocXML), UPPER(SUBSTRING(dx.DocXML,CHARINDEX('.',dx.DocXML,1)+1,3))                    
    FROM @DocsXML AS dx                     
    WHERE dx.DocXML IS NOT NULL                    
    AND UPPER(SUBSTRING(dx.DocXML,CHARINDEX('.',dx.DocXML,1)+1,3))='XML'    
    
    --Inserta los documentos XML cuando estos tengan caracteres como punto en el nombre
    IF NOT EXISTS(SELECT 1 FROM @ArchivosXML)
    BEGIN
        WITH docsXml
        AS(
            SELECT DISTINCT REVERSE(RIGHT(REVERSE(dx.DocXML),LEN(dx.DocXML)-4))+'.xml' AS 'nombreinvertido',
                    REVERSE(RIGHT(REVERSE(dx.DocXML),LEN(dx.DocXML)-4)) As 'edocname'
            FROM @DocsXML AS dx
            WHERE dx.DocXML IS NOT NULL
        )
        INSERT INTO @ArchivosXML
        SELeCT ROW_NUMBER() OVER (ORDER BY nombreinvertido),edocname
        FRoM docsXml
    END                
                        
    --Se contabiliza cuantos documentos xml se tienen a procesar                    
    SELECT @NumDocsxML=COUNT(dx.ID)                    
    FROM @ArchivosXML AS dx                    
                           
    --Se asigna el contador para el ciclo que analizara y validara los XML en 1                       
    SET @ContXML=1                    
                        
    IF ISNULL(@NumDocsxML,0) > 0                    
    BEGIN                    
        --Se crea un ciclo para la validacion de cada xml que se tenga en la carpeta                    
        WHILE @ContXML <= @NumDocsxML                    
        BEGIN                    
            --Se genera el nombre de los documentos XML y PDF
            SELECT @NombreDocXML=eDocName+'.xml'
                   ,@NombreDocPDF=eDocName+'.PDF'
            FROM @ArchivosXML
            WHERE ID=@ContXML   
                   
            --Se obtienen las rutas de donde se encuetran los documentos XML y PDF asi como el nombre de los docs XML                    
            SELECT @RutaDocXML=@Ruta+'\'+@NombreDocXML                    
                   ,@RutaDocPDF=@Ruta+'\'+@NombreDocPDF                                     
            FROM @ArchivosXML AS dx                    
            WHERE dx.ID=@ContXML                    
                                
            --Se realiza la insercion de los datos en la tablan #XMLData de tipo XML                    
            SET @cmdSQL='INSERT INTO #XMLData                    
                                SELECT P                    
                                FROM OPENROWSET(BULK '+@Apostofre+@RutaDocXML+@Apostofre+', SINGLE_BLOB) AS Datos(P)'                    
              EXEC (@cmdSQL)                      
                                         
              BEGIN TRY
                  --Se asigna la variable con el texto del XML               
                  SELECT @CadenaXML=CAST(DocXML AS VARCHAR(MAX))            
                  FROM #XMLData      
                  
                  --Se eliminan caracteres invalidos tales como acentos
                  SELECT @CadenaXML=dbo.fneDocQuitarAcentos(@CadenaXML)
			  
                  --Se ejecuta la validacion del XML a fin de comprobar que el documento esta correcto               
                  EXEC xpValSAMXMLCFDI @Empresa,@CadenaXML,@OK OUTPUT,@OKref OUTPUT  

                  --Se ejecuta el validador de documentos XML que no cumplen los requisitos del primer validador
                  IF @OK IS NOT NULL
			      BEGIN
                     SELECT @ok=null,
						    @OKref=null
				 
				     EXEC xpSAMValidaCFDEsp @CadenaXML,@OK OUTPUT,@OKref OUTPUT                   
              
			      END
			      
			      IF @OK IS NULL
			      BEGIN
			           --Se reemplazan los prefijos del documento XML para que este sea leido y estructurado correctamente                    
                       SELECT @CadenaXML=dbo.fnSAMPrefijosXML(@CadenaXML)                    
                       --Se reasigna la variable XML con la cadena de tipo XML                    
                       SELECT @XML=CAST(@CadenaXML AS XML)    
			      END
			  END TRY
			  BEGIN CATCH
			        SELECT @OK=ERROR_NUMBER()
			              ,@OKRef=ERROR_MESSAGE() 
			  END CATCH
			               
               --Si el documento es correcto entonces se realiza una segunda comprobacion                    
              IF @OK IS NULL                    
              BEGIN                    
                               
                               
               --Se prepara el XML para su lectura                    
                DECLARE @hdoc int                    
                    EXEC sp_xml_preparedocument @hdoc OUTPUT,@XML                    
              
               --Se obtiene el UUID del documento XML                    
               SELECT @UUID=UUID                    
               FROM OPENXML (@hdoc, '/Comprobante/Complemento/TimbreFiscalDigital',1)                    
                   WITH (               
                        UUID      NVARCHAR(100)                    
                   )                    
                                   
                   SELECT @Fecha= Fecha                    
                         ,@TipoComprobante=TipoDeComprobante                    
                         ,@Total=Total                    
                         ,@Folio=Folio                    
                   FROM OPENXML (@hdoc, '/Comprobante',1)                    
                   WITH (                    
                        Folio               VARCHAR(100),                    
                        Fecha               DATETIME,                    
                        TipoDeComprobante   VARCHAR(100),                    
                        Total               FLOAT                    
                   )                    
                                   
                   SELECT @RFCProv=RFC                    
                   FROM OPENXML (@hdoc, '/Comprobante/Emisor',1)                    
                   WITH (                  
                        Rfc   VARCHAR(30)                    
                   )                    
                                                                    
                   --Se realiza la validacion para saber si existe el UUID en la tabla SATXML se mueve a validados y se inserta en la tabla de datos                    
                   IF EXISTS(SELECT 1 FROM SatXml AS sx WHERE sx.FolioFiscal=@UUID)                    
                   BEGIN                    
                                       
                        SET @RutaProcXML=@RutaValido+'\'+@NombreDocXML                    
                        SET @RutaProcPDF=@RutaValido+'\'+@NombreDocPDF                    
                
                    --Se insertan datos en la tabla a utilizar oara la asocioacion de movimientos                    
                    INSERT INTO AsociadoXMLSAM(Nombre,Folio,Importe,RFC,Tipo,UUID,FechaTimbrado,FechaRegistro,Asociado)                    
                                    SELECT @NombreDocXML,@Folio,@Total,@RFCProv,@TipoComprobante,@UUID,@Fecha,CAST(GETDATE() AS DATE),0                    
                                
                    --Se copian los documentos PDF y XML a la carpeta de validos                    
                    SET @CMD='COPY '+@RutaDocXML+' '+@RutaProcXML                    
                        EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                     
                        SET @CMD='DEL '+@RutaDocXML                    
                        EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                    
                                            
                        SET @CMD='COPY '+@RutaDocPDF+' '+@RutaProcPDF                    
                        EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                     
                        SET @CMD='DEL '+@RutaDocPDF                    
                        EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                     
                                        
                                        
                    --Se insertan los valores de exitos en la tabla de registro de errores                    
                    IF NOT EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Nombre=@NombreDocXML)                     
                        INSERT INTO AsocXMLSAMLog(Nombre,Proveedor, FechaExpedicion,Estatus, Descripcion, FechaProceso)                    
                                      SELECT @NombreDocXML,@Proveedor,@Fecha,'Procesado','Procesado con exito',GETDATE()            
                    ELSE          
                       UPDATE AsocXMLSAMLog SET Estatus='Procesado'          
                                           ,Descripcion='Procesado con exito'          
                                           ,FechaProceso=GETDATE()          
                                           WHERE Nombre=@NombreDocXML          
                                         
                   END                    
                   ELSE    
                   BEGIN     
                     --Valida que el tipo de comprobante sea un complemento de pago, carta porte y no exista su UUID en la tabla de SATXML       
                        IF @TipoComprobante IN ('T','P','E')    
                        BEGIN    
                         SET @RutaProcXML=@RutaValido+'\'+@NombreDocXML                  
                            SET @RutaProcPDF=@RutaValido+'\'+@NombreDocPDF                  
              
                            --Se insertan datos en la tabla a utilizar oara la asocioacion de movimientos                  
                            INSERT INTO AsociadoXMLSAM(Nombre,Folio,Importe,RFC,Tipo,UUID,FechaTimbrado,FechaRegistro,Asociado)                  
                                            SELECT @NombreDocXML,@Folio,@Total,@RFCProv,@TipoComprobante,@UUID,@Fecha,CAST(GETDATE() AS DATE),0                  
                              
                            --Se copian los documentos PDF y XML a la carpeta de validos                  
                            SET @CMD='COPY '+@RutaDocXML+' '+@RutaProcXML                  
                                EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                   
                                SET @CMD='DEL '+@RutaDocXML                  
                                EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                  
                                          
                                SET @CMD='COPY '+@RutaDocPDF+' '+@RutaProcPDF                  
                                EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                   
                                SET @CMD='DEL '+@RutaDocPDF                  
                                EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                   
                                      
                                      
                            --Se insertan los valores de exitos en la tabla de registro de errores                  
                            IF NOT EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Nombre=@NombreDocXML)                   
                                INSERT INTO AsocXMLSAMLog(Nombre,Proveedor, FechaExpedicion,Estatus, Descripcion, FechaProceso)                  
                                              SELECT @NombreDocXML,@Proveedor,@Fecha,'Procesado','Procesado con exito',GETDATE()          
                          ELSE        
                            UPDATE AsocXMLSAMLog SET Estatus='Procesado'        
                                                    ,Descripcion='Procesado con exito'        
                                                    ,FechaProceso=GETDATE()        
                                                WHERE Nombre=@NombreDocXML      
                        END    
                        ELSE    
                        BEGIN    
                          SET @RutaProcXML=@RutaInValido+'\'+@NombreDocXML                    
                          SET @RutaProcPDF=@RutaInValido+'\'+@NombreDocPDF                    
                                        
                          --Se copian los documentos PDF y XML a la carpeta de invalidos                    
                          SET @CMD='COPY '+@RutaDocXML+' '+@RutaProcXML                    
                          EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                     
                          SET @CMD='DEL '+@RutaDocXML                    
                          EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                    
                                            
                          SET @CMD='COPY '+@RutaDocPDF+' '+@RutaProcPDF                    
                          EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                     
                          SET @CMD='DEL '+@RutaDocPDF                    
                          EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                     
                                        
                      --Se insertan los valores de exitos en la tabla de registro de errores                    
                      IF NOT EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Nombre=@NombreDocXML)                                              
                          INSERT INTO AsocXMLSAMLog(Nombre,Proveedor,FechaExpedicion, Estatus, Descripcion, FechaProceso)                    
                           SELECT @NombreDocXML,@Proveedor,@Fecha,'NoProcesado','No se encuentra disponible en la tabla de SATXML',GETDATE()         
                            ELSE        
                             UPDATE AsocXMLSAMLog SET Descripcion='No se encuentra disponible en la tabla de SATXML'        
                             ,Estatus='NoProcesado'        
                             ,FechaProceso=GETDATE()        
                             WHERE Nombre=@NombreDocXML     
             
                          SELECT @OK=NULL,    
                                @OKref=NULL    
                  END    
                 END    
              END                    
              ELSE                    
              BEGIN                    
                    SET @RutaProcXML=@RutaInValido+'\'+@NombreDocXML                    
                    SET @RutaProcPDF=@RutaInValido+'\'+@NombreDocPDF                    
                                        
                    --Se copian los documentos PDF y XML a la carpeta de invalidos                    
                    SET @CMD='COPY '+@RutaDocXML+' '+@RutaProcXML                    
                    EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                     
                    SET @CMD='DEL '+@RutaDocXML                    
                    EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                    
                                            
                    SET @CMD='COPY '+@RutaDocPDF+' '+@RutaProcPDF                    
                    EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                     
                    SET @CMD='DEL '+@RutaDocPDF                    
                    EXEC MASTER..xp_cmdshell   @CMD, NO_OUTPUT                     
                                        
                --Se insertan los valores de exitos en la tabla de registro de errores                    
                IF NOT EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Nombre=@NombreDocXML)                     
                    INSERT INTO AsocXMLSAMLog(Nombre,Proveedor,FechaExpedicion, Estatus, Descripcion, FechaProceso)                    
                                       SELECT @NombreDocXML,@Proveedor,@Fecha,'NoProcesado',CAST(@OK AS VARCHAR(10))+' '+ISNULL(@OKRef,''),GETDATE()            
                ELSE            
                   UPDATE AsocXMLSAMLog SET Descripcion = CAST(@OK AS VARCHAR(10))+' '+ISNULL(@OKRef,'')            
                                            ,FechaProceso = GETDATE()            
                   WHERE Nombre=@NombreDocXML            
        
                SELECT @OK=NULL,    
                    @OKref=NULL    
          
              END                      
              TRUNCATE TABLE #XMLdata                    
                              
            SET @ContXML=@ContXML+1                    
        END                     
    END                    
                        
 DELETE FROM @DocsXML                    
 DELETE FROM @ArchivosXML                    
                     
 SET @ContProv=@ContProv+1                    
END                    
                    
     -- Liberamos memoria de la lectura del xml                    
     IF @hdoc IS NOT NULL                    
EXEC sp_xml_removedocument @hdoc                    
                    
RETURN                    
END 