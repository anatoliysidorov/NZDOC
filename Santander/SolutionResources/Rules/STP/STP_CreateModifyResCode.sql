DECLARE
  v_id          NUMBER;
  v_code        NVARCHAR2(255);
  v_isdeleted   NUMBER;
  v_name        NVARCHAR2(255);
  v_type        NVARCHAR2(255);
  v_iconcode    NVARCHAR2(255);
  v_theme       NVARCHAR2(255);
  v_description NCLOB;
  v_textstyle   NVARCHAR2(1024);
  v_cellstyle   NVARCHAR2(1024);
  v_rowstyle    NVARCHAR2(1024);
  v_isId        NUMBER;
  v_Text 		NVARCHAR2(255);
  v_Result      NUMBER;

  --standard rule params
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
  
BEGIN
  v_id          := :Id;
  v_code        := :Code;
  v_description := :Description;
  v_name        := :NAME;
  v_type        := :TYPE;
  v_isdeleted   := NVL(:IsDeleted, 0);
  v_textstyle   := :TextStyle;
  v_cellstyle   := :CellStyle;
  v_rowstyle    := :RowStyle;
  v_iconcode    := :IconCode;
  v_theme       := :Theme;

  --standard rule params
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';
  :SuccessResponse := EMPTY_CLOB();

 
    -- validation on Id is Exist
    IF NVL(v_id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_id,
                             tablename    => 'TBL_STP_RESOLUTIONCODE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  --set assumed success message
  IF v_id IS NOT NULL THEN
    v_Text := 'Updated {{MESS_NAME}} resolution task';
  ELSE
    v_Text := 'Created {{MESS_NAME}} resolution task';
  END IF;
  --:SuccessResponse := :SuccessResponse || ' ' || v_name || ' resolution task';
	v_result := LOC_i18n(
		MessageText => v_Text,
		MessageResult => :SuccessResponse,
		MessageParams => NES_TABLE(
			Key_Value('MESS_NAME', v_name)
		)
	);

  BEGIN
    --create record if :id is NULL
    IF v_id IS NULL THEN
      INSERT INTO tbl_STP_ResolutionCode
        (col_Code, col_Type, col_ucode)
      VALUES
        (UPPER(v_type) || '_' || v_code, v_type, sys_guid())
      RETURNING col_id INTO v_id;
    END IF;
  
    --update record with additional info
    UPDATE tbl_STP_ResolutionCode
       SET col_Name        = v_name,
           col_Description = v_description,
           col_IsDeleted   = v_isdeleted,
           col_textstyle   = v_textstyle,
           col_cellstyle   = v_cellstyle,
           col_rowstyle    = v_rowstyle,
           col_iconcode    = v_iconcode,
           col_theme       = v_theme
     WHERE col_Id = v_id;
  
    :affectedRows := 1;
  
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows  := 0;
      v_errorcode    := 101;
      v_errormessage := 'There already exists a resolution with this code';
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows  := 0;
      v_errorcode    := 102;
      v_errormessage := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  --set output params
  :recordId     := v_id;
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;

END;