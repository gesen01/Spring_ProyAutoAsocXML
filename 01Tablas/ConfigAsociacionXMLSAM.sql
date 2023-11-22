CREATE TABLE ConfigAsociacionXMLSAM(
    Empresa			   VARCHAR(5)	    NOT NULL,
    RutaRepositorioProc	   VARCHAR(150)    NULL,
    RutaRepositorioVal	   VARCHAR(150)    NULL,
    RutaRepositorioInVal	   VARCHAR(150)    NULL,
    AlmacenarXML		   BIT DEFAULT 0,
    AlmacenarPDF		   BIT DEFAULT 0,
    RutaAsoc			   VARCHAR(150)    NULL,
    FechaModificacion	   DATETIME
    
    CONSTRAINT pkConfigAsociacionXMLSAM PRIMARY KEY (Empresa)
)