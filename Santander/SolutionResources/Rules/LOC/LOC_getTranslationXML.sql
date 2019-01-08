DECLARE
  v_XmlData NCLOB;
  v_KeyId   TBL_LOC_KEY.COL_ID%TYPE;
  v_LangId  TBL_LOC_LANGUAGES.COL_ID%TYPE;
BEGIN
  v_KeyId := :KeyID;
  v_LangId := :LangID;
  v_XmlData := '<xmlData></xmlData>';
  IF (v_LangId IS NOT NULL AND v_KeyId IS NOT NULL)
  THEN
    BEGIN
      SELECT XMLElement("xmlData", 
               XMLAGG(
                 XMLElement("record", 
                   XMLElement("ID", tbl.COL_ID),
                   XMLElement("KEYID", tbl.COL_KEYID),
                   XMLElement("LANGID", tbl.COL_LANGID),
                   XMLElement("PLURALFORM", tbl.COL_PLURALFORM),
                   XMLElement("VALUE", XMLCDATA(tbl.COL_VALUE))
                 )
               )
             ).getclobval()
        INTO v_XmlData
        FROM TBL_LOC_TRANSLATION tbl
       WHERE tbl.COL_LANGID = v_LangId 
         AND tbl.COL_KEYID = v_KeyId;
    END;
  END IF;
  RETURN v_XmlData;
END;