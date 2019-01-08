declare
  v_input      xmltype;
  v_paramname  nvarchar2(255);
  v_paramvalue nvarchar2(32000);
  v_result     varchar2(32000);
  v_sql_str    varchar2(32000);
  buf2         nvarchar2(8000);
  v_tmp_xml    XMLTYPE;
  v_path      VARCHAR2(2555); 
  v_count     Integer;
  v_count1    Integer;
  attrname    nvarchar2(255);
  attrvalue   nvarchar2(255);
  v_formname  nvarchar2(255);
begin
  v_result := :Input;
  v_input := XMLType(v_result);
  v_formname := :FormName;
  v_paramname := :ParamName;
  v_paramvalue := :ParamValue;

  v_paramvalue := dbms_xmlgen.convert(v_paramvalue, dbms_xmlgen.ENTITY_ENCODE);  
  v_path := '/CustomData/Attributes/Form[@name="'||v_formname||'"]/'||v_paramname||'/text()';
  v_sql_str := 'SELECT updateXML(XMLTYPE('''||v_input.getStringVal()||'''),'''||v_path||''','''||v_paramvalue||''') FROM dual';
  
  EXECUTE IMMEDIATE v_sql_str INTO v_tmp_xml;
  
  RETURN v_tmp_xml.getClobVal();
end;