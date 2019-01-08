DECLARE 
TYPE args IS RECORD 
(r_argument_name  user_arguments.ARGUMENT_NAME%TYPE,
r_POSITION        user_arguments.POSITION%TYPE,
r_arg_data_type   VARCHAR2(32),
r_in_out          VARCHAR2(32),
r_cnt_args        pls_integer
);
TYPE t_l_args IS TABLE OF args;
v_l_args               t_l_args;
v_cnt  PLS_INTEGER;
v_fun_invoker_name     VARCHAR2(255);
v_fun_ivoker_type      VARCHAR2(255);
v_fun_processor        VARCHAR2(255);
v_fun_processor_type   VARCHAR2(255);
v_line_source          PLS_INTEGER;
v_var_type             VARCHAR2(255);
v_arg_type             VARCHAR2(255);
v_col                  PLS_INTEGER;
v_col_name             VARCHAR2(255);
v_in_out_var_type      VARCHAR2(255);
v_cnt_func_args        NUMBER;
BEGIN
/****************************************************************************/
-- Execute immediate mast be on one row in function invoker. Any other case will generate error
/****************************************************************************/
v_fun_invoker_name := UPPER(:fun_invoker_name);
v_fun_ivoker_type  := upper(:fun_ivoker_type);
v_fun_processor    := UPPER(:fun_processor);
v_fun_processor_type  := UPPER(:fun_processor_type);

/*Check existing valid function processor_code*/

       SELECT COUNT(*)
			 INTO
			 v_cnt
			 FROM user_objects uo
			 WHERE uo.object_name = v_fun_processor
			 AND uo.object_type =  v_fun_processor_type;
						IF v_cnt = 0 THEN
							:ErrorCode := 101;
							:ErrorMessage := 'Event processor not found';
						RETURN -1;
						END IF;
/* */
SELECT ua.ARGUMENT_NAME, 
                   ua.POSITION, 
                   upper(ua.DATA_TYPE) arg_data_type, 
                   ua.in_out, COUNT(*) OVER() cnt_args
                   BULK COLLECT INTO v_l_args
              FROM user_arguments ua
              WHERE ua.OBJECT_NAME = v_fun_processor
              and not(argument_name is null and in_out = 'OUT' and position = 0)
              order by position;
              
