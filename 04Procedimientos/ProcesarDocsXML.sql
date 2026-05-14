DECLARE @TotalSinProcesar	INT

--Paso 1. Procesa todos los rfc de la carpeta de proveedores
--EXEC xpProcesaXMLSAMDebug 'sam',1

--Paso 2. La tabla de documentos sin procesar se llena con aquellos numeros de documentos que no fueron procesados
IF NOT EXISTS(SELECT 1 FROM SAMCantidadDocsXMLproc)
	EXEC xpSAMDocsXMLsinProc 'SAM'

--Paso 3. cuenta el de numero de RFC que requieren que se vuelvan a procesar
SELECT @TotalSinProcesar=COUNT(RFC)
FROM SAMCantidadDocsXMLproc
WHERE NumDocs=4

SELECT @TotalSinProcesar
WHILE @TotalSinProcesar IS NOT NULL
BEGIN 
	--Paso 4. Procesa aquellos RFC faltantes
	EXEC xpProcesaXMLSAMDebug 'sam',1

	IF EXISTS(SELECT 1 FROM AsocXMLSAMLog WHERE Estatus='NoProcesado' AND Descripcion NOT LIKE '%SATXML%' AND Descripcion NOT LIKE '900010%')
		SELECT @TotalSinProcesar=NULL
	ELSE
	BEGIN
		EXEC xpSAMDocsXMLsinProc 'SAM'
	
		SELECT @TotalSinProcesar=COUNT(RFC)
		FROM SAMCantidadDocsXMLproc
		WHERE NumDocs=4
	END
END 