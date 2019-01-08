declare
	v_tmpXML3    xmltype;
	v_tmpXML2    xmltype;
	v_tmpXML     xmltype;
    v_result     varchar2(32000);
    v_result2    varchar2(32000);
    v_result3    varchar2(32000);
begin
  v_result := :Input;
  v_result2 := :Input2;
  if v_result is null then
    v_result := '<CustomData><Attributes></Attributes></CustomData>';
  end if;
  if v_result2 is null then
    v_result2 := '<CustomData><Attributes></Attributes></CustomData>';
  end if;
  v_result := dbms_xmlgen.convert(v_result, dbms_xmlgen.ENTITY_DECODE);
  v_result2 := dbms_xmlgen.convert(v_result2, dbms_xmlgen.ENTITY_DECODE);
  v_result3 := '<CustomData><Attributes></Attributes></CustomData>';
  v_tmpXML3 := XMLTYPE(v_result3); 
  v_tmpXML2 := XMLTYPE(v_result2);
  v_tmpXML := XMLTYPE(v_result);
	
FOR rec IN (SELECT regexp_substr(form_name,'<Form name="(.*?)"/>',1,LEVEL,'i',1) FM FROM  
									(
									SELECT 
									XMLQuery ('for $e in $p/CustomData/Attributes/Form[@name]
										 return <Form name ="{$e/@name}"/>'
									 PASSING v_tmpXML2 AS "p"  
									RETURNING CONTENT
									) AS form_name
									FROM dual
									) 
CONNECT BY regexp_substr(form_name,'<Form name="(.*?)"/>',1,LEVEL,'i',1) IS NOT NULL) LOOP

SELECT deleteXML(v_tmpXML, 
                '/CustomData/Attributes/Form[@name="'||rec.FM||'"]')
INTO 	v_tmpXML							
FROM dual;

END LOOP;

IF v_tmpXML IS NOT NULL THEN 
		SELECT APPENDCHILDXML(v_tmpXML3,
                             'CustomData/Attributes',
                               XMLQuery('$p/CustomData/Attributes/Form' PASSING v_tmpXML AS "p" RETURNING CONTENT) 
                              )
		INTO v_tmpXML3
		FROM DUAL;
END IF;


SELECT APPENDCHILDXML(v_tmpXML3,
                     'CustomData/Attributes',
                     XMLQuery('$p/CustomData/Attributes/Form' PASSING v_tmpXML2 AS "p" RETURNING CONTENT)
                     )
INTO v_tmpXML3
FROM DUAL;


	IF v_tmpXML3 IS NOT NULL THEN 
     RETURN v_tmpXML3.getClobVal();
    ELSE 
	 RETURN NULL;
	END IF;	


end;