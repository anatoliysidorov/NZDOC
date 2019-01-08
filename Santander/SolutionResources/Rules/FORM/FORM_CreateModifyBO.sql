DECLARE 
    v_errorcode        NUMBER;
    v_errormessage     NVARCHAR2(255);
    
    v_id                NUMBER;
    v_code              NVARCHAR2(255);
    v_name              NVARCHAR2(255); 
    v_isdeleted         NUMBER;
                    
BEGIN
    
    :affectedRows := 0;
    v_errorcode := 0;
    v_errormessage := '';     
    
    v_id := :Id;
    v_code := :Code; 
    v_name := :Name;
    v_isdeleted := :IsDeleted;
    BEGIN        
                   
      IF v_id IS NULL THEN
      INSERT INTO TBL_DICT_BUSINESSOBJECT
      (
        COL_CODE,
        COL_NAME,
        COL_ISDELETED              
      )
      VALUES 
      (
        v_code,
        v_name,                 
        0
      );
 
        SELECT gen_TBL_DICT_BUSINESSOBJECT.CURRVAL
        INTO   :recordId
        FROM   dual;
 
        :affectedRows := 1;

      ELSE
          UPDATE TBL_DICT_BUSINESSOBJECT dict
            SET dict.COL_CODE = v_code,
                dict.COL_NAME = v_name,
                dict.COL_ISDELETED = v_isdeleted                  
          WHERE  COL_ID = v_id;
 
          :affectedRows := 1;
          :recordId := v_id;
      END IF;

        EXCEPTION
        WHEN dup_val_on_index THEN
          :affectedRows := 0;
          v_errorcode := 101;
          v_errormessage := 'There already exists a record with this value ';
        WHEN OTHERS THEN
          :affectedRows := 0;
          v_errorcode := 102;
          v_errormessage := substr(SQLERRM, 1, 200);
    END;
    :errorCode := v_errorcode;
    :errorMessage := v_errormessage;   
END;