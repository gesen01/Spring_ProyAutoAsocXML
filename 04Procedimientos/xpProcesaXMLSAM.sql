SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--EXEC xpProcesaXMLSAMDebug 'sam',1
IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpProcesaXMLSAM') 
DROP PROCEDURE xpProcesaXMLSAM
GO
CREATE PROCEDURE [dbo].[xpProcesaXMLSAM]         
   @Empresa  VARCHAR(10)      
AS                
BEGIN                
 DECLARE    @cmd    VARCHAR(500),                
            @Ruta    VARCHAR(255),                
            @RutaValido   VARCHAR(255),                
            @RutaInvalido  VARCHAR(255),                  
            @RutaRepositorio    VARCHAR(255),  
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
            @NombreDoc   VARCHAR(255),                
            @RFCProv   VARCHAR(20),                
            @OK     INT,                
            @OKref    VARCHAR(255),  
            @hdoc     INT,  
            @ClaveCancelacion   VARCHAR(10),  
            @XMLCancelado   VARCHAR(MAX),
            @NombreTieneEspacio INT
                 
                    
DECLARE @ProvAcre    TABLE (  
    Proveedor  VARCHAR(10),                      
    RFC    VARCHAR(15)                      
)      
  
DECLARE @RepositorioRFC   TABLE (                
    RFC    VARCHAR(15)                      
)  
  
DECLARE @ProveedoresRFC TABLE(  
    ID              INT IDENTITY(1,1) NOT NULL,  
    Proveedor       VARCHAR(15),  
    RFC             VARCHAR(15)  
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
        DocXML  xml                
)         
  

               
SELECT @Apostofre=CHAR(39)         
  
--Se obtiene la ruta del repositorio general  
SELECT @RutaRepositorio=RutaRepositorio  
FROM ConfigAsociacionXMLSAM                      
WHERE Empresa=@Empresa    
  
--Se arma la cadena para la lectura de la carpeta                       
SELECT @cmd='DIR '+@RutaRepositorio+' /B'                      
                          
--Se lee la carpeta y se insertan el nombre de las carpetas (RFC) del repositorio                      
    INSERT INTO @RepositorioRFC(RFC)                      
    EXEC MASTER..xp_cmdshell @cmd    
                
--Se insertan los RFC y proveedores a procesar                   
    INSERT INTO @ProvAcre  
    SELECT p.Proveedor,p.RFC                
    FROM Prov AS p         
    WHERE p.RFC IS NOT NULL  
    And p.Estatus='Alta'
    AND EXISTS(SELECT 1 FROM @RepositorioRFC r WHERE r.RFC=p.RFC)  
    UNION ALL                
    SELECT c.Cliente,c.RFC                
    FROM Cte AS c                
    WHERE c.RFC IS NOT NULL   
    And c.Estatus='Alta'
    AND EXISTS(SELECT 1 FROM @RepositorioRFC r WHERE r.RFC=c.RFC)  

      
--Se llena toda la tabla de proveedores asignados y sin asignar   
    IF NOT EXISTS(SELECT 1 FROM SAMCantidadDocsXMLproc WHERE NumDocs > 0)
        INSERT INTO @ProveedoresRFC  
        SELECT p.Proveedor   
              ,p.RFC  
        FROM @ProvAcre p  
        UNION   
        SELECT 'SINASIGNAR'  
              ,r.RFC  
        FROM @RepositorioRFC r  
        WHERE NOT EXISTS(SELECT 1 FROM @ProvAcre p WHERE p.RFC=r.RFC)   
        AND r.RFC IS NOT NULL
    ELSE
        INSERT INTO @ProveedoresRFC
         SELECT p.Proveedor   
              ,p.RFC  
        FROM @ProvAcre p
        WHERE EXISTS(SELECT 1 FROM SAMCantidadDocsXMLproc s WHERE p.RFC=s.RFC AND NumDocs > 0)
        UNION   
        SELECT 'SINASIGNAR'  
              ,r.RFC  
        FROM @RepositorioRFC r  
        WHERE EXISTS(SELECT 1 FROM SAMCantidadDocsXMLproc s WHERE r.RFC=s.RFC AND NumDocs > 0)  
        AND NOT EXISTS(SELECT 1 FROM @ProvAcre p WHERE p.RFC=r.RFC) 
        AND r.RFC IS NOT NULL
                          
