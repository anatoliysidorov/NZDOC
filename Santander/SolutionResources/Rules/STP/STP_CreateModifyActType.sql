DECLARE 
    --custom 
    v_id           NUMBER; 
    v_isdefault    NUMBER; 
	v_isdeleted    NUMBER; 
    v_name         NVARCHAR2(255); 
	v_code         NVARCHAR2(255); 
    v_value        NUMBER(10, 2); 
    v_description  NCLOB; 
    --standard 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
BEGIN 
    --custom 
    :affectedRows := 0; 
    v_errorcode := 0; 
    v_errormessage := ''; 
	
    --standard 
    v_id := :pId; 
    v_isdefault := :pIsDefault; 
	v_isdeleted := :pIsDeleted; 
    v_name := :pName; 
    v_value := :pValue; 
    v_description := :pDescription; 
	v_code := :pCode;

    BEGIN 
        --set isDefault to only 1 item 
        IF v_isdefault = 1 THEN 
          UPDATE tbl_dict_ActivitySetup
          SET    col_isdefault = 0 
          WHERE  col_isdefault = 1; 
        END IF; 

        --add new record or update existing one 
        IF v_id IS NULL THEN 
          INSERT INTO tbl_dict_ActivitySetup 
                      (col_isdefault, 
                       col_description, 
                       col_value, 
                       col_name,
					   col_code,
					   col_isDeleted) 
          VALUES      ( v_isdefault, 
                       v_description, 
                       v_value, 
                       v_name,
					   v_code,
						0); 

          SELECT gen_tbl_dict_ActivitySetup.CURRVAL 
          INTO   :recordId 
          FROM   dual; 

          :affectedRows := 1; 
        ELSE 
          UPDATE tbl_dict_ActivitySetup  
          SET    col_isdefault = v_isdefault,  
                 col_name = v_name, 
				 col_code = v_code,
                 col_value = v_value, 
                 col_description = v_description,
				 col_isDeleted = v_isdeleted				 
          WHERE  col_id = v_id; 

          :affectedRows := 1; 
          :recordId := v_id; 
        END IF; 
    EXCEPTION 
        WHEN dup_val_on_index THEN 
          :affectedRows := 0; 
          v_errorcode := 101; 
          v_errormessage := 'There already exists a Activity Setup with the value ' || To_char(v_value); 
        WHEN OTHERS THEN 
          :affectedRows := 0; 
          v_errorcode := 102; 
      	  v_errormessage := substr(SQLERRM, 1, 200);
    END; 
	:errorCode := v_errorcode;
	:errorMessage := v_errormessage;	
END;