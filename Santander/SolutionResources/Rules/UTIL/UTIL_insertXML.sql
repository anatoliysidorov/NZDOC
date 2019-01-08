DECLARE
    v_rn NUMBER;
    v_inputXML NCLOB;
BEGIN
    v_inputXML := :inputXML;
    INSERT INTO tbl_importXML(COL_XMLDATA, col_CMSPATH)
              VALUES(v_inputXML, :cmsPath)
    RETURNING col_id
    INTO v_rn;
	
    :newId := v_rn;
END;