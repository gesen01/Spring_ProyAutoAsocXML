SELECT *
FROM TablaStD AS ts
WHERE ts.TablaSt='PrefijosXML'

DELETE FROM TablastD WHERE TablaSt='PrefijosXML'

INSERT INTO TablaSt
VALUES('PrefijosXML')
GO

INSERT INTO TablaStD
VALUES('PrefijosXML','cfdi:',1)
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','tfd:','2')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','xmlns:','3')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','xsi:','4')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','pago10:','5')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','pago20:','6')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','cartaporte20:','7')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','cartaporte30:','8')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','cartaporte31:','9')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','if:','10')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','tp:','11')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','registrofiscal:','12')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','donat:','12')
GO
INSERT INTO TablaStD
VALUES('PrefijosXML','ecfd:','13')
GO

DECLARE @cadena VARCHAR(MAX)

SET @cadena=''

SELECT @cadena=@cadena+Prefijo+':,'
FROM SAMPrefijosXML

SELECT @cadena=SUBSTRING(@cadena,0,LEN(@cadena))

SELECT @cadena='%['+@cadena+']%'

SELECT @cadena




