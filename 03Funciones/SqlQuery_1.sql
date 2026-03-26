SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='fn' AND NAME='fnSAMSuprAddenda')
DROP FUNCTION fnSAMSuprAddenda
GO
CREATE FUNCTION fnSAMSuprAddenda(@DataXML VARCHAR(MAX),@etiqueta VARCHAR(255))
RETURNS XML
AS
BEGIN
	
	 DECLARE @OpeningTag NVARCHAR(255) = '<' + @etiqueta + '>',
	         @ClosingTag NVARCHAR(255) = '</' + @etiqueta + '>',
	         @StartPos INT,
	         @EndPos INT,
	         @LengthToRemove INT,
	         @NuevoXML  VARCHAR(MAX)
	 
	 --Reemplaza prefijo cfdi: del xml
	 SET @NuevoXML=REPLACE(@DataXML,'cfdi:','')

    -- Buscar la primera ocurrencia de la etiqueta
    SET @StartPos = CHARINDEX(@OpeningTag, @NuevoXML);

    -- Bucle para eliminar todas las ocurrencias de la etiqueta
    WHILE @StartPos > 0
    BEGIN
        -- Buscar la etiqueta de cierre correspondiente
        SET @EndPos = CHARINDEX(@ClosingTag, @NuevoXML, @StartPos);

        IF @EndPos > 0
        BEGIN
            -- Calcular la longitud del texto entre etiquetas
            SET @LengthToRemove = @EndPos - @StartPos + LEN(@ClosingTag);

            -- Eliminar el texto entre etiquetas utilizando STUFF
            SET @NuevoXML = STUFF(@NuevoXML, @StartPos, @LengthToRemove, @OpeningTag + @ClosingTag);
            
            -- Buscar la siguiente etiqueta
            SET @StartPos = CHARINDEX(@OpeningTag, @NuevoXML, @StartPos + 1);
        END
        ELSE
        BEGIN
            -- Etiqueta de cierre no encontrada, salir
            BREAK;
        END
    END

    RETURN CAST(@NuevoXML AS XML)
END


