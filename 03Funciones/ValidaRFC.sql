SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='fn' AND NAME='ValidaRFC')
DROP FUNCTION ValidaRFC
GO
CREATE  FUNCTION [dbo].[ValidaRFC] 
(
    @RFC as VARCHAR(15) --No necesitas que sea tan largo
)
RETURNS BIT
AS
BEGIN
	DECLARE @Resultado bit
	
    IF EXISTS(  SELECT *
                FROM(VALUES(10, '[A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][0-9][0-9]', 5), --Persona física sin homoclave
                           (13, '[A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][0-9][0-9][A-Z0-9][A-Z0-9][A-Z0-9]', 5), --Persona física con homoclave
                           (12, '[A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][0-9][0-9][A-Z0-9][A-Z0-9][A-Z0-9]', 4) --Persona moral (siempre lleva homoclave)
                           )x(longitud, patron, iniciofecha)
                WHERE longitud = LEN( @RFC) -- Escoge cual patrón usar
                AND   @RFC LIKE patron -- Valida que el RFC cumpla con el patrón de letras y números
                AND   CONVERT( date, SUBSTRING( @RFC, iniciofecha, 6), 12) IS NOT NULL -- Valida que la fecha sea real
               )
        SELECT @Resultado= CAST( 1 AS bit);
    ELSE 
        SELECT @Resultado= CAST( 0 AS bit);
        
    RETURN @Resultado
END