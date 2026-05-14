DECLARE @TotalSinProcesar	INT
		,@Debug				BIT=0 --apagar si no se va utilizat el debug en el proceso

--Paso 1. Borra las tabla que tiene la lectura de los RFC con archivos faltantes de procesar en caso de tener algún rastrop de otra ejecución de proceso
IF @Debug=0
	TRUNCATE TABLE SAMCantidadDocsXMLproc

--Paso 1. Procesa todos los rfc de la carpeta de proveedores
IF @Debug=0
	EXEC xpProcesaXMLSAM 'SAM'
ELSE
	EXEC xpProcesaXMLSAMDebug 'SAM',@Debug

--Paso 2. La tabla de documentos sin procesar se llena con aquellos numeros de documentos que no fueron procesados
IF NOT EXISTS(SELECT 1 FROM SAMCantidadDocsXMLproc)
	EXEC xpSAMDocsXMLsinProc 'SAM'

--Paso 3. cuenta el de numero de RFC que requieren que se vuelvan a procesar
SELECT @TotalSinProcesar=COUNT(RFC)
FROM SAMCantidadDocsXMLproc
WHERE NumDocs > 0

--SELECT @TotalSinProcesar
--Paso 4. Mientras el numero de documentos a procesar en las distintas caroetas de RFC sea diferente de 0 se analizaran y procesaran
WHILE @TotalSinProcesar <> 0
BEGIN 
	
	IF @Debug=0
		EXEC xpProcesaXMLSAM 'SAM'
	ELSE		
		EXEC xpProcesaXMLSAMDebug 'SAM',@Debug

	IF EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Estatus='NoProcesado' AND Descripcion NOT LIKE '%SATXML%' AND Descripcion NOT LIKE '%900010%'  AND Descripcion NOT LIKE '%6355%')
		SELECT @TotalSinProcesar=0
	ELSE
	BEGIN
		EXEC xpSAMDocsXMLsinProc 'SAM'
	
		SELECT @TotalSinProcesar=COUNT(RFC)
		FROM SAMCantidadDocsXMLproc
		WHERE NumDocs > 0
		-- Se valida que si el numero de RFC a procesar son menos o igual a 20 termina el ciclo ya que pueden haber quedado algunas carpetas con archivos que tienen errores 
		--y debido a esos errores no lo va a mover si no hasta que se corrigan asegurando que se finalice el proceso con un numero manejable de carpetas por procesar
		IF @TotalSinProcesar <= 20
			SELECT @TotalSinProcesar=0
	END
END 