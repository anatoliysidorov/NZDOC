DECLARE
  v_idslaaction       NUMBER;
  v_idslaevent        NUMBER;
  v_tasktype_id       NUMBER;
  v_slaeventlevel_id  NUMBER;
  v_dateeventlevel_id NUMBER;
  v_slaeventtype_id   NUMBER;
  v_maxattempts       INT;
  v_seconds           INT;
  v_minutes           INT;
  v_hours             INT;
  v_days              INT;
  v_months            INT;
  v_description       NCLOB;
  v_processorcode     NVARCHAR2(255);
  v_paramcodes        NCLOB;
  v_paramvalues       NCLOB;
  v_intervalds        NVARCHAR2(255);
  v_intervalym        NVARCHAR2(255);
  v_res               INT;
  v_SlaEventOrder     INT;
  v_isId              INT;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_idslaaction       := :Id;
  v_tasktype_id       := :TaskType_Id;
  v_slaeventlevel_id  := :SLAEventLevel_Id;
  v_dateeventlevel_id := :DateEventLevel_Id;
  v_slaeventtype_id   := :SLAEventType_Id;
  v_maxattempts       := NVL(:MaxAttempts, 1);
  v_seconds           := NVL(:Seconds, 0);
  v_minutes           := NVL(:Minutes, 0);
  v_hours             := NVL(:Hours, 0);
  v_days              := NVL(:Days, 0);
  v_months            := NVL(:Months, 0);
  v_description       := :Description;
  v_processorcode     := :ProcessorCode;
  v_paramcodes        := :ParamCodes;
  v_paramvalues       := :ParamValues;

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  -- validation on Id is Exist 
  IF NVL(v_tasktype_id, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                           errormessage => v_errormessage,
                           id           => v_tasktype_id,
                           tablename    => 'TBL_DICT_TASKSYSTYPE');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  -- check on require parameters
  IF v_tasktype_id IS NULL THEN
    v_errormessage := 'TaskType_Id can not be empty';
    v_errorcode    := 102;
    GOTO cleanup;
  END IF;

  IF v_slaeventlevel_id IS NULL THEN
    v_errormessage := 'SLAEventLevel_Id can not be empty';
    v_errorcode    := 103;
    GOTO cleanup;
  END IF;

  IF v_dateeventlevel_id IS NULL THEN
    v_errormessage := 'DateEventLevel_Id can not be empty';
    v_errorcode    := 104;
    GOTO cleanup;
  END IF;

  IF v_slaeventtype_id IS NULL THEN
    v_errormessage := 'SLAEventType_Id can not be empty';
    v_errorcode    := 105;
    GOTO cleanup;
  END IF;

  --set success message
  IF v_idslaaction IS NOT NULL THEN
    :SuccessResponse := 'Updated SLAAction and SLAEvent records';
  ELSE
    :SuccessResponse := 'Created SLAAction and SLAEvent records';
  END IF;

  --:SuccessResponse := :SuccessResponse || ' SLAAction and SLAEvent records';

  BEGIN
    --create new record if id is not passed in
    IF v_idslaaction IS NULL THEN
      -- new record to SLAEvemt - MaxAttempts, Integer - defaults to 1
      INSERT INTO TBL_SLAEVENT
        (col_code, col_maxattempts)
      VALUES
        (sys_guid(), 1)
      RETURNING col_id INTO v_idslaevent;
    
      -- new record to SLAAction
      INSERT INTO TBL_SLAACTION
        (col_code, col_slaactionslaevent)
      VALUES
        (sys_guid(), v_idslaevent)
      RETURNING col_id INTO v_idslaaction;
    END IF;
  
    -- define IntervalDS
    v_intervalds := TO_DSINTERVAL(TO_CHAR(v_days) || ' ' || TO_CHAR(v_hours) || ':' ||
                                  TO_CHAR(v_minutes) || ':' || TO_CHAR(v_seconds));
  
    -- define IntervalYM
    v_intervalym := TO_YMINTERVAL('00' || '-' || TO_CHAR(v_months));
  
    BEGIN
      SELECT nvl(MAX(col_slaeventorder), 0) + 1
        INTO v_SlaEventOrder
        FROM tbl_slaevent
       WHERE col_slaeventdict_tasksystype = v_tasktype_Id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_SlaEventOrder := 1;
    END;
  
    --update the values in the records
    UPDATE TBL_SLAEVENT
       SET col_slaeventdict_slaeventtype = v_slaeventtype_id,
           col_slaevent_dateeventtype    = v_dateeventlevel_id,
           col_slaevent_slaeventlevel    = v_slaeventlevel_id,
           col_maxattempts               = v_maxattempts,
           col_slaeventdict_tasksystype  = v_tasktype_id,
           col_intervalds                = v_intervalds,
           col_intervalym                = v_intervalym,
           col_slaeventorder             = v_SlaEventOrder
     WHERE col_id = v_idslaevent;
  
    UPDATE TBL_SLAACTION
       SET col_processorcode           = v_processorcode,
           col_slaaction_slaeventlevel = v_slaeventlevel_id,
           col_description             = v_description
     WHERE col_id = v_idslaaction;
  
    :affectedRows := 1;
    :recordId     := v_idslaaction;
  
    -- Send ParamCodes and ParamValues to the STP_setAutoRuleParams function
    v_res := f_stp_setautoruleparams(errorcode        => v_errorcode,
                                     errormessage     => v_errormessage,
                                     objecttargetrid  => v_idslaaction,
                                     objecttargettype => v_processorcode,
                                     paramcodes       => v_paramcodes,
                                     paramvalues      => v_paramvalues);
  EXCEPTION
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
      v_errormessage   := SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;