declare
  v_input     xmltype;
  v_formname  nvarchar2(255);
  v_paramname nvarchar2(255);
  v_param     nvarchar2(255);
  v_result    varchar2(32000);
  v_count     Integer;
  v_count1    Integer;
  v_temp_xml  xmltype;
  v_path      VARCHAR2(800);
  attrname    nvarchar2(255);
  attrvalue   nvarchar2(255);
  buf         nvarchar2(8000);
  buf2        nvarchar2(8000);

begin
  v_result := :Input;
  v_param := :Param;

  if v_result is null then
     RETURN NULL; 
  end if;

  if (instr(v_result, '<?xml') = 0) then
    v_result := '<?xml version="1.0" encoding="US7ASCII"?>' || v_result;
  end if;
  v_input := XMLType(v_result);

  v_count := regexp_instr(v_param, '/+', 1, 1, 0, 'i');
  v_formname := substr(v_param, 1, v_count-1);
  v_count1 := regexp_instr(v_param, '/+', 1, 1, 1, 'i');
  v_paramname := substr(v_param, v_count1, length(v_param) - v_count1 + 1);

  v_path := '$p//'||v_param||'/text()';
    SELECT 
    XMLQuery(v_path
                    PASSING v_input AS "p" RETURNING CONTENT)
    INTO   v_temp_xml             
    FROM dual;			
    
    IF v_temp_xml IS NOT NULL THEN 
      return v_temp_xml.getClobVal();
    ELSE 
	RETURN NULL;  
    END IF;  

end;