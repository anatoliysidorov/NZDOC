DECLARE
	v_Count NUMBER;
	v_Res NCLOB;
BEGIN
	SELECT COUNT(*), XMLAGG(XMLELEMENT("ITEM", XMLELEMENT("ID", id1),XMLELEMENT("NAME",name1),XMLELEMENT("VALUE",value1))).getclobval()
	INTO v_Count, v_Res 
	FROM (SELECT c1.rn as id1, name1, value1
		 FROM (SELECT rownum as rn, COLUMN_VALUE as name1 FROM TABLE(ASF_SPLITCLOB(:Names_CSV, ','))) c1
			   LEFT JOIN (SELECT ROWNUM as rn, COLUMN_VALUE as value1 FROM TABLE(ASF_SPLITCLOB(:Values_CSV, ','))  )  v 
	ON c1.rn=v.rn);
	v_Res := '<?xml version="1.0" encoding="UTF-8"?><dataset><RESULTS>' || v_Count || '</RESULTS>' || v_Res || '</dataset>';

	RETURN v_Res;
END;