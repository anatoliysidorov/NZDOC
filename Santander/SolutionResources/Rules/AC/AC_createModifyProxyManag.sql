DECLARE
    v_Id                  NUMBER;
    v_CaseWorker_Assignee INTEGER;
    v_CaseWorker_Assignor INTEGER;
    v_StartDate           DATE;
    v_EndDate             DATE;
    v_Reason              NCLOB;
    v_ErrorCode           NUMBER;
    v_ErrorMessage        NVARCHAR2(255);
    v_AvailablePeriod     NUMBER;
    v_Code                NVARCHAR2(255);
    v_IsDeleted           NUMBER;
	v_isId		   		  INT;
	v_result			  NUMBER;
BEGIN  
    v_Id                  := :Id;
    v_CaseWorker_Assignee := :CaseWorker_Assignee_Id;
    v_CaseWorker_Assignor := :CaseWorker_Assignor_Id;
    v_StartDate           := TRUNC(:StartDate);
    v_EndDate             := TRUNC(NVL(:EndDate, SYSDATE)) + 1 - 1/86400; -- 1 second before next day
    v_Reason              := :Reason;
    :affectedRows         := 0;
    v_ErrorCode           := 0;
    v_ErrorMessage        := '';
    v_Code                := :Code;
    v_AvailablePeriod     := null;
    v_IsDeleted           := :ISDELETED; 
/*    
    select cw.ID into v_CaseWorker_Assignor
    from vw_PPL_CaseWorkersUsers cw
    where cw.ACCODE = sys_context('CLIENTCONTEXT', 'AccessSubject');
*/ 
    :SuccessResponse := '';
    -- Input params check
    IF v_CaseWorker_Assignee IS NULL THEN
       v_ErrorMessage  := 'Case Worker Assignee(ID) can not be empty';
       v_ErrorCode     := 101;
       :SuccessResponse := '';
       GOTO cleanup;
    ELSIF v_StartDate IS NULL THEN
       v_ErrorMessage  := 'Start Date can not be empty';
       v_ErrorCode     := 101;
       :SuccessResponse := '';
       GOTO cleanup;
    ELSIF v_EndDate IS NULL THEN
       v_ErrorMessage  := 'End Date can not be empty';
       v_ErrorCode     := 101;
       :SuccessResponse := '';
       GOTO cleanup;
    ELSIF trunc(v_StartDate) > trunc(v_EndDate) THEN
       v_ErrorMessage  := 'Start date cannot be after the End date';
       v_ErrorCode     := 101;
       :SuccessResponse := '';
       GOTO cleanup;
   /*add*/
    ELSIF v_CaseWorker_Assignor IS NULL THEN
       v_ErrorMessage  := 'Case Worker Assignor(ID) can not be empty';
       v_ErrorCode     := 101;
       :SuccessResponse := '';
       GOTO cleanup;
    ELSIF v_CaseWorker_Assignor = v_CaseWorker_Assignee THEN
       v_ErrorMessage  := 'You can not set the Proxy to the same Case Worker';
       v_ErrorCode     := 101;
       :SuccessResponse := '';
       GOTO cleanup;
   /*add*/
    END IF;
    
	-- validation on Id is Exist
    IF NVL(v_id, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_id,
                             tablename    => 'TBL_PROXY');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
    IF NVL(v_CaseWorker_Assignee, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_CaseWorker_Assignee,
                             tablename    => 'TBL_PPL_CASEWORKER');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
    IF NVL(v_CaseWorker_Assignor, 0) > 0 THEN
      v_isId := f_UTIL_getId(errorcode    => v_errorcode,
                             errormessage => v_errormessage,
                             id           => v_CaseWorker_Assignor,
                             tablename    => 'TBL_PPL_CASEWORKER');
      IF v_errorcode > 0 THEN
        GOTO cleanup;
      END IF;
    END IF;
  
    select count(*) into v_AvailablePeriod
    from tbl_proxy px
    where px.COL_ASSIGNOR = v_CaseWorker_Assignor
      and not ((trunc(COL_STARTDATE) > trunc(v_EndDate)) or (trunc(COL_ENDDATE) < trunc(v_StartDate)))
      and (v_Id is null or px.COL_ID <> v_Id);

    IF v_AvailablePeriod > 0 THEN
        v_ErrorMessage := 'There is already a proxy assigned for this time period: '
		|| '<br> from {{MESS_STARTDATE}} to {{MESS_ENDDATE}}';
		v_result := LOC_i18n(
			MessageText => v_errormessage,
			MessageResult => v_errormessage,
			MessageParams => NES_TABLE(
				Key_Value('MESS_STARTDATE', trunc(v_StartDate)),
				Key_Value('MESS_ENDDATE', trunc(v_EndDate))
			)
		);        
		v_ErrorCode    := 106;
        :SuccessResponse := '';
        GOTO cleanup;
    END IF;
    IF v_id IS NOT NULL THEN
		:SuccessResponse := 'Updated proxy record';
	ELSE
		:SuccessResponse := 'Created proxy record';
	END IF;
    BEGIN
        --add new record or update existing one
        IF v_id IS NULL THEN
          INSERT INTO tbl_proxy
             ( COL_CODE,
               COL_ASSIGNEE,
               COL_ASSIGNOR,
               COL_ENDDATE,
               COL_STARTDATE,
               COL_REASON)
          VALUES     
             ( v_Code,
               v_CaseWorker_Assignee,
               v_CaseWorker_Assignor,
               v_EndDate,
               v_StartDate,
               v_Reason);
          SELECT gen_tbl_proxy.CURRVAL INTO :recordId FROM dual;
          :affectedRows := 1;
        ELSE
          UPDATE tbl_proxy
          SET    COL_CODE       = v_Code,
                 COL_ASSIGNEE   = v_CaseWorker_Assignee,
                 COL_ASSIGNOR   = v_CaseWorker_Assignor,
                 COL_ENDDATE    = v_EndDate,
                 COL_STARTDATE  = v_StartDate,
                 COL_REASON     = v_Reason,
                 COL_ISDELETED  = v_IsDeleted
          WHERE  col_id = v_id;
          :affectedRows := 1;
          :recordId := v_id;
        END IF;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            :affectedRows   := 0;
            v_ErrorCode     := 101;
            v_ErrorMessage  := 'There already exists a proxy with the value {{MESS_PROXY}}';
			v_result := LOC_i18n(
				MessageText => v_errormessage,
				MessageResult => v_errormessage,
				MessageParams => NES_TABLE(
					Key_Value('MESS_PROXY', trunc(v_Code))
				)
			);            :SuccessResponse := '';
        WHEN OTHERS THEN
            :affectedRows   := 0;
            v_ErrorCode     := 102;
            v_ErrorMessage  := substr(SQLERRM, 1, 200);
            :SuccessResponse := '';
    END;
    
    <<cleanup>>
    :errorCode    := v_ErrorCode;
    :errorMessage := v_ErrorMessage;   
END;