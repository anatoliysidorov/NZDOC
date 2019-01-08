declare
  v_input      xmltype;
  v_paramname  nvarchar2(255);
  v_paramvalue nvarchar2(255);
  v_eventid    Integer;
  v_eventproc  nvarchar2(255);
  v_stateid    Integer;
  v_result     varchar2(32000);
  doc          DBMS_XMLDOM.DOMDocument;
  ndoc         DBMS_XMLDOM.DOMNode;
  v_temp_str   VARCHAR2(32000);
  v_temp_xml   XMLTYPE;
begin
   v_result := :Input;
  v_input := XMLType(v_result);
  v_paramname := :ParamName;
  v_paramvalue := :ParamValue;
  v_eventid := :EventId;
  v_eventproc := :EventProc;
  v_stateid := :StateId;

  v_paramvalue := dbms_xmlgen.convert(v_paramvalue, dbms_xmlgen.ENTITY_ENCODE);


  IF v_eventid IS NOT NULL THEN
   v_temp_str := ' EventId = "'||to_char(v_eventid)||'"';
  END IF;

  IF v_eventproc IS NOT NULL THEN
  v_temp_str := NVL(v_temp_str,' ')||'ProcessorCode = "'||to_char(v_eventproc)||'"';
  END IF;

  IF v_stateid IS NOT NULL THEN
  v_temp_str := NVL(v_temp_str,' ')||'StateId = "'||to_char(v_stateid)||'"';
  END IF;

  SELECT APPENDCHILDXML(v_input,
                     'Parameters',
                     XMLType('<'||v_paramname||v_temp_str||'>'||v_paramvalue||'</'||v_paramname||'>' ) )
INTO v_temp_xml
FROM DUAL;

  return v_temp_xml.getClobVal();

end;