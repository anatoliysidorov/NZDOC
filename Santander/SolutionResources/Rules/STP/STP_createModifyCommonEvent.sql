DECLARE
  v_id              NUMBER;
  v_name            NVARCHAR2(255);
  v_code            NVARCHAR2(255);
  v_isId            NUMBER;
  v_eventorder      INTEGER;
  v_processorcode   NVARCHAR2(255);
  v_commoneventtype NUMBER;
  v_eventmoment     NUMBER;
  v_eventtype       NUMBER;
  v_casetype_id     NUMBER;
  v_procedure_id    NUMBER;
  v_tasktype_id     NUMBER;
  v_customconfig    NCLOB;
  v_repeatingevent  NUMBER;
  v_result          NUMBER;
  v_description     NCLOB;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);

BEGIN
  v_id              := :Id;
  v_name            := :NAME;
  v_code            := :Code;
  v_commoneventtype := :EventWhen_Id;
  v_eventmoment     := :EventMoment_Id;
  v_eventtype       := :EventType_Id;
  v_casetype_id     := :CaseType_Id;
  v_procedure_id    := :Procedure_Id;
  v_tasktype_id     := :TaskType_Id;
  v_customconfig    := :CustomConfig;
  v_description     := :Description;

  :affectedRows    := 0;
  :SuccessResponse := EMPTY_CLOB();
  v_errorcode      := 0;
  v_errormessage   := '';

  -- Input params checks

  -- validation on Id is Exist
  IF NVL(v_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_id, tablename => 'TBL_COMMONEVENTTMPL');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  ELSE
    IF (v_casetype_id IS NULL AND v_procedure_id IS NULL AND v_tasktype_id IS NULL) THEN
      v_errormessage := 'CaseSysTypeId or ProcedureId or TaskSysTypeId need have a value';
      v_errorcode    := 101;
      GOTO cleanup;
    END IF;
  END IF;

  -- validation on Description is Exist
  IF nvl(dbms_lob.getlength(v_description), 0) = 0 THEN
    v_errormessage := 'Description can not be NULL';
    v_errorcode    := 104;
    GOTO cleanup;
  END IF;

  IF NVL(v_casetype_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_casetype_id, tablename => 'TBL_DICT_CASESYSTYPE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF NVL(v_procedure_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_procedure_id, tablename => 'TBL_PROCEDURE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  IF NVL(v_tasktype_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_tasktype_id, tablename => 'TBL_DICT_TASKSYSTYPE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  --set success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated common event';
  ELSE
    :SuccessResponse := 'Created common event';
  END IF;

  -- get data
  IF UPPER(v_code) != 'RULE' THEN
    BEGIN
      SELECT NVL(col_msprocessorcode, col_processorcode) INTO v_processorcode FROM tbl_dict_actiontype WHERE col_code = v_code;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        :affectedRows    := 0;
        v_errorcode      := 102;
        v_errormessage   := substr(SQLERRM, 1, 200);
        :SuccessResponse := '';
    END;
  ELSE
    v_processorcode := f_UTIL_extract_value_xml(Input => XMLType(v_customconfig), Path => '/CustomData/Attributes/RULE_CODE/text()');
  END IF;
  BEGIN
    SELECT col_repeatingevent INTO v_repeatingevent FROM tbl_dict_commoneventtype WHERE col_id = v_commoneventtype;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      :affectedRows    := 0;
      v_errorcode      := 103;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  BEGIN
  
    --add new record or update existing one 
    IF v_id IS NULL THEN
      -- get MAX EventOrder
      SELECT NVL(MAX(col_eventorder), 0) + 1
        INTO v_eventorder
        FROM tbl_commoneventtmpl
       WHERE col_commoneventtmplcasetype = v_casetype_id
          OR col_commoneventtmplprocedure = v_procedure_id
          OR col_commoneventtmpltasktype = v_tasktype_id;
    
      INSERT INTO tbl_commoneventtmpl
        (col_code,
         col_eventorder,
         col_name,
         col_processorcode,
         col_ucode,
         col_comeventtmplcomeventtype,
         col_comevttmplevtmmnt,
         col_comevttmpltaskevtt,
         col_commoneventtmplcasetype,
         col_commoneventtmplprocedure,
         col_commoneventtmpltasktype,
         col_customconfig,
         col_repeatingevent,
         col_description)
      VALUES
        (v_code,
         v_eventorder,
         v_name,
         v_processorcode,
         sys_guid(),
         v_commoneventtype,
         v_eventmoment,
         v_eventtype,
         v_casetype_id,
         v_procedure_id,
         v_tasktype_id,
         v_customconfig,
         v_repeatingevent,
         v_description)
      RETURNING col_id INTO v_id;
    
    ELSE
    
      UPDATE tbl_commoneventtmpl
         SET col_code                     = v_code,
             col_eventorder               = v_eventorder,
             col_name                     = v_name,
             col_processorcode            = v_processorcode,
             col_comeventtmplcomeventtype = v_commoneventtype,
             col_comevttmplevtmmnt        = v_eventmoment,
             col_comevttmpltaskevtt       = v_eventtype,
             col_customconfig             = v_customconfig,
             col_description              = v_description
       WHERE col_id = v_id;
    END IF;
  
    v_Result      := f_STP_createCommonEventData(COMMONEVENTID => v_id, ERRORCODE => v_errorcode, ERRORMESSAGE => v_errormessage);
    :affectedRows := SQL%ROWCOUNT;
    :recordId     := v_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 103;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
