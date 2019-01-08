DECLARE

v_TaskEventMoment number;    
v_TaskEventType number;
v_id number;
v_affectedRows number;

CURSOR c1 IS SELECT s1.name as vname, s1."LEVEL" as vlevel, s2.name as cname, s2."LEVEL" as clevel
FROM (SELECT regexp_substr(:ParameterCodes_SV,'[^|||]+', 1, level) as name, level as "LEVEL" FROM dual
WHERE level BETWEEN 1 AND 100
CONNECT BY regexp_substr(:ParameterCodes_SV, '[^|||]+', 1, level) is not null) s1
inner join (select regexp_substr(:ParameterValues_SV,'[^|||]+', 1, level) as name, level as "LEVEL" from dual
WHERE level BETWEEN 1 and 100   
CONNECT BY regexp_substr(:ParameterValues_SV, '[^|||]+', 1, level) is not null) s2
ON s1."LEVEL" = s2."LEVEL"
ORDER BY clevel, cname;

BEGIN

  BEGIN
  	SELECT t1.col_id INTO v_TaskEventMoment FROM tbl_dict_taskeventmoment t1 WHERE t1.col_code = UPPER(:TaskEventMoment_Code);
  	SELECT t1.col_id INTO v_TaskEventType FROM tbl_dict_taskeventtype t1 WHERE t1.col_code = UPPER(:TaskEventType_Code);
  
      INSERT INTO tbl_taskevent (COL_PROCESSORCODE, COL_TASKEVENTTASKSTATEINIT, COL_TASKEVENTMOMENTTASKEVENT, COL_TASKEVENTTYPETASKEVENT, col_code)
      VALUES (:ProcessorCode, :TaskStateInit, v_TaskEventMoment, v_TaskEventType, sys_guid())
      RETURNING col_id INTO v_id;
      
      v_affectedRows := 1;
        
	IF :ParameterCodes_SV IS NOT NULL then
      FOR rec1 IN c1 LOOP
    
         INSERT INTO tbl_autoruleparameter (col_paramcode, col_ParamValue, col_taskeventautoruleparam, col_code)
         VALUES (rec1.VNAME, rec1.CNAME, v_id, sys_guid());
         v_affectedRows := v_affectedRows + 1;
         
      END LOOP;
	END IF;
	
      :recordId := v_id;
      :affectedRows := v_affectedRows;
      :ErrorCode := 0;
      :ErrorMessage := 'Success';
      
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    :recordId := 0;
    :affectedRows := 0;
    :ErrorCode := 1;
    :ErrorMessage := 'No data found';
  WHEN DUP_VAL_ON_INDEX THEN
    :recordId := 0;
    :affectedRows := 0;
    :ErrorCode := 2;
    :ErrorMessage := 'Dup val on index';
  WHEN OTHERS THEN
    :recordId := 0;
    :affectedRows := 0;
    :ErrorCode := 3;
    :ErrorMessage :=SQLERRM;
  END;

END;