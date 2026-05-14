SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='fn' AND NAME='fnSAMEliminarAddendaXML')
DROP FUNCTION fnSAMEliminarAddendaXML
GO

CREATE FUNCTION dbo.fnSAMEliminarAddendaXML (@XMLString NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @PosInicio INT;
    DECLARE @PosFin INT;
    DECLARE @EtiquetaInicio NVARCHAR(100);
    DECLARE @EtiquetaCierre NVARCHAR(100);
    DECLARE @Resultado NVARCHAR(MAX);

    SET @Resultado = @XMLString;

    -- 1. Encontrar la posición de "<" + cualquier prefijo + ":Addenda"
    -- Usamos CHARINDEX con un comodín parcial si fuera necesario, 
    -- pero buscaremos la estructura común "Addenda"
    SET @PosInicio = CHARINDEX('<', @Resultado, CHARINDEX(':Addenda', @Resultado) - 10);
    
    -- Si no encuentra "Addenda", salir
    IF @PosInicio = 0 OR CHARINDEX('Addenda', @Resultado) = 0
        RETURN @Resultado;

    -- 2. Encontrar el cierre de la etiqueta inicial ">"
    SET @PosInicio = CHARINDEX('<', @Resultado, CHARINDEX(':Addenda', @Resultado) - 10);
    SET @PosFin = CHARINDEX('>', @Resultado, @PosInicio);

    -- 3. Identificar el prefijo/nombre completo de la etiqueta de cierre </...Addenda>
    -- Tomamos la parte entre < y > para ver si tiene prefijo
    DECLARE @TagCompleto NVARCHAR(100);
    SET @TagCompleto = SUBSTRING(@Resultado, @PosInicio + 1, @PosFin - @PosInicio - 1);
    
    -- Extraer el nombre de la etiqueta (ej. "cfdi:Addenda" o "Addenda")
    DECLARE @NombreEtiqueta NVARCHAR(100);
    SET @NombreEtiqueta = CASE 
        WHEN CHARINDEX(' ', @TagCompleto) > 0 THEN LEFT(@TagCompleto, CHARINDEX(' ', @TagCompleto) - 1)
        ELSE @TagCompleto
    END;

    SET @EtiquetaCierre = '</' + @NombreEtiqueta + '>';

    -- 4. Encontrar la etiqueta de cierre real
    SET @PosFin = CHARINDEX(@EtiquetaCierre, @Resultado, @PosInicio);

    IF @PosFin > 0
    BEGIN
        -- 5. Eliminar desde <Addenda...> hasta el final de </...Addenda>
        -- Usamos SUBSTRING para reconstruir la cadena sin la addenda
        SET @Resultado = SUBSTRING(@Resultado, 1, @PosInicio - 1) + 
                         SUBSTRING(@Resultado, @PosFin + LEN(@EtiquetaCierre), LEN(@Resultado));
 
    END
    
    IF CHARINDEX('</cfdi:Addenda>',@Resultado) > 1
        SET @Resultado=REPLACE(@Resultado,'</cfdi:Addenda>','')

    RETURN @Resultado;
END;
GO
