CREATE TABLE AsocXMLSAMLog(
     ID                 INT IDENTITY(1,1) NOT NULL,
     Nombre 	        VARCHAR(255),
     Proveedor          VARCHAR(15),
     FechaExpedicion    DATETIME,
     Estatus            VARCHAR(15),
     Descripcion        VARCHAR(150),
     FechaProceso       DATETIME
     
     CONSTRAINT pkAsocXMLSAMLog PRIMARY KEY (ID)
)

EXEC spALTER_TABLE 'AsocXMLSAMLog',' FechaExpedicion DATETIME NULL'