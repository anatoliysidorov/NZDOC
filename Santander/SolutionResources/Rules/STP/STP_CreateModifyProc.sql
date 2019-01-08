DECLARE
    --custom
    v_customdataprocessor NVARCHAR2(255);
    v_retcustdataprocessor NVARCHAR2(255);
    v_updatecustdataprocessor NVARCHAR2(255);
    v_customvalidator NVARCHAR2(255);
    v_id NUMBER;
    v_name NVARCHAR2(255);
    v_code NVARCHAR2(255);
    v_aotcode NVARCHAR2(255);
    v_aotid     NUMBER;
    v_isdeleted NUMBER;
    v_description NCLOB;
    v_resolutioncodes_ids NCLOB;
    v_config NCLOB;
    v_initmethodcode NVARCHAR2(255);
    v_initmethodid NUMBER;
    v_isId         NUMBER;
    --standard
    v_errorcode NUMBER;
    v_errormessage NVARCHAR2(255);
    v_createdby_name NVARCHAR2(255);
    v_modifiedby_name NVARCHAR2(255);
    v_text NVARCHAR2(255);
    v_result number;
BEGIN
    --custom
    v_customdataprocessor     := :Customdataprocessor;
    v_retcustdataprocessor    := :Retcustdataprocessor;
    v_updatecustdataprocessor := :Updatecustdataprocessor;
    v_customvalidator         := :CustomValidator;
    v_id                      := :Id;
    v_name                    := :Name;
    v_code                    := :Code;
    v_config                  := :Config;
    v_isdeleted               := NVL(:IsDeleted, 0);
    v_description             := :Description;
    --standard
    :affectedRows  := 0;
    v_errorcode    := 0;
    v_errormessage := '';
    :SuccessResponse := EMPTY_CLOB();
    BEGIN
        --set assumed success message
        IF v_id  IS NOT NULL THEN
        -- validation on Id is Exist
        v_isId := f_UTIL_getId(errorcode    => v_errorcode,
           errormessage => v_errormessage,
           id           => v_id,
           tablename    => 'TBL_PROCEDURE');
        IF v_errorcode > 0 THEN
        GOTO cleanup;
        END IF;

            v_text := 'Updated {{MESS_NAME}} procedure';
        ELSE
            v_text := 'Created {{MESS_NAME}} procedure';
        END IF;
        --:SuccessResponse := :SuccessResponse || ' ' || v_name || ' procedure';
        v_result := LOC_i18n(
        MessageText => v_text,
        MessageResult => :SuccessResponse,
        MessageParams => NES_TABLE(
        Key_Value('MESS_NAME', v_name)
        )
        );

        --create new record if needed
        IF v_id IS NULL THEN
            INSERT INTO tbl_procedure
                (col_code
                ) VALUES
                (v_code
                )
            RETURNING col_id INTO v_id;
            --add root task template
            INSERT
            INTO tbl_tasktemplate
                (
                    col_name,
                    col_taskid,
                    col_leaf,
                    col_parentttid,
                    col_taskorder,
                    col_depth,
                    col_icon,
                    col_proceduretasktemplate,
                    col_systemtype,
                    col_code
                )
                VALUES
                (
                    'Root',
                    'root',
                    0,
                    0,
                    1,
                    0,
                    'folder',
                    v_id,
                    'Root',
                    sys_guid()
                );
        END IF;        
        
        IF(v_name IS NULL AND v_code IS NULL AND v_id IS NOT NULL AND v_config IS NOT NULL) THEN
            --update only config
            UPDATE TBL_Procedure 
            SET COL_CONFIG = v_config 
            WHERE col_id = v_id;
        ELSE 
            --update the record
            UPDATE tbl_procedure
            SET col_customdataprocessor     = v_customdataprocessor,
                col_retcustdataprocessor    = v_retcustdataprocessor,
                col_updatecustdataprocessor = v_updatecustdataprocessor,
                col_customvalidator         = v_customvalidator,
                col_name                    = v_name,
                col_code                    = v_code,
                col_isdeleted               = v_isdeleted,
                col_description             = v_description
            WHERE col_id                    = v_id;
        END IF;
        
        --set output
        :affectedRows := SQL%rowcount;
        :recordId     := v_id;
    EXCEPTION
    WHEN dup_val_on_index THEN
        :affectedRows    := 0;
        v_errorcode      := 101;
        v_errormessage   := 'There already exists a procedure with the code {{MESS_CODE}}';
        v_result := LOC_i18n(
        MessageText => v_errormessage,
        MessageResult => v_errormessage,
        MessageParams => NES_TABLE(
        Key_Value('MESS_CODE', TO_CHAR(v_code))
        )
        );
        :SuccessResponse := '';
        goto cleanup;
    WHEN OTHERS THEN
        :affectedRows    := 0;
        v_errorcode      := 102;
        v_errormessage   := SUBSTR(SQLERRM, 1, 200);
        :SuccessResponse := '';
        goto cleanup;
    END;

    if v_config is not null then
      v_result := f_WFL_createProcedureContent(Input => v_config,
                                               ErrorCode=>v_errorcode,
                                               ErrorMessage=>v_errormessage);
                                               
      IF v_errorcode > 0 THEN GOTO cleanup; END IF;                                              
    end if;
    
    BEGIN
                            
    SELECT F_getnamefromaccesssubject(col_createdby), F_getnamefromaccesssubject(col_modifiedby) 
      INTO v_createdby_name, v_modifiedby_name
      FROM tbl_procedure WHERE col_id = v_id;       
      
      :createdby_name  := v_createdby_name;
      :modifiedby_name := v_modifiedby_name;
      
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            v_errorCode := 103;
            v_errorMessage := 'No data found';
            goto cleanup;
         WHEN OTHERS
         THEN
            v_errorCode := 104;
            v_errorMessage := SUBSTR(SQLERRM, 1, 200);
            goto cleanup;
    END;      
    <<cleanup>>
    :errorCode    := v_errorcode;
    :errorMessage := v_errormessage;
    
END;