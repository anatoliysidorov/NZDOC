DECLARE 
    --custom 
    v_id           NUMBER; 
    v_objectid     NUMBER;
	v_isdeleted    NUMBER; 
    v_name         NVARCHAR2(255); 
    v_code         NVARCHAR2(255); 
    v_columnname    NVARCHAR2(255); 
    --standard 
    v_errorcode    NUMBER; 
    v_errormessage NVARCHAR2(255); 
BEGIN 
    --custom 
    :affectedRows := 0; 
    v_errorcode := 0; 
    v_errormessage := ''; 
	
    --standard 
    v_id := :Id; 
    v_objectid := :Object_Id;
   	v_isdeleted := :IsDeleted; 
    v_name := :Name; 
    v_code := :Code;
    v_columnName := :ColumnName;

    BEGIN 
      
        --add new record or update existing one 
        IF v_id IS NULL THEN 
          INSERT INTO tbl_fom_attribute
                      (
                       col_code, 
                       col_name,
                       col_columnname,
                       COL_FOM_ATTRIBUTEFOM_OBJECT,
                       col_isDeleted) 
          VALUES      (  
                       v_code, 
                       v_name,
                       v_columnname,
                       v_objectid,
                       0); 

          SELECT gen_tbl_fom_attribute.CURRVAL 
          INTO   :recordId 
          FROM   dual; 

          :affectedRows := 1; 
        ELSE 
          UPDATE tbl_fom_attribute
          SET    col_name = v_name, 
                 col_code = v_code, 
                 col_columnname = v_columnname,
                 COL_FOM_ATTRIBUTEFOM_OBJECT = v_objectid,
				 col_isDeleted = v_isdeleted				 
          WHERE  col_id = v_id; 

          :affectedRows := 1; 
          :recordId := v_id; 
        END IF; 
    EXCEPTION 
        WHEN dup_val_on_index THEN 
          :affectedRows := 0; 
          v_errorcode := 101; 
          v_errormessage := 'There already exists a FOM Attribute with the name ' || To_char(v_name); 
        WHEN OTHERS THEN 
          :affectedRows := 0; 
          v_errorcode := 102; 
      	  v_errormessage := substr(SQLERRM, 1, 200);
    END; 
	:errorCode := v_errorcode;
	:errorMessage := v_errormessage;	
END; 