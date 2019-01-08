DECLARE
  --custom 
  v_customdataprocessor     NVARCHAR2(255);
  v_retcustdataprocessor    NVARCHAR2(255);
  v_updatecustdataprocessor NVARCHAR2(255);
  v_executionmethod_id      NVARCHAR2(255);
  v_dateeventcustdataproc   NVARCHAR2(255);
  v_processorcode           NVARCHAR2(255);
  v_id                      NUMBER;
  v_name                    NVARCHAR2(255);
  v_code                    NVARCHAR2(255);
  v_aotcode                 NVARCHAR2(255);
  v_aotid                   NUMBER;
  v_isdeleted               NUMBER;
  v_description             NCLOB;
  v_resolutioncodes_ids     NCLOB;
  v_initmethodcode          NVARCHAR2(255);
  v_initmethodid            NUMBER;
  v_stateconfig             NUMBER;
  v_iconcode                NVARCHAR2(255);
  v_isId                    NUMBER;
  v_result                  NUMBER;

  --standard 
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_aotcode := 'TASK_TYPE';

  --custom 
  v_customdataprocessor     := :Customdataprocessor;
  v_retcustdataprocessor    := :Retcustdataprocessor;
  v_updatecustdataprocessor := :Updatecustdataprocessor;
  v_executionmethod_id      := :ExecutionMethod_Id;
  v_dateeventcustdataproc   := :DateEventCustDataProc;
  v_processorcode           := :ProcessorCode;
  v_id                      := :Id;
  v_name                    := :NAME;
  v_code                    := :Code;
  v_isdeleted               := Nvl(:IsDeleted, 0);
  v_description             := :Description;
  v_resolutioncodes_ids     := Nvl(:ResolutionCodes_IDs, '');
  v_stateconfig             := :StateConfig_Id;
  v_iconcode                := NVL(:IconCode, 'cube');

  --standard 
  :affectedRows    := 0;
  :SuccessResponse := EMPTY_CLOB();
  v_errorcode      := 0;
  v_errormessage   := '';

  BEGIN
    -- validation on Id is Exist
    IF NVL(v_id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_id, tablename => 'TBL_DICT_TASKSYSTYPE');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    --set assumed success message 
    IF v_id IS NOT NULL THEN
      v_result := LOC_i18n(MessageText => 'Updated {{MESS_TASKTYPE}} task type', MessageResult => :SuccessResponse, MessageParams => NES_TABLE(Key_Value('MESS_TASKTYPE', v_name)));
    ELSE
      v_result := LOC_i18n(MessageText => 'Created {{MESS_TASKTYPE}} task type', MessageResult => :SuccessResponse, MessageParams => NES_TABLE(Key_Value('MESS_TASKTYPE', v_name)));
    END IF;
  
    --:SuccessResponse := :SuccessResponse || ' "' || v_name || '" task type';
  
    IF V_EXECUTIONMETHOD_ID IS NULL OR V_EXECUTIONMETHOD_ID = 0 THEN
      BEGIN
        SELECT COL_ID
          INTO V_EXECUTIONMETHOD_ID
          FROM TBL_DICT_EXECUTIONMETHOD
         WHERE NVL(COL_ISDELETED, 0) = 0
           AND COL_CODE = 'MANUAL';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          V_EXECUTIONMETHOD_ID := 0;
      END;
    END IF;
  
    -- get Access Object Type
    v_aotid := f_util_getidbycode(code => v_aotcode, tablename => 'tbl_ac_accessobjecttype');
  
    --create new record if needed 
    IF v_id IS NULL THEN
      INSERT INTO tbl_dict_tasksystype (col_code, col_isdeleted) VALUES (v_code, 0) RETURNING col_id INTO v_id;
    
      INSERT INTO tbl_ac_accessobject
        (col_code, col_accessobjecttasksystype, col_accessobjaccessobjtype)
      VALUES
        (F_util_calcuniquecode(basecode => v_code || '_' || v_aotcode, tablename => 'tbl_ac_accessobject'), v_id, v_aotid);
    
      --add default state inits 
      v_initmethodcode := 'MANUAL';
      v_initmethodid   := f_util_getidbycode(code => v_initmethodcode, tablename => 'tbl_dict_initmethod');
      IF NVL(v_stateconfig, 0) = 0 THEN
        BEGIN
          SELECT col_id
            INTO v_stateconfig
            FROM tbl_dict_StateConfig
           WHERE col_isdefault = 1
             AND lower(col_type) = 'task'
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            v_stateconfig := 0;
        END;
      END IF;
    
      FOR cur IN (SELECT col_id,
                         col_code,
                         col_name,
                         col_activity
                    FROM tbl_dict_taskstate
                   WHERE Nvl(col_stateconfigtaskstate, 0) = v_stateconfig) LOOP
        INSERT INTO tbl_map_taskstateinitiation
          (col_taskstateinit_tasksystype, col_map_tskstinit_initmtd, col_map_tskstinit_tskst, col_code)
        VALUES
          (v_id, v_initmethodid, cur.col_id, f_UTIL_calcUniqueCode(BaseCode => v_code || '_' || cur.col_code, TableName => 'tbl_map_taskstateinitiation'));
        INSERT INTO tbl_map_taskstateinittmpl
          (col_taskstateinittp_tasktype, col_map_tskstinittpl_initmtd, col_map_tskstinittpl_tskst, col_code)
        VALUES
          (v_id, v_initmethodid, cur.col_id, f_UTIL_calcUniqueCode(BaseCode => v_code || '_' || cur.col_code, TableName => 'tbl_map_taskstateinitiation'));
      END LOOP;
    END IF;
  
    --update the record 
    UPDATE tbl_dict_tasksystype
       SET col_customdataprocessor     = v_customdataprocessor,
           col_retcustdataprocessor    = v_retcustdataprocessor,
           col_updatecustdataprocessor = v_updatecustdataprocessor,
           col_processorcode           = v_processorcode,
           col_tasksystypeexecmethod   = v_executionmethod_id,
           col_dateeventcustdataproc   = v_dateeventcustdataproc,
           col_name                    = v_name,
           col_isdeleted               = v_isdeleted,
           col_description             = v_description,
           col_stateconfigtasksystype  = v_stateconfig,
           col_iconcode                = v_iconcode
     WHERE col_id = v_id;
  
    UPDATE tbl_ac_accessobject SET col_name = v_name, col_code = v_aotcode || '_' || v_code WHERE col_accessobjecttasksystype = v_id;
  
    --set resolution codes 
    DELETE FROM tbl_tasksystyperesolutioncode WHERE col_tbl_dict_tasksystype = v_id;
  
    FOR rec IN (SELECT TO_NUMBER(regexp_substr(v_resolutioncodes_ids, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS resolutioncodeid
                  FROM dual
                CONNECT BY dbms_lob.getlength(regexp_substr(v_resolutioncodes_ids, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) LOOP
    
      INSERT INTO tbl_tasksystyperesolutioncode (col_tbl_stp_resolutioncode, col_tbl_dict_tasksystype) VALUES (rec.resolutioncodeid, v_id);
    END LOOP;
  
    --set output 
    :affectedRows := SQL%ROWCOUNT;
    :recordId     := v_id;
  EXCEPTION
    WHEN dup_val_on_index THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
      v_errormessage   := 'There already exists a task type with the code {{MESS_TASKTYPE}}';
      v_result         := LOC_i18n(MessageText => v_errormessage, MessageResult => v_errormessage, MessageParams => NES_TABLE(Key_Value('MESS_TASKTYPE', To_char(v_code))));
      :SuccessResponse := '';
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 102;
      v_errormessage   := Substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
