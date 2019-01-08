DECLARE 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
	
    --custom 
    v_id           NUMBER; 
    v_isdeleted    NUMBER; 
    v_name         NVARCHAR2(255); 
    v_code         NVARCHAR2(255); 
    v_description  NCLOB; 
BEGIN 
    --custom 
    :affectedRows := 0; 
    v_errorcode := 0; 
    v_errormessage := ''; 

    --standard 
    v_id := :Id; 
    v_isdeleted := :IsDeleted; 
    v_name := :Name; 
    v_code := :Code; 
    v_description := :Description; 

    BEGIN 
        IF v_id IS NULL THEN 
          INSERT INTO tbl_dict_datatype 
                      (col_description, 
                       col_code, 
                       col_name, 
                       col_isdeleted) 
          VALUES      ( v_description, 
                       v_code, 
                       v_name, 
                       0); 

          SELECT gen_tbl_dict_datatype.CURRVAL 
          INTO   :recordId 
          FROM   dual; 

          :affectedRows := 1; 
        ELSE 
          UPDATE tbl_dict_datatype dt 
          SET    col_name = v_name, 
                 col_code = v_code, 
                 col_description = v_description, 
                 col_isdeleted = v_isdeleted 
          WHERE  col_id = v_id; 

          :affectedRows := 1; 
          :recordId := v_id; 
        END IF; 
    EXCEPTION 
        WHEN dup_val_on_index THEN 
          :affectedRows := 0; 
          v_errorcode := 101; 
          v_errormessage := 'There already exists a Data Type with this code '; 
        WHEN OTHERS THEN 
          :affectedRows := 0; 
          v_errorcode := 102; 
          v_errormessage := Substr(SQLERRM, 1, 200); 
    END; 

    :errorCode := v_errorcode; 
    :errorMessage := v_errormessage; 
END; 