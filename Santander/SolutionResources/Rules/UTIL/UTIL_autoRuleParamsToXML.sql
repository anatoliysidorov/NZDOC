  DECLARE
    v_Count NUMBER;
    v_XML_data NCLOB;
  BEGIN
    select count(*), XMLAGG(XMLELEMENT("ITEM", XMLELEMENT("ID", COL_ID),XMLELEMENT("PARAMVALUE",COL_PARAMVALUE),XMLELEMENT("PARAMCODE",COL_PARAMCODE),XMLELEMENT("PARAMVALUE",COL_PARAMVALUE))).getclobval()
    INTO v_Count, v_XML_data 
    from TBL_AUTORULEPARAMETER
    WHERE col_TaskEventAutoRuleParam = :TaskEvent;
    v_XML_data := '<?xml version="1.0" encoding="UTF-8"?><dataset><RESULTS>' || v_Count || '</RESULTS>' || v_XML_data || '</dataset>';
    RETURN v_XML_data;
  END;