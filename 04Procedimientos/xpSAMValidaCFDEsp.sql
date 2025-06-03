SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpSAMValidaCFDEsp')
DROP PROCEDURE xpSAMValidaCFDEsp
GO
CREATE PROCEDURE xpSAMValidaCFDEsp
@XML    VARCHAR(MAX),
@OK     INT OUTPUT,
@OKRef  VARCHAR(255) OUTPUT
AS
BEGIN
	DECLARE @CadenaXML  VARCHAR(MAX),
	        @XMLValido  XML,
	        @Version    VARCHAR(5),
			@Subtotal	FLOAT,
			@Total		FLOAT,
			@TipoComprobante	VARCHAR(3),
			@LugarExpedicion	VARCHAR(5),
			@Serie		VARCHAR(5),
			@Moneda		VARCHAR(5),
			@fecha		VARCHAR(20),
			@RFC		VARCHAR(13),
			@Nombre		VARCHAR(255),
			@RegimenFiscal	VARCHAR(3),
			@RfcReceptor    varchar(13)  ,    
			@NombreReceptor   varchar(254) ,    
			@ResidenciaFiscal varchar(10),    
			@NumRegIDTrib  varchar(40),    
			@UsoCFDI   varchar(10),
			@TotalImpRetenidos	FLOAT,
			@TotalImpTrasladados	FLOAT,
			@TotTrasImpuesto	VARCHAR(8),
			@TotTrasTipoFactor	VARCHAR(100),
			@TotTrasTasaOCuota	VARCHAR(100),
			@TotTrasImporte		VARCHAR(100),
			@SumaTotTrasImporte	FLOAT,
			@ParteImporte		FLOAT,
	        @hdoc       INT
     
          --Se reemplazan los prefijos de la cadena XML para su lectura correcta
          SELECT @CadenaXML=REPLACE(@XML,'cfdi:','')
            
          SELECT @CadenaXML=REPLACE(@CadenaXML,'xmlns:','')
          SELECT @CadenaXML=REPLACE(@CadenaXML,'xsi:','')
          SELECT @CadenaXML=REPLACE(@CadenaXML,'tfd:','')
          
        -- SELECT LEFT(@CadenaXML,3366)
                      
          SELECT @XMLValido=CAST(@CadenaXML AS XML)
          
          EXEC sp_xml_preparedocument @hdoc OUTPUT,@XMLValido
          
          SELECT @Version=Version,
			     @fecha=Fecha,
				 @Subtotal=SubTotal,
				 @Moneda=Moneda,
				 @Total=Total,
				 @TipoComprobante=TipoDeComprobante,
				 @LugarExpedicion=LugarExpedicion,
				 @Serie=Serie				 
            FROM OPENXML (@hdoc, '/Comprobante',1)
            WITH (
                [Version]      NVARCHAR(255),
				[Fecha]		   NVARCHAR(255),
				[SubTotal]		   FLOAT,
				[Moneda]		   VARCHAR(5),
				[Total]		   FLOAT,
				[TipoDeComprobante]		   VARCHAR(3),
				[LugarExpedicion]		   VARCHAR(5),
				[Serie]			VARCHAR(5)
            )


			--SE VALIDA CABECERA--
            IF ISNULL(@Version,'')='' OR @Version NOT IN ('3.2','3.3','4.0')
                SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ CAST(ISNULL(@Version,'') as varchar(5))  
                FROM MensajeLista  
                WHERE Mensaje = 80300 
			
			IF ISNULL(@fecha,'')=''
				SELECT @Ok = Mensaje, @OkRef = Descripcion     
				FROM MensajeLista    
				WHERE Mensaje = 80301  
			
			IF ISNULL(@Subtotal,0)=0 
				SELECT @Ok = Mensaje, @OkRef = Descripcion     
				FROM MensajeLista    
				WHERE Mensaje = 80308  
			ELSE
				IF @Subtotal < 0.000000
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+CAST(@Subtotal as varchar(18))    
				FROM MensajeLista    
				WHERE Mensaje = 80309  

			IF ISNULL(@Moneda,'')=''
				SELECT @Ok = Mensaje, @OkRef = Descripcion     
				FROM MensajeLista    
				WHERE Mensaje = 80311
			ELSE
				IF NOT EXISTS(SELECT Clave FROM SATMoneda WHERE Clave = @Moneda)    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ ISNULL(@Moneda,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80312  

			IF ISNULL(@Total,0)=0
				SELECT @Ok = Mensaje, @OkRef = Descripcion     
				FROM MensajeLista    
				WHERE Mensaje = 80316   
			ELSE
				IF @Total < 0.000000
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + CAST(@Total as varchar(18))    
				FROM MensajeLista    
				WHERE Mensaje = 80317    

			IF ISNULL(@TipoComprobante,'')=''
				SELECT @Ok = Mensaje, @OkRef = Descripcion     
				FROM MensajeLista    
				WHERE Mensaje = 80318  
			ELSE    
				IF NOT EXISTS(SELECT TipoComprobante FROM SATCatTipoComprobante WHERE TipoComprobante = @TipoComprobante)    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TipoComprobante,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80319    
			
			IF ISNULL(@LugarExpedicion,'')=''
				SELECT @Ok = Mensaje, @OkRef = Descripcion     
				FROM MensajeLista    
				WHERE Mensaje = 80321  
			ELSE   
				IF NOT EXISTS(SELECT ClaveCP FROM SATCatCP WHERE ClaveCP = @LugarExpedicion)    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ ISNULL(@LugarExpedicion,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80322  
				
			--VALIDA EMISOR--
			SELECT @RFC   = [Rfc],    
				   @Nombre   = [Nombre],    
				   @RegimenFiscal = [RegimenFiscal]    
					FROM OPENXML (@hdoc, 'Comprobante/Emisor', 1) WITH ( 
						[Rfc]   varchar(13)  ,    
						[Nombre]  varchar(254) ,    
						[RegimenFiscal] varchar(3)    
					)  
			
			IF EXISTS(SELECT FiscalRegimen FROM FiscalRegimen WHERE FiscalRegimen = @RegimenFiscal )
			BEGIN
				IF dbo.ValidaRFC(@RFC) <> 1    
				IF @RegimenFiscal <> '622'    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ ISNULL(@RFC,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80325    
				ELSE    
				IF dbo.ValidaRFC(@RFC) <> 1    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@RFC,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80325				
			END
			IF NOT EXISTS(SELECT * FROM FiscalRegimen WHERE FiscalRegimen = @RegimenFiscal)    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ISNULL(@RegimenFiscal,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80326 
			
			--VALIDA RECEPTOR--
			SELECT @RfcReceptor  = [Rfc],    
					@NombreReceptor  = [Nombre],    
					@ResidenciaFiscal = [ResidenciaFiscal],    
					@NumRegIDTrib  = [NumRegIdTrib],    
					@UsoCFDI   = [UsoCFDI]    
					FROM OPENXML (@hdoc, 'Comprobante/Receptor', 1) WITH (
						[Rfc]    varchar(13)  ,    
					[Nombre]   varchar(254) ,    
					[ResidenciaFiscal] varchar(10),    
					[NumRegIdTrib]  varchar(40),    
					[UsoCFDI]   varchar(10)    
					)  
			IF @OK IS NULL
			BEGIN	
				IF @RfcReceptor NOT LIKE '[A-Z&][A-Z&][A-Z&][0-9][0-9][0-9][0-9][0-9][0-9][0-Z&][0-Z&][0-Z&]' AND    
				@RfcReceptor NOT LIKE '[A-Z&][A-Z&][A-Z&][A-Z&][0-9][0-9][0-9][0-9][0-9][0-9][0-Z&][0-Z&][0-Z&]'    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@RfcReceptor,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80327    
				IF EXISTS(SELECT * FROM Cte c JOIN FiscalRegimen f ON f.FiscalRegimen = c.FiscalRegimen WHERE c.RFC = @RfcReceptor AND f.Extranjero = 1)    
				BEGIN    
				IF @Ok IS NULL AND NOT EXISTS(SELECT ClavePais FROM SATPais WHERE ClavePais = @ResidenciaFiscal)    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ResidenciaFiscal,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80328    
				END    
    
				IF @Ok IS NULL AND NOT EXISTS(SELECT ClaveUsoCFDI FROM SATCatUsoCFDI WHERE ClaveUsoCFDI = @UsoCFDI)    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@UsoCFDI,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80329  
			END
			--VALIDA IMPUESTOS--
			SELECT @TotalImpRetenidos   = [TotalImpuestosRetenidos],    
					@TotalImpTrasladados = [TotalImpuestosTrasladados]    
					FROM OPENXML (@hdoc, 'Comprobante/Impuestos',1)    
					WITH ([TotalImpuestosRetenidos]  FLOAT,    
					[TotalImpuestosTrasladados] FLOAT    
					)   
			IF @OK IS NULL
			BEGIN
				IF @TotalImpRetenidos < 0.000000    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ParteImporte,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80358    
				IF @TotalImpTrasladados < 0.000000    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ParteImporte,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80359 
			END
			--TOTAL TRASLADADO--
			IF @OK IS NULL
			BEGIN
				DECLARE cTotalTranslados CURSOR FOR    
				SELECT [Impuesto],    
				[TipoFactor],    
				[TasaOCuota],    
				[Importe]    
				FROM OPENXML (@hdoc, 'Comprobante/Impuestos/Traslados/Traslado',1)    
				WITH ([Impuesto]  varchar(8),    
				[TipoFactor]  varchar(100),    
				[TasaOCuota]  varchar(100),    
				[Importe]   varchar(100)    
				)    
				OPEN cTotalTranslados    
				FETCH NEXT FROM cTotalTranslados INTO @TotTrasImpuesto, @TotTrasTipoFactor, @TotTrasTasaOCuota, @TotTrasImporte    
				WHILE @@FETCH_STATUS = 0  BEGIN    
				IF @TotTrasImpuesto NOT IN ('001','002','003')    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TotTrasImpuesto,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80362    
				IF NOT EXISTS(SELECT Descripcion FROM SATCatTipoFactor WHERE Descripcion = @TotTrasTipoFactor)    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TotTrasTipoFactor,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80363    
				IF @TotTrasTipoFactor IN (SELECT DISTINCT Factor FROM SATCatTasaOCuota)  
				BEGIN  
				IF NOT EXISTS (SELECT ValMax FROM SATCatTasaOCuota WHERE ValMax = CAST(@TotTrasTasaOCuota as float) AND Factor = @TotTrasTipoFactor AND Traslado = 1)  
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TotTrasTasaOCuota,'')  
				FROM MensajeLista  
				WHERE Mensaje = 80364  
				END  
				IF CAST(@TotTrasImporte AS FLOAT) < 0.000000    
				SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TotTrasTasaOCuota,'')    
				FROM MensajeLista    
				WHERE Mensaje = 80365    
				--SELECT @SumaTotTrasImporte = ISNULL(@SumaTotTrasImporte,0) + @SumaTotTrasImporte    
				FETCH NEXT FROM cTotalTranslados INTO @TotTrasImpuesto, @TotTrasTipoFactor, @TotTrasTasaOCuota, @TotTrasImporte    
				END    
				CLOSE cTotalTranslados    
				DEALLOCATE cTotalTranslados    
			END
			
RETURN
END
          
          --DROP TABLE #XMLData