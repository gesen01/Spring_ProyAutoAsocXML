SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpValSAMXMLCFDI')
DROP PROCEDURE xpValSAMXMLCFDI
GO
CREATE PROCEDURE xpValSAMXMLCFDI
(@Empresa		varchar(5),
@XML			nvarchar(max) OUTPUT,
@Ok			int = NULL OUTPUT,
@OkRef			varchar(255) = NULL OUTPUT
)
WITH ENCRYPTION
AS
BEGIN
DECLARE
@DocXML				varchar(max),
@iDatos				int,
@NameSpace			varchar(max),
@CampoValidar		varchar(max),
@Encabezado			varchar(max),
@Version			varchar(5),
@Serie				varchar(25),
@Folio				varchar(40),
@Fecha				varchar(19),
@Sello				varchar(max),
@FormaPago			varchar(2),
@NoCertificado		varchar(max),
@Certificado		varchar(max),
@CondicionesPago	varchar(1000),
@Subtotal			decimal(18,6),
@Descuento			decimal(18,6),
@Moneda				varchar(5),
@TipoCambio			decimal(18,6),
@EDICOMTipoCambio	decimal(18,2),
@Total				decimal(18,6),
@TipoComprobante	varchar(1),
@MetodoPago			varchar(3),
@LugarExpedicion	varchar(5),
@Confirmacion		varchar(20),
@CFDIRelacionado	varchar(max),
@TipoRelacion		varchar(2),
@UUIDRelacionado	varchar(50),
@Emisor				varchar(max),
@RFC				varchar(13),
@Nombre				varchar(254),
@RegimenFiscal		varchar(3),
@Receptor			varchar(max),
@RfcReceptor		varchar(13),
@NombreReceptor		varchar(254),
@ResidenciaFiscal	varchar(3),
@NumRegIDTrib		varchar(40),
@UsoCFDI			varchar(3),
@Concepto			varchar(max),
@CptoClaveProdServ	varchar(8),
@CptoNoIden			varchar(100),
@CptoCantidad		decimal(18,6),
@CptoClaveUnidad	varchar(5),
@CptoUnidad			varchar(20),
@CptoDescripcion	varchar(1000),
@CptoValorUnitario	decimal(18,6),
@CptoImporte		decimal(18,6),
@CptoDescuento		decimal(18,6),
/*********  Impuestos  *********/
@TrasladoBase		decimal(18,6),
@TrasladoImpuesto	varchar(3),
@TrasladoTipoFactor varchar(6),
@TrasladoTasaOCuota varchar(25),
@TrasladoImporte	decimal(18,6),
@SumaTraslados		decimal(18,6),
@RetencionBase			decimal(18,6),
@RetencionImpuesto		varchar(3),
@RetencionTipoFactor	varchar(6),
@RetencionTasaOCuota	varchar(25),
@RetencionImporte		decimal(18,6),
@SumaRetenciones		decimal(18,6),
/****  Información Aduanera  ***/
@NumeroPedimento	varchar(21),
/*******  Cuenta Predial  ******/
@CtaPredialNumero	varchar(150),
/*********    Parte     ********/
@ParteClaveProdServ	varchar(8),
@ParteNoIden		varchar(100),
@ParteCantidad		decimal(18,6),
@ParteUnidad		varchar(20),
@ParteDescripcion	varchar(1000),
@ParteValorUnitario	decimal(18,6),
@ParteImporte		decimal(18,6),
@TotalImpRetenidos		decimal(18,6),
@TotalImpTrasladados	decimal(18,6),
@TotRetImpuesto			varchar(3),
@TotRetImporte			decimal(18,6),
@SumaTotRetImporte		decimal(18,6),
@TotTrasImpuesto		varchar(3),
@TotTrasTipoFactor		varchar(10),
@TotTrasTasaOCuota		varchar(25),
@TotTrasImporte			decimal(18,6),
@SumaTotTrasImporte		decimal(18,6),
@NameSpaceComplemento	varchar(max),
@TipoComplemento		varchar(3),
@ServidorTimbrado		varchar(100),
@DiferenciaCentavos		decimal(18,6),
@CfgDecimales			INT,
@ArchivoXML		     XML,
@TipoCambioInt			FLOAT
SELECT @CfgDecimales = ISNULL(Decimales,2) FROM EmpresaCFD WHERE Empresa = @Empresa
SELECT @NameSpace = REPLACE(@XML COLLATE Latin1_General_100_CI_AI,'<?xml version="1.0" encoding="Windows-1252" ?>','')
SELECT @NameSpace = SUBSTRING(@NameSpace COLLATE Latin1_General_100_CI_AI, 1 , PATINDEX('%version=%',@NameSpace COLLATE Latin1_General_100_CI_AI)-1)+'/>'
SELECT @XML = REPLACE(@XML COLLATE Latin1_General_100_CI_AI,'<?xml version="1.0" encoding="Windows-1252" ?>','')
SELECT @ArchivoXML=CAST(@XML AS XML)
EXEC sp_xml_preparedocument @iDatos OUTPUT, @ArchivoXML , @NameSpace
/**********************************     E N C A B E Z A D O     ***************************************/
SELECT @Encabezado = REPLACE(@XML COLLATE Latin1_General_100_CI_AI,'<?xml version="1.0" encoding="Windows-1252"?>','')
SELECT @Encabezado = SUBSTRING(@Encabezado COLLATE Latin1_General_100_CI_AI, 1 , PATINDEX('%>%',@Encabezado COLLATE Latin1_General_100_CI_AI)-1)+'/>'
SELECT	@Version			= [Version],
@Serie				= [Serie],
@Folio				= [Folio],
@Fecha				= [Fecha],
@Sello				= [Sello],
@FormaPago			= [FormaPago],
@NoCertificado		= [NoCertificado],
@Certificado		= [Certificado],
@CondicionesPago	= [CondicionesPago],
@Subtotal			= [SubTotal],
@Descuento			= [Descuento],
@Moneda				= [Moneda],
@TipoCambio			= [TipoCambio],
@Total				= [Total],
@TipoComprobante	= [TipoDeComprobante],
@MetodoPago			= [MetodoPago],
@LugarExpedicion	= [LugarExpedicion],
@Confirmacion		= [Confirmacion]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante', 1) WITH (	[Version]			varchar(5),
[Serie]				varchar(25),
[Folio]				varchar(40),
[Fecha]				varchar(19),
[Sello]				varchar(max),
[FormaPago]			varchar(2),
[NoCertificado]		varchar(max),
[Certificado]		varchar(max),
[CondicionesPago]	varchar(1000),
[SubTotal]			decimal(18,6),
[Descuento]			decimal(18,6),
[Moneda]			varchar(5),
[TipoCambio]		decimal(18,6),
[Total]				decimal(18,6),
[TipoDeComprobante]	varchar(1),
[MetodoPago]		varchar(3),
[LugarExpedicion]	varchar(5),
[Confirmacion]		varchar(20)
)

