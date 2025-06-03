CREATE TABLE AsociadoXMLSAM(
      ID                INT IDENTITY(1,1) NOT NULL,
      Nombre            VARCHAR(255)    NULL,
      Folio             VARCHAR(15)     NULL,
      Importe           FLOAT           NULL,
      RFC               VARCHAR(15)     NULL,
      Tipo              VARCHAR(30)     NULL,
      UUID              VARCHAR(50)     NULL,
      FechaTimbrado	    DATETIME        NULL,
      FechaRegistro     DATETIME        NULL,
      Asociado          BIT DEFAULT 0
      
      CONSTRAINT pkAsociadoXMLSAM PRIMARY KEY (ID) 
)