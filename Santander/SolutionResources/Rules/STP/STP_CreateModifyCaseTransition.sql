DECLARE
       v_id           NUMBER;
       v_name         NVARCHAR2(255);
       v_code         NVARCHAR2(255);
       v_description  NCLOB;
       ---
       v_errorcode    NUMBER;
       v_errormessage NVARCHAR2(255);
BEGIN
       v_id := :Id;
       v_name := :Name;
       v_code := :Code;
       v_description := :Description;
       ---
       :affectedRows := 0;
       v_errorcode := 0;
       v_errormessage := '';
       BEGIN
              --add new record or update existing one
              IF v_id IS NULL
              THEN
                     INSERT INTO tbl_dict_tasktransition (
                            col_name,
                            col_code,
                            col_description
                     )
                     VALUES (
                            v_name,
                            v_code,
                            v_description
                     );

                     SELECT gen_tbl_dict_tasktransition.CURRVAL INTO v_id FROM dual;
              ELSE
                     UPDATE tbl_dict_tasktransition
                     SET
                            col_name        = v_name,
                            col_code        = v_code,
                            col_description = v_description
                     WHERE col_id = v_id;
              END IF;
              
              :affectedRows := 1;
              :recordId := v_id;

              EXCEPTION
              WHEN OTHERS THEN
              :affectedRows := 0;
              v_errorcode := 102;
              v_errormessage := substr(SQLERRM, 1, 200);

       END;
       :errorCode := v_errorcode;
       :errorMessage := v_errormessage;
END;