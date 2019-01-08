DECLARE
  v_RawType          VARCHAR2(10);
  v_Name             NVARCHAR2(255);
  v_Code             NVARCHAR2(255);
  v_Value            NVARCHAR2(255);
  v_ParentCategoryId NUMBER;
  v_Description      NCLOB;
  v_Count            NUMBER;
  v_newitemid        NUMBER;
  v_WordOrder        NUMBER;
  v_IsDeleted        NUMBER;
  v_CategoryOrder    NUMBER;
  v_Style            NVARCHAR2(255);
  v_RowStyle         NVARCHAR2(255);
  v_colorcode        NVARCHAR2(7);
  v_iconcode         NVARCHAR2(255);
  v_isId             NUMBER;
  v_errorcode        NUMBER;
  v_errormessage     NVARCHAR2(255);
  v_result           NUMBER;
BEGIN
  v_RawType          := :RawType;
  v_Name             := :NAME;
  v_ParentCategoryId := :ParentCategoryId;
  v_Description      := :Description;
  v_Code             := :pCode;
  v_Value            := :pValue;
  v_WordOrder        := 0;
  v_IsDeleted        := :IsDeleted;
  v_Style            := :pStyle;
  v_RowStyle         := :pRowStyle;
  v_iconcode         := :IconCode;
  v_colorcode        := :ColorCode;

  v_errormessage   := '';
  v_errorcode      := 0;
  :RecordId        := 0;
  :SuccessResponse := EMPTY_CLOB();

  -- validation on ParentCategoryId is Exist
  IF NVL(v_ParentCategoryId, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_ParentCategoryId, tablename => 'TBL_DICT_CUSTOMCATEGORY');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF (v_RawType IS NULL) THEN
    v_errorcode    := 20;
    v_errormessage := '$t(RawType can not be empty) ';
  END IF;

  IF (v_Name IS NULL) THEN
    v_errorcode    := 20;
    v_errormessage := v_errormessage || '$t(Name can not be empty) ';
  END IF;

  IF (v_Code IS NULL) THEN
    v_errorcode    := 20;
    v_errormessage := v_errormessage || '$t(CODE can not be empty) ';
  END IF;

  IF (v_errorcode > 0) THEN
    GOTO cleanup;
  END IF;

  IF (v_RawType = 'WORD') THEN
    IF (v_ParentCategoryId IS NULL) THEN
      BEGIN
        SELECT COUNT(COL_CODE)
          INTO v_Count
          FROM TBL_DICT_CUSTOMWORD dl
         WHERE LOWER(dl.COL_CODE) = LOWER(v_Code)
           AND COL_WORDCATEGORY IS NULL;
      
        IF v_Count > 0 THEN
          v_errorcode    := 10;
          v_errormessage := 'For RowType, WORD Code have to be Unique';
          GOTO cleanup;
        END IF;
      END;
    ELSE
      BEGIN
        SELECT COUNT(dl.COL_CODE)
          INTO v_Count
          FROM TBL_DICT_CUSTOMWORD dl
         INNER JOIN TBL_DICT_CUSTOMCATEGORY dc
            ON dc.COL_ID = dl.COL_WORDCATEGORY
         WHERE LOWER(dl.COL_CODE) = LOWER(v_Code)
           AND dl.COL_WORDCATEGORY = v_ParentCategoryId;
      
        IF v_Count > 0 THEN
          v_errorcode    := 21;
          v_errormessage := 'RawType WORD. The CODE has to be unique for all Words in the ParentFolder: {{MESS_PARENTFOLDERID}}';
          v_result       := LOC_i18n(MessageText   => v_errormessage,
                                     MessageResult => v_errormessage,
                                     MessageParams => NES_TABLE(Key_Value('MESS_PARENTFOLDERID', v_ParentCategoryId)));
          GOTO cleanup;
        END IF;
      END;
    END IF;
  
    BEGIN
      -- get MAX WordOrder
      SELECT NVL(MAX(col_wordorder), 0) INTO v_WordOrder FROM TBL_DICT_CUSTOMWORD WHERE col_wordcategory = v_ParentCategoryId;
      v_WordOrder := v_WordOrder + 1;
    
      --create word
      INSERT INTO TBL_DICT_CUSTOMWORD
        (COL_NAME, COL_DESCRIPTION, COL_CODE, COL_VALUE, COL_WORDCATEGORY, COL_WORDORDER, COL_ISDELETED, COL_STYLE, COL_ROWSTYLE)
      VALUES
        (v_Name, v_Description, v_Code, v_Value, v_ParentCategoryId, v_WordOrder, v_IsDeleted, v_Style, v_RowStyle)
      RETURNING COL_ID INTO v_newitemid;
      --:SuccessResponse := 'Created ' || v_name || ' word';
      :SuccessResponse := 'Created {{MESS_NAME}} word';
      v_result         := LOC_i18n(MessageText   => :SuccessResponse,
                                   MessageResult => :SuccessResponse,
                                   MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_name)));
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorcode    := 11;
        v_errormessage := 'RawType WORD. Error on insert record.';
        GOTO cleanup;
      WHEN DUP_VAL_ON_INDEX THEN
        v_errorcode    := 12;
        v_errormessage := 'RawType WORD. Error on insert record.';
        GOTO cleanup;
    END;
  
    :RecordId := v_newitemid;
  ELSIF (v_RawType = 'CATEGORY') THEN
    /*    IF (v_ParentCategoryId IS NULL) THEN
      BEGIN
        SELECT COUNT(COL_CODE)
          INTO v_Count
          FROM TBL_DICT_CUSTOMCATEGORY dl
         WHERE LOWER(dl.COL_CODE) = LOWER(v_Code)
           AND COL_CATEGORYCATEGORY IS NULL;
      
        IF v_Count > 0 THEN
          v_errorcode    := 13;
          v_errormessage := 'For RawType CATEGORY Code have to by Uniqued';
          GOTO cleanup;
        END IF;
      END;
    ELSE
      BEGIN
        SELECT COUNT(dl.COL_CODE)
          INTO v_Count
          FROM TBL_DICT_CUSTOMCATEGORY dl
         INNER JOIN TBL_DICT_CUSTOMCATEGORY dc
            ON dc.COL_ID = dl.COL_CATEGORYCATEGORY
         WHERE LOWER(dl.COL_CODE) = LOWER(v_Code)
           AND dl.COL_CATEGORYCATEGORY = v_ParentCategoryId;
      
        IF v_Count > 0 THEN
            v_errorcode    := 22;
            --v_errormessage := 'RawType CATEGORY. The CODE has to be unique for all Categories in the ParentFolder: ' || v_ParentCategoryId;
      v_errormessage := 'RawType CATEGORY. The CODE has to be unique for all Categories in the ParentFolder: {{MESS_PARENTFOLDERID}}';
      v_result := LOC_i18n(
        MessageText => v_errormessage,
        MessageResult => v_errormessage,
        MessageParams => NES_TABLE(
          Key_Value('MESS_PARENTFOLDERID', v_ParentCategoryId)
        )
      );
      GOTO cleanup;
        END IF;
      END;
    END IF;*/
  
    SELECT MAX(COL_CATEGORYORDER) + 1 INTO v_CategoryOrder FROM TBL_DICT_CUSTOMCATEGORY WHERE COL_CATEGORYCATEGORY = v_ParentCategoryId;
  
    --create folder
    BEGIN
      --create word
      INSERT INTO TBL_DICT_CUSTOMCATEGORY
        (COL_NAME, COL_CODE, COL_DESCRIPTION, COL_CATEGORYCATEGORY, COL_CATEGORYORDER, COL_ICONCODE, COL_COLORCODE)
      VALUES
        (v_Name, v_Code, v_Description, v_ParentCategoryId, v_CategoryOrder, v_iconcode, v_colorcode)
      RETURNING COL_ID INTO v_newitemid;
      --:SuccessResponse := 'Created ' || v_name || ' category';
      :SuccessResponse := 'Created {{MESS_NAME}} category';
      v_result         := LOC_i18n(MessageText   => :SuccessResponse,
                                   MessageResult => :SuccessResponse,
                                   MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_name)));
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        v_errorcode := 15;
        --v_errormessage := 'There already exists a Category with the code: ' || to_char(v_Code);
        v_errormessage := 'There already exists a Category with the code: {{MESS_CODE}}';
        v_result       := LOC_i18n(MessageText   => v_errormessage,
                                   MessageResult => v_errormessage,
                                   MessageParams => NES_TABLE(Key_Value('MESS_CODE', to_char(v_Code))));
        GOTO cleanup;
      WHEN OTHERS THEN
        v_errorcode    := 14;
        v_errormessage := substr(SQLERRM, 1, 200);
        GOTO cleanup;
    END;
  
    :RecordId := v_newitemid;
  ELSE
    v_errorcode := 30;
    --v_errormessage := 'Raw Type ' || v_RawType || ' is not recognized!';
    v_errormessage := 'Raw Type {{MESS_RAWTYPE}} is not recognized!';
    v_result       := LOC_i18n(MessageText   => v_errormessage,
                               MessageResult => v_errormessage,
                               MessageParams => NES_TABLE(Key_Value('MESS_RAWTYPE', v_RawType)));
    GOTO cleanup;
  END IF;

  <<cleanup>>
  :ErrorMessage := v_errormessage;
  :ErrorCode    := v_errorcode;
END;