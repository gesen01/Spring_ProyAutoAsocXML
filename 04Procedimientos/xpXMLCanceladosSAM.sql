SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO

IF EXISTS(SELECT * FROM sysobjects WHERE TYPE='p' AND NAME='xpXMLCanceladosSAM')
DROP PROCEDURE xpXMLCanceladosSAM
GO
CREATE PROCEDURE xpXMLCanceladosSAM
@XML		VARCHAR(MAX),
@OK			INT=NULL	OUTPUT,
@OKRef		VARCHAR(255)=NULL OUTPUT
AS
BEGIN
	DECLARE @Clave	VARCHAR(10),
			@Etiqueta	VARCHAR(255),
			@EstatusUUID	INT,
			@NumClaves	INT,
			@Contador	INT=1
	
	DECLARE @ClavesCancelacion TABLE (
		ID		INT IDENTITY (1,1) NOT NULL,
		clave	VARCHAR(10)
	)
	
	INSERT INTO @ClavesCancelacion
	SELECT tsd.Valor
	FROM TablaSt AS ts
	JOIN TablaStD AS tsd ON tsd.TablaSt = ts.TablaSt
	WHERE ts.TablaSt='Claves Cancelacion XML'
	
	SELECT @NumClaves=COUNT(ID)
	FROM @ClavesCancelacion AS cc
	
	IF ISNULL(@NumClaves,0) <> 0
	BEGIN
		WHILE @Contador<=@NumClaves
		BEGIN
			SELECT @Clave=cc.clave
			FROM @ClavesCancelacion AS cc
			WHERE ID=@Contador
			
			SELECT @Etiqueta='<EstatusUUID>'+@Clave+'</EstatusUUID>'
			
			SELECT @EstatusUUID=CHARINDEX(@Etiqueta,@XML,1)
			
			IF @EstatusUUID=0
			BEGIN
				BREAK
			END	
			ELSE
			BEGIN
				SELECT @OK=@EstatusUUID,@OKRef=@Clave
				BREAK
			END	 
			
			SET @Contador=@Contador+1
		END
	END 
	
	
RETURN
END