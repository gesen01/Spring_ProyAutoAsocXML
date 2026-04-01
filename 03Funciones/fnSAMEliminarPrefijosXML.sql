SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='fn' AND NAME='fnSAMEliminarPrefijosXML')
DROP FUNCTION fnSAMEliminarPrefijosXML
GO

CREATE FUNCTION dbo.fnSAMEliminarPrefijosXML (@xml NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Pos            INT = CHARINDEX(':', @xml)    

    WHILE @Pos > 0
    BEGIN
        -- Verificamos que el ':' esté dentro de una etiqueta <...>
        -- Buscamos el inicio de la etiqueta '<' o '</' hacia atrás
        DECLARE @Start INT = @Pos
        WHILE @Start > 1 AND SUBSTRING(@xml, @Start, 1) NOT IN ('<','/',' ','xmlns',',','"','|','{','}','[',']',''',','*','(',')')   
            SET @Start = @Start - 1

        -- Si encontramos el inicio de un prefijo dentro de un tag, lo removemos
        IF SUBSTRING(@xml, @Start, 1) IN ('<', '/', ' ')
            SET @xml = STUFF(@xml, @Start + 1, @Pos - @Start, '')
        ELSE
            -- Si el ':' no es de un prefijo (ej. en un atributo), saltamos al siguiente
            SET @Pos = @Pos + 1
            
        SET @Pos = CHARINDEX(':', @xml, @Pos)
    END
    
    RETURN @xml
END
