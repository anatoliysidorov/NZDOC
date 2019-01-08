DECLARE

v_result number;
v_errorCode number;
v_errorMessage nclob;

v_statement varchar2(2000);
v_table_name varchar2(255);
v_processor_code varchar2(255);
v_status varchar2(255);
v_type varchar2(255);
v_count number;
cur                SYS_REFCURSOR;
BEGIN

v_errorCode := 0;
v_errorMessage := '';


:ErrorCode := v_errorCode;
:ErrorMessage := v_errorMessage;


FOR REC IN (
    select distinct(table_name) TableName 
    from all_tab_columns 
    WHERE (upper(table_name) LIKE 'TBL_DICT_%' 
    or upper(table_name) 
    in ('TBL_AC_ACCESSOBJECTTYPE', 'TBL_AC_PERMISSION')) and upper(table_name) not in ('TBL_DICT_CASESYSTYPE', 'DICT_CUSTOMCATEGORY','DICT_CUSTOMWORD',
																						'DICT_DCMTYPE',
																						'DICT_STATECONFIG',
																						'DICT_TAGOBJECT',
																						'DICT_TAGTOTAGOBJECT',
																						'DICT_CASEROLE')
   AND owner = UPPER((SELECT VALUE FROM CONFIG WHERE NAME = 'ENV_SCHEMA'))
    order by 1
    )
LOOP
  v_table_name := rec.TableName;
  v_statement   := 'SELECT count(1) FROM ' || v_table_name;
  --DBMS_OUTPUT.PUT_LINE(v_statement);
  OPEN cur FOR v_statement;
  LOOP
  FETCH cur INTO v_count;
  EXIT WHEN cur%NOTFOUND;         
       -- DBMS_OUTPUT.PUT_LINE( 'Table: '||v_table_name||' has undeployed rule: '||v_processor_code);
  		 if v_count < 1 THEN
       v_errorCode := 128;
        v_errorMessage := v_errorMessage || '<li>Table: '||v_table_name||' has less then 1 record</li>';
      END IF;  
  END LOOP; 
  CLOSE cur;
END LOOP;

:ErrorCode := v_errorCode;
:ErrorMessage := v_errorMessage;
END;