DECLARE 
v_invoke_function         VARCHAR2(255);
v_processor_function      VARCHAR2(255);
v_cnt_arguments_proc_func NUMBER;
v_case_or_task_id         NUMBER;
BEGIN
  v_invoke_function         := :invoke_function;
  v_processor_function      := :processor_function;
  v_cnt_arguments_proc_func := :cnt_arguments_proc_func;
  v_case_or_task_id         := :case_or_task_id;
-- raise_application_error(-20001, 'Can not invoke function '||v_processor_function||' from function'||v_invoke_function||' with '||v_cnt_arguments_proc_func||' arguments' ); 
INSERT INTO TBL_LOG
(col_data1, col_data2  )
VALUES 
('Can not invoke function '||v_processor_function||' from function'||v_invoke_function||' with '||v_cnt_arguments_proc_func||' arguments', v_case_or_task_id);
RETURN 0;
EXCEPTION
  WHEN OTHERS THEN 
RETURN -1;
END;  