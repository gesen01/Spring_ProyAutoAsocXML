CREATE TABLE AsociadoXMLSAM(
      ID                INT IDENTITY(1,1) NOT NULL,
      Nombre            VARCHAR(255),
      Folio             VARCHAR(15),
      Importe           FLOAT,
      RFC               VARCHAR(15),
      Tipo              VARCHAR(30),
      UUID              VARCHAR(50),
      FechaTimbrado	    DATETIME,
      FechaRegistro     DATETIME,
      Asociado          BIT DEFAULT 0
      
      CONSTRAINT pkAsociadoXMLSAM PRIMARY KEY (ID) 
)