SELECT @TipoCambioInt=m.TipoCambio FROM Mon AS m WHERE m.Clave=@Moneda

IF @Ok IS NULL AND @Version NOT IN ('3.2','3.3','4.0')
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ CAST(ISNULL(@Version,'') as varchar(5))
FROM MensajeLista
WHERE Mensaje = 80300
IF @Ok IS NULL AND @Serie IS NULL
SELECT @Encabezado = REPLACE(@Encabezado COLLATE Latin1_General_100_CI_AI,'Serie=""','')
IF @Ok IS NULL AND @Folio IS NULL
SELECT @Encabezado = REPLACE(@Encabezado COLLATE Latin1_General_100_CI_AI,'Folio=""','')
IF @Ok IS NULL
BEGIN
IF @Fecha IS NULL
SELECT @Ok = Mensaje, @OkRef = Descripcion 
FROM MensajeLista
WHERE Mensaje = 80301
ELSE
IF LTRIM(RTRIM(@Fecha)) NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]'
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ @Fecha
FROM MensajeLista
WHERE Mensaje = 80302
END
IF @Ok IS NULL
BEGIN
IF @FormaPago IS NULL
SELECT @Encabezado = REPLACE(@Encabezado COLLATE Latin1_General_100_CI_AI,'FormaPago=""','')
ELSE
IF NOT EXISTS(SELECT * FROM SATFormaPago WHERE Clave = @FormaPago)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ ISNULL(@FormaPago,'')
FROM MensajeLista
WHERE Mensaje = 80304
END
IF @Ok IS NULL
BEGIN
IF @Subtotal IS NULL
SELECT @Ok = Mensaje, @OkRef = Descripcion 
FROM MensajeLista
WHERE Mensaje = 80308
ELSE
IF @Subtotal < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+CAST(@Subtotal as varchar(18))
FROM MensajeLista
WHERE Mensaje = 80309
END
IF @Ok IS NULL
BEGIN
IF @Descuento IS NULL
SELECT @Encabezado = REPLACE(@Encabezado COLLATE Latin1_General_100_CI_AI,'Descuento=""','')
ELSE
IF @Descuento < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+CAST(@Descuento as varchar(18))
FROM MensajeLista
WHERE Mensaje = 80310
END
IF @Ok IS NULL
BEGIN
IF @Moneda IS NULL
SELECT @Ok = Mensaje, @OkRef = Descripcion 
FROM MensajeLista
WHERE Mensaje = 80311
ELSE
IF NOT EXISTS(SELECT Clave FROM SATMoneda WHERE Clave = @Moneda)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ ISNULL(@Moneda,'')
FROM MensajeLista
WHERE Mensaje = 80312
END
IF @Ok IS NULL
BEGIN
IF @Moneda COLLATE Latin1_General_100_CI_AI IN ('MXN','XXX') AND @TipoCambio IS NULL
SELECT @Encabezado = REPLACE(@Encabezado COLLATE Latin1_General_100_CI_AI,'TipoCambio=""','')
IF @Moneda COLLATE Latin1_General_100_CI_AI NOT IN ('MXN','XXX') AND @TipoCambio IS NULL
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Moneda:'+ ISNULL(@Moneda,'')
FROM MensajeLista
WHERE Mensaje = 80313
ELSE
IF @Moneda NOT IN ('MXN','XXX') AND @TipoCambio < 0.000001
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Moneda:'+@Moneda+' Valor: '+ CAST(@TipoCambio as varchar(18))
FROM MensajeLista
WHERE Mensaje = 80314
ELSE
BEGIN
--SELECT @Version,@Moneda,@TipoCambio
IF @Moneda = 'MXN' AND ISNULL(ROUND(@TipoCambio,0),1) <> @TipoCambioInt
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Moneda:'+@Moneda+' Valor: '+ CAST(ISNULL(@TipoCambio,0) as varchar(18))
FROM MensajeLista
WHERE Mensaje = 80315
END
END
IF @Ok IS NULL
BEGIN
IF @Total IS NULL
SELECT @Ok = Mensaje, @OkRef = Descripcion 
FROM MensajeLista
WHERE Mensaje = 80316
ELSE
IF @Total < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + CAST(@Total as varchar(18))
FROM MensajeLista
WHERE Mensaje = 80317
END
IF @Ok IS NULL
BEGIN
IF @TipoComprobante IS NULL
SELECT @Ok = Mensaje, @OkRef = Descripcion 
FROM MensajeLista
WHERE Mensaje = 80318
ELSE
IF NOT EXISTS(SELECT TipoComprobante FROM SATCatTipoComprobante WHERE TipoComprobante = @TipoComprobante)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TipoComprobante,'')
FROM MensajeLista
WHERE Mensaje = 80319
END
IF @Ok IS NULL
BEGIN
IF @MetodoPago IS NULL
SELECT @Encabezado = REPLACE(@Encabezado COLLATE Latin1_General_100_CI_AI,'MetodoPago=""','')
ELSE
IF NOT EXISTS(SELECT IDClave FROM SATMetodoPago WHERE IDClave = @MetodoPago)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@MetodoPago,'')
FROM MensajeLista
WHERE Mensaje = 80320
END
IF @Ok IS NULL
BEGIN
IF @LugarExpedicion IS NULL
SELECT @Ok = Mensaje, @OkRef = Descripcion 
FROM MensajeLista
WHERE Mensaje = 80321
ELSE
IF NOT EXISTS(SELECT ClaveCP FROM SATCatCP WHERE ClaveCP = @LugarExpedicion)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ ISNULL(@LugarExpedicion,'')
FROM MensajeLista
WHERE Mensaje = 80322
END
IF @Ok IS NULL AND (@Confirmacion IS NULL OR @Confirmacion = '_CONFIRMACION_')
SELECT @Encabezado = REPLACE(REPLACE(@Encabezado COLLATE Latin1_General_100_CI_AI,'Confirmacion=""','')COLLATE Latin1_General_100_CI_AI,'Confirmacion="_CONFIRMACION_"','')
/*****************************     C F D I   R E L A C I O N A D O S     ******************************/
IF @OK IS NULL
BEGIN
DECLARE cCFDIRelacionado CURSOR FOR
SELECT	[TipoRelacion],
[UUID]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:CfdiRelacionados/cfdi:CfdiRelacionado',2)
WITH ([TipoRelacion]		varchar(2)	'../@TipoRelacion',
[UUID]				varchar(50) '@UUID'
)
OPEN cCFDIRelacionado
FETCH NEXT FROM cCFDIRelacionado INTO @TipoRelacion, @UUIDRelacionado
WHILE @@FETCH_STATUS = 0 AND @Ok IS NULL
BEGIN
IF NOT EXISTS(SELECT ClaveTipoRelacion FROM SATCatTipoRelacion WHERE ClaveTipoRelacion = @TipoRelacion)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ ISNULL(@TipoRelacion,'')
FROM MensajeLista
WHERE Mensaje = 80323
ELSE
SELECT @CFDIRelacionado = ISNULL(@CFDIRelacionado,'')+'<cfdi:CfdiRelacionados TipoRelacion="'+@TipoRelacion+'">'
IF @UUIDRelacionado COLLATE Latin1_General_100_CI_AI LIKE '[0-Z][0-Z][0-Z][0-Z][0-Z][0-Z][0-Z][0-Z]-[0-Z][0-Z][0-Z][0-Z]-[0-Z][0-Z][0-Z][0-Z]-[0-Z][0-Z][0-Z][0-Z]-[0-Z][0-Z][0-Z][0-Z][0-Z][0-Z][0-Z][0-Z][0-Z][0-Z][0-Z][0-Z]'
SELECT @CFDIRelacionado = @CFDIRelacionado+'<cfdi:CfdiRelacionado UUID="'+@UUIDRelacionado+'" />'
ELSE
BEGIN
SELECT @CFDIRelacionado = @CFDIRelacionado+'<cfdi:CfdiRelacionado UUID="" />'
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ ISNULL(@UUIDRelacionado,'')
FROM MensajeLista
WHERE Mensaje = 80324
END
SELECT @CFDIRelacionado = @CFDIRelacionado+'</cfdi:CfdiRelacionados>'
FETCH NEXT FROM cCFDIRelacionado INTO @TipoRelacion, @UUIDRelacionado
END
CLOSE cCFDIRelacionado
DEALLOCATE cCFDIRelacionado
END
/**************************************     E M I S O R      ******************************************/
IF @OK IS NULL
BEGIN
SELECT	@RFC			= [Rfc],
@Nombre			= [Nombre],
@RegimenFiscal	= [RegimenFiscal]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Emisor', 1) WITH (	[Rfc]			varchar(13)  ,
[Nombre]		varchar(254) ,
[RegimenFiscal]	varchar(3)
)
IF @Ok IS NULL
BEGIN
IF EXISTS(SELECT FiscalRegimen FROM FiscalRegimen WHERE FiscalRegimen = @RegimenFiscal AND TipoPersonaMoral COLLATE Latin1_General_100_CI_AI = 'SI')
IF @RFC NOT LIKE '[A-Z&][A-Z&][A-Z&][0-9][0-9][0-9][0-9][0-9][0-9][0-Z&][0-Z&][0-Z&]'
IF @RegimenFiscal <> '622'
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ ISNULL(@RFC,'')
FROM MensajeLista
WHERE Mensaje = 80325
ELSE
IF @RFC NOT LIKE '[A-Z&][A-Z&][A-Z&][A-Z&][0-9][0-9][0-9][0-9][0-9][0-9][0-Z&][0-Z&][0-Z&]'
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@RFC,'')
FROM MensajeLista
WHERE Mensaje = 80325
IF EXISTS(SELECT FiscalRegimen FROM FiscalRegimen WHERE FiscalRegimen = @RegimenFiscal AND TipoPersonaFisica COLLATE Latin1_General_100_CI_AI = 'SI')
IF @RFC NOT LIKE '[A-Z&][A-Z&][A-Z&][A-Z&][0-9][0-9][0-9][0-9][0-9][0-9][0-Z&][0-Z&][0-Z&]'
IF @RegimenFiscal <> '622'
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@RFC,'')
FROM MensajeLista
WHERE Mensaje = 80325
ELSE
IF @RFC NOT LIKE '[A-Z&][A-Z&][A-Z&][0-9][0-9][0-9][0-9][0-9][0-9][0-Z&][0-Z&][0-Z&]'
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@RFC,'')
FROM MensajeLista
WHERE Mensaje = 80325
END
IF @Ok IS NULL
BEGIN
IF NOT EXISTS(SELECT * FROM FiscalRegimen WHERE FiscalRegimen = @RegimenFiscal)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: '+ISNULL(@RegimenFiscal,'')
FROM MensajeLista
WHERE Mensaje = 80326
END
IF @Ok IS NULL
BEGIN
SELECT @Emisor = '<cfdi:Emisor Rfc="'+@RFC+'" Nombre="'
SELECT @Emisor = @Emisor + LTRIM(RTRIM(@Nombre))+ '" RegimenFiscal = "'+@RegimenFiscal+'" />'
END
END
/************************************     R E C E P T O R      ****************************************/
IF @Ok IS NULL
BEGIN
SELECT	@RfcReceptor		= [Rfc],
@NombreReceptor		= [Nombre],
@ResidenciaFiscal	= [ResidenciaFiscal],
@NumRegIDTrib		= [NumRegIdTrib],
@UsoCFDI			= [UsoCFDI]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Receptor', 1) WITH ([Rfc]				varchar(13)  ,
[Nombre]			varchar(254) ,
[ResidenciaFiscal]	varchar(3),
[NumRegIdTrib]		varchar(40),
[UsoCFDI]			varchar(3)
)
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
IF PATINDEX('%<cce:ComercioExterior>%',@XML) > 0
BEGIN
IF NULLIF(@NumRegIDTrib,' ') IS NULL
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@UsoCFDI,'')
FROM MensajeLista
WHERE Mensaje = 80366
END
IF @Ok IS NULL
BEGIN
SELECT @Receptor = '<cfdi:Receptor Rfc="'+@RfcReceptor+'" Nombre="'
SELECT @Receptor = @Receptor + LTRIM(RTRIM(@NombreReceptor))+ '" ResidenciaFiscal="'
SELECT @Receptor = @Receptor + @ResidenciaFiscal+'" UsoCFDI="'
SELECT @Receptor = @Receptor + @UsoCFDI+'" '
SELECT @Receptor = @Receptor + ISNULL('NumRegIDTrib="'+@NumRegIDTrib+'" />',' />')
END
END
/***********************************     C O N C E P T O S     ****************************************/
IF @Ok IS NULL
BEGIN
DECLARE cConcepto CURSOR FOR
SELECT	[ClaveProdServ],
[NoIdentificacion],
[Cantidad],
[ClaveUnidad],
[Unidad],
[Descripcion],
[ValorUnitario],
[Importe],
[Descuento]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto',2)
WITH ([ClaveProdServ]		varchar(8)		'@ClaveProdServ',
[NoIdentificacion]	varchar(100)	'@NoIdentificacion',
[Cantidad]			decimal(18,6)	'@Cantidad',
[ClaveUnidad]			varchar(5)		'@ClaveUnidad',
[Unidad]				varchar(20)		'@Unidad',
[Descripcion]			varchar(1000)	'@Descripcion',
[ValorUnitario]		decimal(18,6)	'@ValorUnitario',
[Importe]				decimal(18,6)	'@Importe',
[Descuento]			decimal(18,6)	'@Descuento'
)
OPEN cConcepto
FETCH NEXT FROM cConcepto INTO @CptoClaveProdServ, @CptoNoIden, @CptoCantidad, @CptoClaveUnidad, @CptoUnidad, @CptoDescripcion, @CptoValorUnitario, @CptoImporte, @CptoDescuento
WHILE @@FETCH_STATUS = 0 AND @Ok IS NULL
BEGIN
IF NOT EXISTS(SELECT Clave FROM SATCatClaveProdServ WHERE Clave = @CptoClaveProdServ)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@CptoClaveProdServ,'')
FROM MensajeLista
WHERE Mensaje = 80330
IF @Ok IS NULL
IF @CptoCantidad < 0.000001
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@CptoCantidad,'')
FROM MensajeLista
WHERE Mensaje = 80332
IF @Ok IS NULL
IF NOT EXISTS(SELECT ClaveUnidad FROM SATCatClaveUnidad WHERE ClaveUnidad = @CptoClaveUnidad)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@CptoClaveUnidad,'')
FROM MensajeLista
WHERE Mensaje = 80333
IF @Ok IS NULL
IF @CptoValorUnitario < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(CAST(@CptoValorUnitario AS VARCHAR(50)),'')
FROM MensajeLista
WHERE Mensaje = 80336
IF @Ok IS NULL
IF @CptoImporte < 0.000001
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(CAST(@CptoImporte AS VARCHAR(50)),'')
FROM MensajeLista
WHERE Mensaje = 80337
IF @Ok IS NULL AND @CptoDescuento IS NOT NULL
IF @CptoDescuento < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(CAST(@CptoDescuento AS VARCHAR(50)),'')
FROM MensajeLista
WHERE Mensaje = 80338
FETCH NEXT FROM cConcepto INTO @CptoClaveProdServ, @CptoNoIden, @CptoCantidad, @CptoClaveUnidad, @CptoUnidad, @CptoDescripcion, @CptoValorUnitario, @CptoImporte, @CptoDescuento
END
CLOSE cConcepto
DEALLOCATE cConcepto
END
/***********************************     I M P U E S T O S     ****************************************/
/***********************************     T R A S L A D O S     ****************************************/
IF @Ok IS NULL
BEGIN
DECLARE cTraslado CURSOR FOR
SELECT	[Base],
[Impuesto],
[TipoFactor],
[TasaOCuota],
[Importe]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',2)
WITH ([Base]				decimal(18,6)	'@Base',
[Impuesto]			varchar(3)		'@Impuesto',
[TipoFactor]			varchar(6)		'@TipoFactor',
[TasaOCuota]			varchar(25)		'@TasaOCuota',
[Importe]				decimal(18,6)	'@Importe'
)
OPEN cTraslado
FETCH NEXT FROM cTraslado INTO @TrasladoBase, @TrasladoImpuesto, @TrasladoTipoFactor, @TrasladoTasaOCuota, @TrasladoImporte
WHILE @@FETCH_STATUS = 0 AND @Ok IS NULL
BEGIN
IF @TrasladoBase < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TrasladoBase,'')
FROM MensajeLista
WHERE Mensaje = 80339
IF @TrasladoImpuesto NOT IN ('001','002','003')
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TrasladoImpuesto,'')
FROM MensajeLista
WHERE Mensaje = 80340
IF @TrasladoTipoFactor NOT IN (SELECT Descripcion FROM SATCatTipoFactor WHERE Descripcion = @TrasladoTipoFactor)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TrasladoTipoFactor,'')
FROM MensajeLista
WHERE Mensaje = 80341
IF @TrasladoTasaOCuota NOT IN (SELECT ValMax FROM SATCatTasaOCuota WHERE ValMax = CAST(@TrasladoTasaOCuota as varchar(10)) AND Factor = @TrasladoTipoFactor AND Traslado = 1)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TrasladoTasaOCuota,'')
FROM MensajeLista
WHERE Mensaje = 80342
IF @TrasladoImporte < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TrasladoImporte,'')
FROM MensajeLista
WHERE Mensaje = 80343
FETCH NEXT FROM cTraslado INTO @TrasladoBase, @TrasladoImpuesto, @TrasladoTipoFactor, @TrasladoTasaOCuota, @TrasladoImporte
END
CLOSE cTraslado
DEALLOCATE cTraslado
END
/*********************************     R E T E N C I O N E S     **************************************/
IF @Ok IS NULL
BEGIN
DECLARE cRetencion CURSOR FOR
SELECT	[Base],
[Impuesto],
[TipoFactor],
[TasaOCuota],
[Importe]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',2)
WITH ([Base]				decimal(18,6)	'@Base',
[Impuesto]			varchar(3)		'@Impuesto',
[TipoFactor]			varchar(6)		'@TipoFactor',
[TasaOCuota]			varchar(5)		'@TasaOCuota',
[Importe]				decimal(18,6)	'@Importe'
)
OPEN cRetencion
FETCH NEXT FROM cRetencion INTO @RetencionBase, @RetencionImpuesto, @RetencionTipoFactor, @RetencionTasaOCuota, @RetencionImporte
WHILE @@FETCH_STATUS = 0 AND @Ok IS NULL
BEGIN
IF @RetencionBase < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + CAST(@RetencionBase as varchar(25))
FROM MensajeLista
WHERE Mensaje = 80344
IF @RetencionImpuesto NOT IN ('001','002','003')
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@RetencionImpuesto,'')
FROM MensajeLista
WHERE Mensaje = 80345
IF @RetencionTipoFactor NOT IN (SELECT Descripcion FROM SATCatTipoFactor WHERE Descripcion = @RetencionTipoFactor)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@RetencionTipoFactor,'')
FROM MensajeLista
WHERE Mensaje = 80346
IF @RetencionTasaOCuota NOT IN (SELECT ROUND(ValMax,3) FROM SATCatTasaOCuota WHERE ROUND(ValMax,3) = CAST(@RetencionTasaOCuota as varchar(10)) AND Factor = @RetencionTipoFactor AND Retencion = 1)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@RetencionTasaOCuota,'')
FROM MensajeLista
WHERE Mensaje = 80347
IF @RetencionImporte < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + CAST(@RetencionImporte as varchar(25))
FROM MensajeLista
WHERE Mensaje = 80348
FETCH NEXT FROM cRetencion INTO @RetencionBase, @RetencionImpuesto, @RetencionTipoFactor, @RetencionTasaOCuota, @RetencionImporte
END
CLOSE cRetencion
DEALLOCATE cRetencion
END
/************************     I N F O R M A C I Ó N     A D U A N E R A     ***************************/
IF @Ok IS NULL
BEGIN
DECLARE cInfoAduanera CURSOR FOR
SELECT	[NumeroPedimento]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:InformacionAduanera',1)
WITH ([NumeroPedimento]		varchar(200)	'@NumeroPedimento'
)
OPEN cInfoAduanera
FETCH NEXT FROM cInfoAduanera INTO @NumeroPedimento
WHILE @@FETCH_STATUS = 0 AND @Ok IS NULL
BEGIN
IF @NumeroPedimento NOT LIKE ('[0-9][0-9]  [0-9][0-9]  [0-9][0-9][0-9][0-9]  [0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@NumeroPedimento,'')
FROM MensajeLista
WHERE Mensaje = 80349
FETCH NEXT FROM cInfoAduanera INTO @NumeroPedimento
END
CLOSE cInfoAduanera
DEALLOCATE cInfoAduanera
END
/*******************************     C U E N T A     P R E D I A L     ********************************/
IF @Ok IS NULL
BEGIN
DECLARE cCtaPredial CURSOR FOR
SELECT	[Numero]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:CuentaPredial',1)
WITH ([Numero]		decimal(18,6)	'@Numero'
)
OPEN cCtaPredial
FETCH NEXT FROM cCtaPredial INTO @CtaPredialNumero
WHILE @@FETCH_STATUS = 0 AND @Ok IS NULL
BEGIN
IF ISNUMERIC(@CtaPredialNumero) = 0 AND NULLIF(@CtaPredialNumero,'') IS NOT NULL
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@CtaPredialNumero,'')
FROM MensajeLista
WHERE Mensaje = 80350
FETCH NEXT FROM cCtaPredial INTO @CtaPredialNumero
END
CLOSE cCtaPredial
DEALLOCATE cCtaPredial
END
/******************************************     P A R T E     *****************************************/
IF @Ok IS NULL
BEGIN
DECLARE cParte CURSOR FOR
SELECT	[ClaveProdServ],
[NoIdentificacion],
[Cantidad],
[Unidad],
[Descripcion],
[ValorUnitario],
[Importe]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Conceptos/cfdi:Concepto/cfdi:Parte',1)
WITH ([ClaveProdServ]		varchar(8)		'@ClaveProdServ',
[NoIdentificacion]		varchar(100)	'@NoIdentificacion',
[Cantidad]				decimal(18,6)	'@Cantidad',
[Unidad]				varchar(20)		'@Unidad',
[Descripcion]			varchar(1000)	'@Descripcion',
[ValorUnitario]		decimal(18,6)	'@ValorUnitario',
[Importe]				decimal(18,6)	'@Importe'
)
OPEN cParte
FETCH NEXT FROM cParte INTO @ParteClaveProdServ, @ParteNoIden, @ParteCantidad, @ParteUnidad, @ParteDescripcion, @ParteValorUnitario, @ParteImporte
WHILE @@FETCH_STATUS = 0 AND @Ok IS NULL
BEGIN
IF NOT EXISTS(SELECT Clave FROM SATCatClaveProdServ WHERE Clave = @ParteClaveProdServ)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ParteClaveProdServ,'')
FROM MensajeLista
WHERE Mensaje = 80351
IF @Ok IS NULL
IF @ParteCantidad < 0.000001
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ParteCantidad,'')
FROM MensajeLista
WHERE Mensaje = 80353
IF @Ok IS NULL
IF @ParteValorUnitario < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ParteValorUnitario,'')
FROM MensajeLista
WHERE Mensaje = 80356
IF @Ok IS NULL
IF @ParteImporte < 0.000001
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ParteImporte,'')
FROM MensajeLista
WHERE Mensaje = 80357
FETCH NEXT FROM cParte INTO @ParteClaveProdServ, @ParteNoIden, @ParteCantidad, @ParteUnidad, @ParteDescripcion, @ParteValorUnitario, @ParteImporte
END
CLOSE cParte
DEALLOCATE cParte
END
/***********************************     I M P U E S T O S     ****************************************/
IF @Ok IS NULL OR @Ok IN (80342, 80347)
BEGIN
SELECT	@TotalImpRetenidos   = [TotalImpuestosRetenidos],
@TotalImpTrasladados = [TotalImpuestosTrasladados]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Impuestos',1)
WITH ([TotalImpuestosRetenidos]		decimal(18,6),
[TotalImpuestosTrasladados]	decimal(18,6)
)
IF @TotalImpRetenidos < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ParteImporte,'')
FROM MensajeLista
WHERE Mensaje = 80358
IF @TotalImpTrasladados < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ParteImporte,'')
FROM MensajeLista
WHERE Mensaje = 80359
END
/****************************     T O T A L     R E T E N C I O N     *********************************/
IF @Ok IS NULL
BEGIN
DECLARE cTotalRetencion CURSOR FOR
SELECT	[Impuesto],
[Importe]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Impuestos/cfdi:Retenciones/cfdi:Retencion',1)
WITH ([Impuesto]		varchar(3),
[Importe]			decimal(18,6)
)
OPEN cTotalRetencion
FETCH NEXT FROM cTotalRetencion INTO @TotRetImpuesto, @TotRetImporte
WHILE @@FETCH_STATUS = 0
BEGIN
IF @TotRetImpuesto NOT IN ('001','002','003')
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ParteImporte,'')
FROM MensajeLista
WHERE Mensaje = 80360
IF @TotRetImporte < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@ParteImporte,'')
FROM MensajeLista
WHERE Mensaje = 80361
SELECT @SumaTotRetImporte = ISNULL(@SumaTotRetImporte,0)+@TotRetImporte
FETCH NEXT FROM cTotalRetencion INTO @TotRetImpuesto, @TotRetImporte
END
CLOSE cTotalRetencion
DEALLOCATE cTotalRetencion
END
/****************************     T O T A L     T R A S L A D A D O    ********************************/
IF @Ok IS NULL
BEGIN
DECLARE cTotalTranslados CURSOR FOR
SELECT	[Impuesto],
[TipoFactor],
[TasaOCuota],
[Importe]
FROM	OPENXML (@iDatos, 'cfdi:Comprobante/cfdi:Impuestos/cfdi:Traslados/cfdi:Traslado',1)
WITH ([Impuesto]		varchar(8),
[TipoFactor]		varchar(100),
[TasaOCuota]		varchar(100),
[Importe]			varchar(100)
)
OPEN cTotalTranslados
FETCH NEXT FROM cTotalTranslados INTO @TotTrasImpuesto, @TotTrasTipoFactor, @TotTrasTasaOCuota, @TotTrasImporte
WHILE @@FETCH_STATUS = 0
BEGIN
IF @TotTrasImpuesto NOT IN ('001','002','003')
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TotTrasImpuesto,'')
FROM MensajeLista
WHERE Mensaje = 80362
IF NOT EXISTS(SELECT Descripcion FROM SATCatTipoFactor WHERE Descripcion = @TotTrasTipoFactor)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TotTrasTipoFactor,'')
FROM MensajeLista
WHERE Mensaje = 80363
IF NOT EXISTS (SELECT ValMax FROM SATCatTasaOCuota WHERE ValMax = CAST(@TotTrasTasaOCuota as varchar(10)) AND Factor = @TotTrasTipoFactor AND Traslado = 1)
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TotTrasTasaOCuota,'')
FROM MensajeLista
WHERE Mensaje = 80364
IF @TotTrasImporte < 0.000000
SELECT @Ok = Mensaje, @OkRef = Descripcion +' Valor: ' + ISNULL(@TotTrasTasaOCuota,'')
FROM MensajeLista
WHERE Mensaje = 80365
SELECT @SumaTotTrasImporte = ISNULL(@SumaTotTrasImporte,0) + @SumaTotTrasImporte
FETCH NEXT FROM cTotalTranslados INTO @TotTrasImpuesto, @TotTrasTipoFactor, @TotTrasTasaOCuota, @TotTrasImporte
END
CLOSE cTotalTranslados
DEALLOCATE cTotalTranslados
END
/******************************************************************************************************/
EXEC sp_xml_removedocument @iDatos
SELECT @XML = REPLACE(@XML,'<cfdi:Impuestos/>','')
SELECT @XML = REPLACE(@XML,'<cfdi:Retenciones/>','')
SELECT @XML = REPLACE(@XML,'<cfdi:Traslados/>','')
SELECT @XML = REPLACE(@XML,'<cfdi:CuentaPredial/>','')
SELECT @XML = REPLACE(@XML,'<cfdi:InformacionAduanera />','')
/**********     VALIDACIONES ADICIONALES     ***********/
IF @Moneda = 'MXN'
BEGIN
SELECT @EDICOMTipoCambio = CAST(@TipoCambio AS DECIMAL(18,2))
SELECT @XML = REPLACE(@XML,'TipoCambio="'+CAST(@EDICOMTipoCambio AS varchar(50))+'"','TipoCambio="1"')
END
IF NOT EXISTS(SELECT * FROM Cte c JOIN FiscalRegimen f ON f.FiscalRegimen = c.FiscalRegimen WHERE c.RFC = @RfcReceptor AND f.Extranjero = 1)
BEGIN
SELECT @XML = REPLACE(@XML,'ResidenciaFiscal="'+ISNULL(@ResidenciaFiscal,'')+'"','')
END
/*********     SE AJUSTARAN LOS IMPORTES POR TEMAS DE REDONDEOS     *********/
IF ABS(((ISNULL(@Subtotal,0) - ISNULL(@Descuento,0))+(ISNULL(@TotalImpTrasladados,0)-ISNULL(@TotalImpRetenidos,0))) - @Total) <= 1 AND
ABS(((ISNULL(@Subtotal,0) - ISNULL(@Descuento,0))+(ISNULL(@TotalImpTrasladados,0)-ISNULL(@TotalImpRetenidos,0))) - @Total) > 0
BEGIN
SELECT @DiferenciaCentavos = ((@Subtotal - @Descuento)+(@TotalImpTrasladados-@TotalImpRetenidos)) - @Total
SELECT @XML = REPLACE(@XML, dbo.fnXMLDecimal('Total',@Total, @CfgDecimales), dbo.fnXMLDecimal('Total',ISNULL(@Subtotal,0)-ISNULL(@Descuento,0)+(ISNULL(@TotalImpTrasladados,0)-ISNULL(@TotalImpRetenidos,0)), @CfgDecimales))
END
END
GO