--Se contabiliza cuantos proveedores se van a procesar                
SELECT @NumProv=COUNT(p.rfc)                      
FROM @ProveedoresRFC AS p        
  
--Se genera un ciclo que permitira procesar cada proveedor                
WHILE @ContProv <= @NumProv                
BEGIN                
 SELECT @Proveedor=Proveedor                
        ,@RFC=p.RFC                
FROM @ProveedoresRFC AS p                
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
   
    IF EXISTS(SELECT 1 FROM @DocsXML)   
    BEGIN     
  
    --Se insertan los documentos XML enumerados para su procesamiento                
    INSERT INTO @ArchivosXML            
    SELECT ROW_NUMBER() OVER (ORDER BY dx.DocXML), UPPER(SUBSTRING(dx.DocXML,1,CHARINDEX('.',dx.DocXML,1)-1))                      
    FROM @DocsXML AS dx                       
    WHERE dx.DocXML IS NOT NULL                      
    AND UPPER(SUBSTRING(dx.DocXML,CHARINDEX('.',dx.DocXML,1)+1,3))='XML'    
      
    IF NOT EXISTS(SELECT 1 FROM @ArchivosXML)  
    BEGIN  
         WITH docsXml  
        AS(  
            SELECT DISTINCT REVERSE(right(REVERSE(DocXML),LEN(DocXML)-4))+'.xml' AS 'nombreinvertido',  
                    REVERSE(right(REVERSE(DocXML),LEN(DocXML)-4)) As 'edocname'  
            FROM @DocsXML  
            WHERE DocXML is not null  
        )  
        INSERT INTO @ArchivosXML  
        SELECT ROW_NUMBER() OVER (ORDER BY nombreinvertido),edocname  
        FROM docsXml  
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
                            
            --Se obtienen las rutas de donde se encuetran los documentos XML y PDF asi como el nombre de los docs XML                
            SELECT @RutaDocXML=@Ruta+'\'+dx.eDocName+'.xml'                
                   ,@RutaDocPDF=@Ruta+'\'+dx.eDocName+'.PDF'                
                   ,@NombreDoc=dx.eDocName                
            FROM @ArchivosXML AS dx                
            WHERE dx.ID=@ContXML                
   
            BEGIN TRY               
            --Se realiza la insercion de los datos en la tablan #XMLData de tipo XML                
            SET @cmdSQL='INSERT INTO #XMLData                
                                SELECT P                 
                                FROM OPENROWSET(BULK '+@Apostofre+@RutaDocXML+@Apostofre+', SINGLE_BLOB) AS Datos(P)'   
     
              EXEC (@cmdSQL)   
              END TRY  
              BEGIN CATCH  
                SELECT @OK=ERROR_NUMBER(),  
                        @OKref=ERROR_MESSAGE()  
              END CATCH  
               

              BEGIN TRY  
                      
                    --Esta seccion utilizara un script que determinara si el xml es de cancelacion, de ser asi devolvera el codigo de cancelacion en la variable  
                   --@OKRef y lo asignara a la variable @clavecancelacion  
                   IF @OK IS NULL  
                   BEGIN  
                        SELECT @OK=NULL,  
                               @OKRef=NULL,
                               @ClaveCancelacion=null
                                 
                               SELECT @XMLCancelado=CAST(DocXML AS VARCHAR(MAX))              
                                FROM #XMLData   
                                 
                               EXEC xpXMLCanceladosSAM @XMLCancelado,@OK OUTPUT,@OKref OUTPUT  
                                 
                               IF @OK IS NOT NULL  
                                SELECT @ClaveCancelacion=@OKRef   
                   END  
                      
                  IF @OK IS NULL And @ClaveCancelacion IS NULL  
                  BEGIN   
                      SELECT @OK=NULL,  
                             @OKRef=NULL  
                                           
                      --Se eliminan caracteres invalidos tales como acentos 
                       SELECT @CadenaXML=dbo.fneDocQuitarAcentos(CAST(DocXML AS VARCHAR(MAX)))  
                       FROM #XMLData   

                       select @CadenaXML=dbo.fnSAMEliminarAddendaXML(@CadenaXML)

                      --Se ejecuta la validacion del XML a fin de comprobar que el documento esta correcto                 
                      EXEC xpValSAMXMLCFDI @Empresa,@CadenaXML,@OK OUTPUT,@OKref OUTPUT    
  
                      --Se ejecuta el validador de documentos XML que no cumplen los requisitos del primer validador  
                      IF @OK IS NOT NULL  
                      BEGIN  
                         SELECT @ok=NULL,  
                                @OKref=NULL  
  
                         --Se elimina cualquier prefijo encontrado en el documento XML  y addendas
                         SELECT @CadenaXML=dbo.fnSAMEliminarAddendaXML(CAST(DocXML AS VARCHAR(MAX)))    
                         FROM #XMLData 

                         select @CadenaXML=dbo.fnSAMEliminarPrefijosXML(@CadenaXML)
                         
                         --Se eliminan caracteres invalidos tales como acentos  
                          SELECT @CadenaXML=dbo.fneDocQuitarAcentos(@CadenaXML)  
                                                                            
                          EXEC xpSAMValidaCFDEsp @CadenaXML,@OK OUTPUT,@OKref OUTPUT        
                             
                
                        END  
                  END  
                  ELSE  
                  BEGIN  
                   SELECT @OK=NULL  
                  END  
     END TRY  
     BEGIN CATCH  
           SELECT @OK=ERROR_NUMBER()  
                  ,@OKRef=ERROR_MESSAGE()   
     END CATCH  

                --Antes de la lectura del documento y posterior a su validacion se verifica si el nombre del documento es valido
                 SELECT @NombreTieneEspacio= CHARINDEX(' ',eDocName,1)
                  FROM @ArchivosXML AS dx                
                  WHERE dx.ID=@ContXML 

               IF ISNULL(@NombreTieneEspacio,0)<>0
                  SELECT @OK=900010,
                         @OKref='EL nombre del documento XML es invàlido. Nombre con espacios no valido: '+eDOcName
                   FROM @ArchivosXML AS dx                
                    WHERE dx.ID=@ContXML
  
               --Si el documento es correcto entonces se realiza una segunda comprobacion                
              IF @OK IS NULL         
              BEGIN     
              
               BEGIN TRY  
               --Se elimina cualquier prefijo encontrado en el documento XML  
                IF @ClaveCancelacion IS NULL  
                BEGIN  
                   --Se elimina cualquier prefijo encontrado en el documento XML  y addendas
                   SELECT @CadenaXML=CAST(DocXML AS VARCHAR(MAX))    
                    FROM #XMLData   
                                     
                    SELECT @CadenaXML=dbo.fnSAMEliminarAddendaXML(@CadenaXML)

                    SELECT @CadenaXML=dbo.fnSAMEliminarPrefijosXML(@CadenaXML)

                END  
                ELSE  
                    SELECT @CadenaXML=CAST(DocXML AS VARCHAR(MAX))    
                      FROM #XMLData    
                 
                   --Se eliminan caracteres invalidos tales como acentos  
                   SELECT @CadenaXML=dbo.fneDocQuitarAcentos(@CadenaXML)   
                      
                   --Se reasigna la variable XML con la cadena de tipo XML                
                    SELECT @XML=CAST(@CadenaXML AS XML)      
  
                IF @OK IS NULL  
                BEGIN  
              
                    IF @ClaveCancelacion IS NULL
                    BEGIN
                        --Se prepara el XML para su lectura                
                        EXEC sp_xml_preparedocument @hdoc OUTPUT,@XML                
                                      
                       --Se obtiene el UUID del documento XML  
                       SELECT @UUID=UUID                
                       FROM OPENXML (@hdoc, '/Comprobante/Complemento/TimbreFiscalDigital',1)                
                           WITH (                
                                UUID    NVARCHAR(100)                
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
                    END  
                    
                    --Valida si el tipo de comprobante es vacio   
                        IF @ClaveCancelacion IS NOT NULL  
                          SELECT @TipoComprobante='C',
                                 @UUID=null,
                                 @Folio=null,
                                 @Fecha=null,
                                 @Total=0,
                                 @RFCProv=@RFC
                    
                                      --Se realiza la validacion para saber si existe el UUID en la tabla SATXML se mueve a validados y se inserta en la tabla de datos                
                   IF EXISTS(SELECT 1 FROM SatXml AS sx WHERE sx.FolioFiscal=@UUID)                
                   BEGIN                
                                 
                        SET @RutaProcXML=@RutaValido+'\'+@NombreDoc+'.xml'                
                        SET @RutaProcPDF=@RutaValido+'\'+@NombreDoc+'.PDF'                
            
                   
                   --Se insertan datos en la tabla a utilizar oara la asocioacion de movimientos                
                   IF NOT EXISTS(SELECT 1 FROM AsociadoXMLSAM WHERE Nombre=@NombreDoc+'.xml' and RFC=@RFC)
                       INSERT INTO AsociadoXMLSAM(Nombre,Folio,Importe,RFC,Tipo,UUID,FechaTimbrado,FechaRegistro,Asociado)                
                                        SELECT @NombreDoc+'.xml',@Folio,@Total,@RFCProv,@TipoComprobante,@UUID,@Fecha,CAST(GETDATE() AS DATE),0                
                            
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
                    IF NOT EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Nombre=@NombreDoc+'.xml')                 
                        INSERT INTO AsocXMLSAMLog(Nombre,Proveedor, Rfc,Estatus, Descripcion, FechaProceso)                
                                      SELECT @NombreDoc+'.xml',@Proveedor,@RFC,'Procesado','Procesado con exito',GETDATE()         
                    ELSE        
                        UPDATE AsocXMLSAMLog SET Estatus='Procesado'        
                                                ,Descripcion='Procesado con exito'        
                                                ,FechaProceso=GETDATE()        
                                        WHERE Nombre=@NombreDOc+'.xml'        
                                                    
                   END                
                   ELSE      
                   BEGIN     
                     --Valida que el tipo de comprobante sea un complemento de pago, carta porte y no exista su UUID en la tabla de SATXML     
                        IF @TipoComprobante IN ('T','P','E','C')  
                        BEGIN  
                         SET @RutaProcXML=@RutaValido+'\'+@NombreDoc+'.xml'                
                            SET @RutaProcPDF=@RutaValido+'\'+@NombreDoc+'.PDF'              
            
                            --Se insertan datos en la tabla a utilizar oara la asocioacion de movimientos     
                            IF NOT EXISTS(SELECT 1 FROM AsociadoXMLSAM WHERE Nombre=@NombreDoc+'.xml' and RFC=@RFC)
                                INSERT INTO AsociadoXMLSAM(Nombre,Folio,Importe,RFC,Tipo,UUID,FechaTimbrado,FechaRegistro,Asociado)                
                                                    SELECT @NombreDoc+'.xml',isnull(@Folio,''),isnull(@Total,0),isnull(@RFCProv,@Rfc),@TipoComprobante,isnull(@UUID,''),isnull(@Fecha,CAST(GETDATE() AS DATE)),CAST(GETDATE() AS DATE),0                
                            
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
                            IF NOT EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Nombre=@NombreDoc+'.xml')           
                                    INSERT INTO AsocXMLSAMLog(Nombre,Proveedor,rfc, Estatus, Descripcion, FechaProceso)                
                                              SELECT @NombreDoc,@Proveedor,@RFC,'Procesado','Procesado con exito',GETDATE()     
                              ELSE      
                                    UPDATE AsocXMLSAMLog SET Estatus='Procesado'      
                                                        ,Descripcion='Procesado con exito'      
                                                        ,FechaProceso=GETDATE()      
                                    WHERE Nombre=@NombreDoc+'.xml'    
                        END  
                        ELSE  
                        BEGIN  
                            SET @RutaProcXML=@RutaInValido+'\'+@NombreDoc+'.xml'                
                              SET @RutaProcPDF=@RutaInValido+'\'+@NombreDoc+'.PDF'                
                                    
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
                          IF NOT EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Nombre=@NombreDoc+'.xml')                                          
                              INSERT INTO AsocXMLSAMLog(Nombre,Proveedor,Rfc, Estatus, Descripcion, FechaProceso)                
                                          SELECT @NombreDoc+'.xml',@Proveedor,@RFC,'NoProcesado','No se encuentra disponible en la tabla de SATXML',GETDATE()         
                          ELSE      
                              UPDATE AsocXMLSAMLog SET Descripcion='No se encuentra disponible en la tabla de SATXML'      
                                                          ,Estatus='NoProcesado'      
                                                     ,FechaProceso=GETDATE()      
                                            WHERE Nombre=@NombreDoc+'.xml'      
      
                          SELECT @ok=NULL,      
                             @okref=NULL      
                        END  
                 END      
              END                
              ELSE                
              BEGIN       
                    SET @RutaProcXML=@RutaInValido+'\'+@NombreDoc+'.xml'                
                    SET @RutaProcPDF=@RutaInValido+'\'+@NombreDoc+'.PDF'                
                                    
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
                 IF NOT EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Nombre=@NombreDoc+'.xml')                 
                        INSERT INTO AsocXMLSAMLog(Nombre,Proveedor,Rfc, Estatus, Descripcion, FechaProceso)                
                                          SELECT @NombreDoc+'.xml',@Proveedor,@RFC,'NoProcesado',CAST(@OK AS VARCHAR(10))+' '+ISNULL(@OKRef,''),GETDATE()        
                    ELSE        
                       UPDATE AsocXMLSAMLog SET Descripcion = CAST(@OK AS VARCHAR(10))+' '+ISNULL(@OKRef,'')        
                                                ,FechaProceso = GETDATE()        
                       WHERE Nombre=@NombreDoc+'.xml'         
        
                SELECT @ok=NULL,      
                   @okref=NULL      
                 --BREAK        
              END          
             
              END TRY  
              BEGIN CATCH  
    
                   SELECT @OK=ERROR_NUMBER()  
                          ,@OKRef=ERROR_MESSAGE()   
  
              END CATCH  
              
              IF @OK IS NOT NULL  
              BEGIN  

                --Se insertan los valores de exitos en la tabla de registro de errores                
                IF NOT EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Nombre=@NombreDoc+'.xml')                 
                    INSERT INTO AsocXMLSAMLog(Nombre,Proveedor,Rfc, Estatus, Descripcion, FechaProceso)                
                                       SELECT @NombreDoc+'.xml',@Proveedor,@RFC,'NoProcesado',CAST(@OK AS VARCHAR(10))+' '+ISNULL(@OKRef,''),GETDATE()        
                ELSE        
                   UPDATE AsocXMLSAMLog SET Descripcion = CAST(@OK AS VARCHAR(10))+' '+ISNULL(@OKRef,'')        
                                            ,FechaProceso = GETDATE()        
                   WHERE Nombre=@NombreDoc+'.xml'   
               END 
            END         
              --Esta validacion inserta aquellos documentos en el log cuyo nombre es invalido por caracteres no validos y los deja en la carpeta de PorValidar
              IF @OK IS NOT NULL  
              BEGIN  
                    --Se insertan los valores de exitos en la tabla de registro de errores                
                    IF NOT EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Nombre=@NombreDoc+'.xml')                 
                       INSERT INTO AsocXMLSAMLog(Nombre,Proveedor,Rfc, Estatus, Descripcion, FechaProceso)                
                                           SELECT @NombreDoc+'.xml',@Proveedor,@RFC,'NoProcesado',CAST(@OK AS VARCHAR(10))+' '+ISNULL(@OKRef,''),GETDATE()        
                    ELSE        
                       UPDATE AsocXMLSAMLog SET Descripcion = CAST(@OK AS VARCHAR(10))+' '+ISNULL(@OKRef,'')        
                                                ,FechaProceso = GETDATE()  
                                                ,Estatus='NoProcesado'
                       WHERE Nombre=@NombreDoc+'.xml'   
                END
                 
              TRUNCATE TABLE #XMLdata                
                          
            SET @ContXML=@ContXML+1 
        END                 
    END    
    END  
                    
 DELETE FROM @DocsXML                
 DELETE FROM @ArchivosXML            
   
     
    -- Liberamos memoria de la lectura del xml
    IF @hdoc IS NOT NULL and @ClaveCancelacion is null               
                EXEC sp_xml_removedocument @hdoc 
                 
 SET @ContProv=@ContProv+1                
END         
                
RETURN                
END 
