declare
  v_input      xmltype;
  v_tmp        xmltype;
  v_paramname  nvarchar2(255);
  v_paramvalue nvarchar2(32000);
  v_result     varchar2(32000);
  v_temp_xml   XMLTYPE;
  buf          NVARCHAR2(32000);


begin
  v_result := :Input;
  v_input := XMLType(dbms_xmlgen.convert(v_result, dbms_xmlgen.ENTITY_DECODE));
  v_paramname := :ParamName;
  v_paramvalue := :ParamValue;
  if instr(v_paramvalue, '<![CDATA[') = 0 then
    v_paramvalue := '<![CDATA[' || v_paramvalue || ']]>';
  end if;

  v_paramvalue := dbms_xmlgen.convert(v_paramvalue, dbms_xmlgen.ENTITY_ENCODE);

BEGIN

	SELECT deleteXML(v_input,
											XMLType('/CustomData/Attributes/'||v_paramname)
												)
	INTO v_temp_xml
	FROM DUAL;

EXCEPTION WHEN OTHERS THEN
  v_temp_xml := v_input;
END;

v_tmp := XMLType('<' || v_paramname || '>' || v_paramvalue || '</' || v_paramname || '>');

SELECT APPENDCHILDXML(v_temp_xml,
                     'CustomData/Attributes',
                     v_tmp)
INTO v_temp_xml
FROM DUAL;

  return v_temp_xml.getClobVal();

end;