DECLARE
  --custom
  v_Id                TBL_FOM_UIELEMENT.COL_ID%TYPE;
  v_IsDeleted         TBL_FOM_UIELEMENT.COL_ISDELETED%TYPE;
  v_IsHidden          TBL_FOM_UIELEMENT.COL_ISHIDDEN%TYPE;
  v_IsEditable        TBL_FOM_UIELEMENT.COL_USEREDITABLE%TYPE;
  v_Name              TBL_FOM_UIELEMENT.COL_NAME%TYPE;
  v_Code              TBL_FOM_UIELEMENT.COL_CODE%TYPE;
  v_ProcessorCode     TBL_FOM_UIELEMENT.COL_PROCESSORCODE%TYPE;
  v_Description       TBL_FOM_UIELEMENT.COL_DESCRIPTION%TYPE;
  v_Config            TBL_FOM_UIELEMENT.COL_CONFIG%TYPE;
  v_UIElementType_Id  TBL_FOM_UIELEMENT.COL_UIELEMENTUIELEMENTTYPE%TYPE;
  v_ParentId          TBL_FOM_UIELEMENT.COL_PARENTID%TYPE;
  v_CaseSysType_Id    TBL_DICT_CASESYSTYPE.COL_ID%TYPE;
  v_CaseTransition_Id TBL_DICT_CASETRANSITION.COL_ID%TYPE;
  v_TaskSysType_Id    TBL_DICT_TASKSYSTYPE.COL_ID%TYPE;
  v_TaskTransition_Id TBL_DICT_TASKTRANSITION.COL_ID%TYPE;
  v_Return            NUMBER;
  --standard
  v_ErrorCode         NUMBER := 0;
  v_ErrorMessage      NCLOB;
BEGIN
  --custom
  v_Id          := :Id;
  v_IsDeleted   := :IsDeleted;
  v_IsHidden    := :IsHidden;
  v_IsEditable  := :IsEditable;
  v_Name        := :Name;
  v_Code        := :Code;
  v_Description := :Description;
  v_Config      := :Config;
  :SuccessResponse := EMPTY_CLOB();

  v_CaseSysType_Id    := :CaseSysType_Id;
  v_CaseTransition_Id := :CaseTransition_Id;
  v_TaskSysType_Id    := :TaskSysType_Id;
  v_TaskTransition_Id := :TaskTransition_Id;
  v_UIElementType_Id  := :UIElementType_Id;
  v_ParentId          := :ParentId;
  v_ProcessorCode     := :ProcessorCode;

  --standard
  :affectedRows  := 0;
  v_ErrorCode    := 0;
  v_ErrorMessage := '';

  -- validation on Id is Exist
  IF (NVL(v_Id, 0) > 0) THEN
    v_Return := F_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_Id,
      TableName    => 'TBL_FOM_UIELEMENT');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF (NVL(v_CaseSysType_Id, 0) > 0)
  THEN
    v_Return := F_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_CaseSysType_Id,
      TableName    => 'TBL_DICT_CASESYSTYPE');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF (NVL(v_CaseTransition_Id, 0) > 0) THEN
    v_Return := F_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_CaseTransition_Id,
      TableName    => 'TBL_DICT_CASETRANSITION');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF (NVL(v_TaskSysType_Id, 0) > 0) THEN
    v_Return := F_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_TaskSysType_Id,
      TableName    => 'TBL_DICT_TASKSYSTYPE');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF NVL(v_TaskTransition_Id, 0) > 0
  THEN
    v_Return := F_UTIL_getId(
      errorCode    => v_ErrorCode,
      errorMessage => v_ErrorMessage,
      Id           => v_TaskTransition_Id,
      TableName    => 'TBL_DICT_TASKTRANSITION');
    IF (v_ErrorCode > 0) THEN
      GOTO cleanup;
    END IF;
  END IF;
  BEGIN
    --add new record or update existing one             
    IF (v_Id IS NULL) 
    THEN
      v_IsDeleted := 0;
      INSERT INTO TBL_FOM_UIELEMENT (
        COL_CODE,
        COL_NAME,
        COL_DESCRIPTION,
        COL_ISDELETED,
        COL_ISHIDDEN,
        COL_UIELEMENTCASETRANSITION,
        COL_UIELEMENTTASKTRANSITION,
        COL_UIELEMENTCASESYSTYPE,
        COL_UIELEMENTTASKSYSTYPE,
        COL_UIELEMENTUIELEMENTTYPE,
        COL_PARENTID,
        COL_PROCESSORCODE,
        COL_CONFIG,
        COL_USEREDITABLE
      ) VALUES (
        v_Code,
        v_Name,
        v_Description,
        v_IsDeleted,
        v_IsHidden,
        v_CaseTransition_Id,
        v_TaskTransition_Id,
        v_CaseSysType_Id,
        v_TaskSysType_Id,
        v_UIElementType_Id,
        v_ParentId,
        v_ProcessorCode,
        v_Config,
        v_IsEditable
      ) RETURNING COL_ID INTO v_Id;
      :SuccessResponse := 'Created {{MESS_NAME}} UI Element';
    ELSE
      UPDATE TBL_FOM_UIELEMENT SET
        COL_NAME = v_Name,
        COL_DESCRIPTION = v_Description,
        COL_ISDELETED = v_IsDeleted,
        COL_ISHIDDEN = v_IsHidden,
        COL_UIELEMENTCASETRANSITION = v_CaseTransition_Id,
        COL_UIELEMENTTASKTRANSITION = v_TaskTransition_Id,
        COL_UIELEMENTCASESYSTYPE = v_CaseSysType_Id,
        COL_UIELEMENTTASKSYSTYPE = v_TaskSysType_Id,
        COL_UIELEMENTUIELEMENTTYPE = v_UIElementType_Id,
        COL_PARENTID = v_ParentId,
        COL_PROCESSORCODE = v_ProcessorCode,
        COL_CONFIG = v_Config
       WHERE COL_ID = v_Id;
      :SuccessResponse := 'Updated {{MESS_NAME}} UI Element';
    END IF;
    :affectedRows := SQL%ROWCOUNT;
    :recordId := v_Id;
    v_Return := LOC_i18n(
      MessageText => :SuccessResponse,
      MessageResult => :SuccessResponse,
      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_Name))
    );
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_ErrorCode := 101;
      v_ErrorMessage := 'UI Element does not exist';
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows := 0;
      v_ErrorCode := 102;
      v_ErrorMessage := '$t(Exception:) ' || SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;
<<cleanup>>
  :errorCode := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
END;