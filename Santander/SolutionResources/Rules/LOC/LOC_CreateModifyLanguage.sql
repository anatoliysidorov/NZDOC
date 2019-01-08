DECLARE
  v_id           NUMBER;
  v_languagename NVARCHAR2(255);
  v_languagecode NVARCHAR2(255);
  v_pluralformid NUMBER;
  v_extcode      NVARCHAR2(255);
  v_momentcode   NVARCHAR2(255);
  v_isdeleted    INTEGER;
  v_appbaselangid NUMBER;
  v_isdefault    INTEGER;
  v_langCount    NUMBER;
  
  --standard 
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
  v_MessageParams NES_TABLE;
  v_result number;
BEGIN
  --custom 
  v_id := :ID;
  v_languagename := :LANGUAGENAME;
  v_languagecode := :LANGUAGECODE;    
  v_extcode      := :EXTCODE;
  v_isdeleted    := :ISDELETED;
  v_momentcode   := :MOMENTCODE;
  v_pluralformid := :PLURALFORMID;
  v_appbaselangid := :APPBASELANGID;
  v_isdefault    := :ISDEFAULT;
  :SuccessResponse := EMPTY_CLOB();

  --standard 
  :affectedRows   := 0;
  v_errorcode     := 0;
  v_errormessage  := '';

  --set assumed success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated {{MESS_NAME}} language';
  ELSE
    :SuccessResponse := 'Created {{MESS_NAME}} language';
  END IF;
  
  BEGIN
    BEGIN
      SELECT COUNT(*) INTO v_langCount
      FROM TBL_LOC_LANGUAGES;
    END;

    --set default language
    IF (v_isdefault = 1) THEN
      UPDATE TBL_LOC_LANGUAGES
        SET COL_ISDEFAULT = NULL
      WHERE COL_ISDEFAULT = 1; 
    END IF;

    --set first language as Default
    IF (v_langCount = 0) THEN
      v_isdefault := 1;
    END IF;

    --add new record or update existing one 
    IF v_id IS NULL THEN
      INSERT INTO TBL_LOC_LANGUAGES
        (
          COL_LANGUAGENAME,
          COL_LANGUAGECODE, 
          COL_PLURALFORMID, 
          COL_EXTCODE, 
          COL_MOMENTCODE, 
          COL_APPBASELANGID, 
          COL_ISDELETED,
          COL_ISDEFAULT,
          COL_UCODE
        )
      VALUES  
        (
          v_languagename, 
          v_languagecode, 
          v_pluralformid, 
          v_extcode, 
          v_momentcode, 
          v_appbaselangid, 
          v_isdeleted,
          v_isdefault,
          SYS_GUID()
        )
      RETURNING COL_ID INTO v_id;
    ELSE
      UPDATE TBL_LOC_LANGUAGES 
        SET COL_LANGUAGENAME = v_languagename,
          COL_LANGUAGECODE = v_languagecode,
          COL_PLURALFORMID = v_pluralformid,
          COL_EXTCODE = v_extcode,
          COL_MOMENTCODE = v_momentcode,
          COL_APPBASELANGID = v_appbaselangid,
          COL_ISDELETED = v_isdeleted,
          COL_ISDEFAULT = v_isdefault
        WHERE COL_ID = v_id;
    END IF;        

    :affectedRows := SQL%ROWCOUNT;
    :recordId := v_id;
    
    v_MessageParams:= NES_TABLE(); 
    v_MessageParams.EXTEND(1);
    v_MessageParams(1) := Key_Value('MESS_NAME', v_languagename);
    
    v_result := LOC_i18n(MessageText => :SuccessResponse, MessageResult => :SuccessResponse, MessageParams => v_MessageParams, MessageParams2 => NULL);
  EXCEPTION WHEN OTHERS THEN
    :affectedRows    := 0;
    v_errorcode      := 102;
    v_errormessage   := substr(SQLERRM, 1, 200);
    :SuccessResponse := '';
  END;
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;