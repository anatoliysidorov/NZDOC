DECLARE 
--CREATE OR REPLACE PROCEDURE TEST_EXTRACT_CASE
--IS 
v_case_id     NUMBER := 24;
v_user        NVARCHAR2(255);
v_path        VARCHAR2(255);
v_xml_tmp     XMLTYPE;  
v_value       CLOB := EMPTY_CLOB();    
V_SQL         VARCHAR2(32000);
v_varcharvalue VARCHAR2(4000);   
BEGIN

v_case_id := :CaseId;
v_user    := :SchemaName;

IF  v_user IS NULL THEN 
  SELECT USER INTO v_user FROM dual;
END IF;   

FOR rec IN (SELECT col_id, col_origin_table_name, col_xml_data, col_date_move_to_hist, col_case_id 
            FROM TBL_HISTORY_CASE t WHERE col_case_id = v_case_id 
            AND col_xml_data IS NOT NULL
            ORDER BY col_origin_table_name DESC ) LOOP
  V_SQL := 'INSERT INTO '||rec.col_origin_table_name||chr(13)||chr(10);      
--  dbms_output.put_line('INSERT INTO '||rec.col_origin_table_name);
  V_SQL := V_SQL || '('; 
 -- dbms_output.put('(');
      FOR tbl_col IN (SELECT column_name ,  column_id, MAX(column_id) OVER(PARTITION BY TABLE_NAME) max_col_id FROM all_tab_columns WHERE owner = v_user
                                AND TABLE_NAME = rec.col_origin_table_name 
                                ORDER BY column_id ) LOOP
           V_SQL := V_SQL || tbl_col.column_name;                    
--          dbms_output.put( tbl_col.column_name);

        IF tbl_col.column_id != tbl_col.max_col_id THEN 
            V_SQL := V_SQL ||', ';
--         dbms_output.put(', '); 
        END IF;  
      END LOOP;
  V_SQL := V_SQL || ')';    
--  dbms_output.put_line(')');
  V_SQL := V_SQL || 'VALUES'||chr(13)||chr(10);    
--  dbms_output.put_line('VALUES');
  V_SQL := V_SQL ||'(';
--  dbms_output.put('('); 
      FOR tbl_col2 IN (SELECT column_name , data_type, data_precision, data_scale  , char_col_decl_length  , column_id, MAX(column_id) OVER(PARTITION BY TABLE_NAME) max_col_id FROM all_tab_columns WHERE owner = v_user
                                AND TABLE_NAME = rec.col_origin_table_name 
                                ORDER BY column_id ) LOOP
          v_path := '/ROW/'||tbl_col2.column_name||'/text()' ; 
         
         IF rec.col_xml_data.EXISTSNODE('ROW/'||tbl_col2.column_name) = 1 THEN 
          v_varcharvalue := extract_value_from_xml_xml(Input => rec.col_xml_data , Path => v_path);
             CASE WHEN tbl_col2.data_type IN ('NVARCHAR2', 'VARCHAR2') THEN 
                    V_SQL := V_SQL ||'q''$'||v_varcharvalue||'$''';
  --                  dbms_output.put_line('q''$'||v_varcharvalue||'$''');
                  WHEN tbl_col2.data_type = 'NUMBER' AND tbl_col2.data_precision IS NULL THEN 
  --                  dbms_output.put_line(v_varcharvalue);
                     V_SQL := V_SQL ||v_varcharvalue;
                  WHEN tbl_col2.data_type = 'NUMBER' AND tbl_col2.data_precision IS NOT NULL THEN     
                     V_SQL := V_SQL || 'to_number('''||v_varcharvalue||''','''||RPAD('9',tbl_col2.data_precision,'9')||'D'||LPAD('9',tbl_col2.data_scale,'9')||''','||q'$' NLS_NUMERIC_CHARACTERS = '',.'' ')$'; 
--                       dbms_output.put_line('to_number('''||v_varcharvalue||''','''||RPAD('9',tbl_col2.data_precision,'9')||'D'||LPAD('9',tbl_col2.data_scale,'9')||''','||q'$' NLS_NUMERIC_CHARACTERS = '',.'' ')$');
                  WHEN tbl_col2.data_type = 'DATE'  THEN     
                    V_SQL := V_SQL ||'to_date('''||v_varcharvalue||''','||'''DD-MON-RR'')';
--                      dbms_output.put_line('to_date('''||v_varcharvalue||''','||'''DD-MON-RR'')');
                  WHEN tbl_col2.data_type = 'XMLTYPE' THEN 
                    V_SQL := V_SQL || 'dbms_xmlgen.convert('''||v_varcharvalue||''',1)';
--                      dbms_output.put_line('dbms_xmlgen.convert('''||v_varcharvalue||''',1)');
                  WHEN tbl_col2.data_type IN ('NCLOB','CLOB') THEN   
                    V_SQL := V_SQL ||'q''$'||v_varcharvalue||'$''';
--                    dbms_output.put_line('q''$'||v_varcharvalue||'$''');
                  ELSE
                 NULL;   
             END CASE;          

          ELSE 
--          dbms_output.put('NULL');
          V_SQL := V_SQL || 'NULL' ;
          END IF;
          
        IF tbl_col2.column_id != tbl_col2.max_col_id THEN 
--         dbms_output.put(', '); 
           V_SQL := V_SQL ||', '; 
        END IF;  
                              
      END LOOP;      
--  dbms_output.put_line(');');
  V_SQL := V_SQL || ')' ; 
  EXECUTE IMMEDIATE V_SQL; 
END LOOP;    

END;