FOR i IN v_l_args.first.. v_l_args.last LOOP
v_col_name := 'V_' || upper(v_l_args(i).r_argument_name);

            BEGIN
								SELECT line, COUNT(*)
                            INTO
                      v_line_source , v_cnt
                  FROM user_source us
                 WHERE line > (SELECT line
                                 FROM USER_SOURCE usd
                                WHERE INSTR(UPPER(text),'DECLARE') > 0
                                  AND usd.name = us.name
                                  AND usd.type = us.type)
                   AND line < (SELECT line
                                 FROM (SELECT line, ROW_NUMBER() OVER(ORDER BY line ASC) RN
                                         FROM USER_SOURCE usb
                                        WHERE instr(UPPER(text),'BEGIN' ) > 0
                                          AND usb.name = v_fun_invoker_name
                                          AND usb.type = v_fun_ivoker_type)
                                WHERE RN = 2)
                   AND us.name = v_fun_invoker_name
                   AND us.type = v_fun_ivoker_type
                   AND instr(UPPER(text), v_col_name) > 0 
                 GROUP BY line, INSTR(UPPER(text), v_col_name);
                 
						EXCEPTION WHEN NO_DATA_FOUND THEN
							v_cnt := 0;
						END;
                        
						IF v_cnt = 0 THEN
							:ErrorCode := 102;
							:ErrorMessage := 'Does not exist variable '||v_col_name||' for calling function '||v_fun_processor||' among declaration function '||v_fun_invoker_name ;
							RETURN -1;
						END IF;

						SELECT upper(us.text)
						INTO v_var_type
						FROM user_source us
						WHERE us.name = v_fun_invoker_name
  						AND us.TYPE = v_fun_ivoker_type
							AND us.line = v_line_source;
            
            v_var_type := substr(replace(v_var_type,' '),length(v_l_args(i).r_argument_name)+3); 
            v_var_type := substr(v_var_type,1, length(v_var_type) - 2);
            v_arg_type := v_l_args(i).r_arg_data_type;
            
           CASE WHEN v_var_type IN ('FLOAT','REAL','INTEGER','INT', 'SMALLINT', 'DECIMAL', 'DEC', 'PLS_INTEGER')
                 THEN v_var_type := 'NUMBER';
                 WHEN v_var_type IN ('CLOB') 
                 THEN v_var_type := 'NCLOB';  
                 WHEN INSTR(v_var_type,'VARCHAR')>0 OR INSTR(v_var_type,'STRING')>0 
                 THEN v_var_type :=  'VARCHAR2' ;
                 ELSE 
                   NULL;
            END CASE;  
            CASE WHEN v_arg_type IN ('FLOAT','REAL','INTEGER','INT', 'SMALLINT', 'DECIMAL', 'DEC', 'PLS_INTEGER')
                 THEN v_arg_type := 'NUMBER';
                 WHEN v_arg_type IN ('CLOB') 
                 THEN v_arg_type := 'NCLOB';  
                 WHEN v_arg_type IN ('NVARCHAR2','STRING')
                 THEN v_arg_type :=  'VARCHAR2' ;
                 ELSE 
                   NULL;
            END CASE;                   
               
            IF  v_var_type != v_arg_type THEN
							ErrorCode := 103;
							ErrorMessage := 'Can not invoke function '||v_fun_processor||' cause incompatible types for argument '||v_l_args(i).r_argument_name||' and variable v_'||v_l_args(i).r_argument_name||' from function '||v_fun_invoker_name ;
							RETURN -1;
						END IF;
        BEGIN
          SELECT trim(SUBSTR(text,(INSTR(text,',',0-LENGTH(text)+col,1))+1, col -1 - INSTR(text,',',0-LENGTH(text)+col,1))) 
						INTO 
						v_in_out_var_type
						FROM(
							SELECT line, COUNT(*) OVER (PARTITION BY line)-2 cnt_var_in_dynamic, variable_name,
										 (row_number() OVER(PARTITION BY line ORDER BY rn))-2 nmb_arg_in_dynamic,
											INSTR(upper(text), variable_name) col, text
								FROM (SELECT us.line, us.name, us.type, upper(COLUMN_VALUE) variable_name, us.text, ROWNUM rn
															FROM user_source us,
																	 TABLE( split_casetype_list(list_case_type => us.TEXT))
															WHERE INSTR(upper(us.text),'IMMEDIATE') > 0
																		AND us.name = v_fun_invoker_name
																		AND us.type = v_fun_ivoker_type
																		AND LOWER(COLUMN_VALUE) NOT IN ('execute','immediate', 'using', 'in', 'out')
											)
								)			
								WHERE cnt_var_in_dynamic = v_l_args(i).r_cnt_args 
								AND nmb_arg_in_dynamic = v_l_args(i).r_position	
								AND variable_name	= v_col_name;	
                                
                            EXCEPTION 
							WHEN NO_DATA_FOUND THEN 
							ErrorCode := 104;
							ErrorMessage := 'Can not invoke function '||v_fun_processor||' cause doesnt exists execute immediate with correct order of variable in function '||v_fun_invoker_name;
							RETURN -1;
						END;
						
						IF upper(nvl(v_in_out_var_type,'IN')) != upper(v_l_args(i).r_in_out) THEN  
							ErrorCode := 105; 
							ErrorMessage := 'Can not invoke function '||v_fun_processor||' from function '||v_fun_invoker_name||' cause variable v_'||v_l_args(i).r_argument_name||' in-out type differs from argument in function';
							RETURN -1;						
						END IF; 

           v_cnt_func_args:= v_l_args(i).r_cnt_args; 
END LOOP;



RETURN v_cnt_func_args;
EXCEPTION WHEN OTHERS
	THEN
		:ErrorCode    := SQLCODE;
		:ErrorMessage := dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
   RETURN -1;
END;