DECLARE
  /*--INPUT*/
  v_InputXML NCLOB;

  /*--CASE CREATE INPUT PROCESS*/
  v_summary          NVARCHAR2(1000);
  v_taskid           INTEGER;
  v_CASETYPE_ID      INTEGER;
  v_CASESYSTYPE_CODE NVARCHAR2(255);
  v_casename         NVARCHAR2(255);
  v_description      NCLOB;
  v_PRIORITY_ID      INTEGER;
  v_draft            NUMBER;
  v_DOCUMENTURLS     NCLOB;
  v_DOCUMENTNAMES    NCLOB;
  v_WORKBASKET_ID    INTEGER;
  v_piWorkitemId     INTEGER;
  v_caseid           INTEGER;
  v_calc_caseid      INTEGER;
  v_ParentCaseId     INTEGER;
  v_LinkTypeId       INTEGER;

  /*--MDM PROCESS*/
  v_CustomDataXML    XMLTYPE;
  v_ParentCode       NVARCHAR2(255);
  v_ParentId         NVARCHAR2(255);
  v_CreateConfigCode NVARCHAR2(255);
  v_CreateConfigId   INTEGER;
  v_CreateConfigName NVARCHAR2(255);
  v_CreateModelId    INTEGER;
  v_EditConfigCode   NVARCHAR2(255);
  v_EditConfigId     INTEGER;
  v_EditConfigName   NVARCHAR2(255);
  v_EditModelId      INTEGER;
  v_RootObjectId     INTEGER;
  v_RootObjectName   NVARCHAR2(255);
  v_session          NVARCHAR2(255);
  
  v_CASEWORKER_ID            NUMBER;
  v_partytypeid              NUMBER;  
  v_purposeName              NVARCHAR2(255);
  

  /*--GENERAL*/
  v_result     INTEGER;
  v_tempErrCd  INTEGER;
  v_tempErrMsg NCLOB;
  v_tempSccss  NCLOB;
  v_message    NCLOB;
  v_historyMsg      NCLOB;
  v_ErrorCode        NUMBER;
  v_ErrorMessage     NCLOB;
  v_validationresult NUMBER;
  v_WarningCode        NUMBER;
  v_WarningMessage     NCLOB;
  --v_InData CLOB;
  v_outData CLOB;
  

BEGIN

  /*--INPUT BINDING*/
  v_InputXML := :InputXML;
  
  /* init */
  v_CASEWORKER_ID  := NULL; 
  v_partytypeid    := NULL;
  v_purposeName    := NULL;
  v_WarningCode    := NULL;
  v_WarningMessage := NULL;
  
  
  /*--CONVERT XML STRING TO XMLType*/
  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Attempting to parse Input XML');
  BEGIN
    if instr(v_InputXML, '<SUMMARY><![CDATA[') = 0 then
      v_InputXML := regexp_replace(v_InputXML, '<SUMMARY>(.+)</SUMMARY>', '<SUMMARY><![CDATA[\1]]></SUMMARY>');
    end if;
    if instr(v_InputXML, '<DESCRIPTION><![CDATA[') = 0 then
      v_InputXML := regexp_replace(v_InputXML, '<DESCRIPTION>(.+)</DESCRIPTION>', '<DESCRIPTION><![CDATA[\1]]></DESCRIPTION>');
    end if;
    v_CustomDataXML := XMLType(v_InputXML);
  EXCEPTION
    WHEN OTHERS THEN
      v_message    := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'SQLCODE: ' || TO_CHAR(SQLCODE));
      v_message    := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'SQLERRM: ');
      v_message    := f_UTIL_addToMessage(originalMsg => v_message, newMsg => SQLERRM);
      v_tempErrMsg := 'ERROR: Failed to parse Input XML';
      v_tempErrCd  := 102;
      GOTO cleanup;
  END;

  /*PARSE INPUT XML TO GET CASE DATA*/
  SELECT SUMMARY, DESCRIPTION, PRIORITY_ID, CASESYSTYPE_ID, CASESYSTYPE_CODE, WORKBASKET_ID, DRAFT, DOCUMENTURLS, DOCUMENTNAMES, PIWORKITEM_ID, PARENT_CASE_ID, LINK_TYPE_ID
    INTO v_SUMMARY,
         v_DESCRIPTION,
         v_PRIORITY_ID,
         v_CASETYPE_ID,
         v_CASESYSTYPE_CODE,
         v_WORKBASKET_ID,
         v_DRAFT,
         v_DOCUMENTURLS,
         v_DOCUMENTNAMES,
         v_piWorkitemId,
		 v_ParentCaseId,
		 v_LinkTypeId
    FROM XMLTABLE('/CustomData/Attributes/Object/Item[OBJECTCODE="CASE"]' PASSING v_CustomDataXML COLUMNS SUMMARY NCLOB PATH 'SUMMARY',
                  DESCRIPTION NCLOB PATH 'DESCRIPTION',
                  PRIORITY_ID INT PATH 'PRIORITY_ID',
                  CASESYSTYPE_ID INT PATH 'CASESYSTYPE_ID',
                  CASESYSTYPE_CODE NVARCHAR2(255) PATH 'CASESYSTYPE_CODE',
                  WORKBASKET_ID INT PATH 'OWNER_WORKBASKET_ID',
                  DRAFT INT PATH 'DRAFT',
                  DOCUMENTURLS CLOB PATH 'DOCUMENTSURLS',
                  DOCUMENTNAMES CLOB PATH 'DOCUMENTSNAMES',
                  PIWORKITEM_ID INT PATH 'PIWORKITEM_ID',
				  PARENT_CASE_ID INT PATH 'PARENT_CASE_ID',
				  LINK_TYPE_ID INT PATH 'LINK_TYPE_ID'
				  );

  /*CREATE CASE*/
  v_message := f_UTIL_addToMessage(originalMsg => v_message,
                                   newMsg      => 'INFO: using Case Type ID ' || to_char(v_CASETYPE_ID) || ' or code ' || v_CASESYSTYPE_CODE);
  v_result  := f_DCM_createCaseWithOptionsFn(InData              => v_InputXML,
                                             OutData             => v_outData,
                                             CASESYSTYPE_ID      => v_CASETYPE_ID,
                                             CASESYSTYPE_CODE    => v_CASESYSTYPE_CODE,
                                             CUSTOMDATA          => v_InputXML,
                                             CaseName            => v_casename,
                                             DESCRIPTION         => v_description,
                                             DocumentsNames      => v_DOCUMENTNAMES,
                                             DocumentsURLs       => v_DOCUMENTURLS,
                                             Draft               => v_draft,
                                             OWNER_WORKBASKET_ID => v_WORKBASKET_ID,
                                             PRIORITY_ID         => v_PRIORITY_ID,
                                             SUMMARY             => v_summary,

                                             Case_Id         => v_CaseId,
                                             Task_Id         => v_taskid,
                                             ErrorCode       => v_tempErrCd,
                                             ErrorMessage    => v_tempErrMsg,
                                             SuccessResponse => v_tempSccss,

                                             preventDocFolderCreate => NULL,
                                             TargetCaseId           => NULL,
                                             CaseFrom               => NULL,
                                             PROCEDURE_CODE         => NULL,
                                             PROCEDURE_ID           => NULL,
                                             ResolveBy              => NULL,
                                             TargetTaskId           => NULL,
                                             AdHocName              => NULL,
                                             AdHocProcCode          => NULL,
                                             AdhocProcId            => NULL,
                                             AdhocTaskTypeCode      => NULL,
                                             AdhocTaskTypeId        => NULL,
                                             PIWorkitemId           => v_piWorkitemId,
                                             PARENT_CASE_ID => v_ParentCaseId,
                                             LINK_TYPE_ID => v_LinkTypeId); 
                                             
  IF NVL(v_CaseId, 0) <= 0 THEN

    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: There was a problem creating the Case');
    GOTO cleanup;

  ELSE

    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Created Case with ID ' || TO_CHAR(v_CaseId));
    :Case_Id  := v_CaseId;

    --create case party record
    IF NVL(v_WORKBASKET_ID, 0)<>0 THEN
      BEGIN
        SELECT wb.COL_CASEWORKERWORKBASKET, NVL(wb.COL_NAME, 'user')
          INTO v_CASEWORKER_ID, v_purposeName
          FROM tbl_ppl_workbasket wb
         INNER JOIN vw_ppl_activecaseworker cw
            ON wb.col_caseworkerworkbasket = cw.col_id
         INNER JOIN vw_ppl_activecaseworkersusers cwu
            ON cw.col_id = cwu.id
         WHERE wb.col_id = v_WORKBASKET_ID;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN        
          v_CASEWORKER_ID :=NULL;
          v_purposeName   := NULL;
      END;    
                             
      IF (NVL(v_CaseId,0)<>0) AND (NVL(v_CASEWORKER_ID,0)<>0) THEN
        -- get PartyType_Id
        v_partytypeid := f_UTIL_getIdByCode(Code => 'CASEWORKER', TableName => 'tbl_dict_participantunittype');
        INSERT INTO TBL_CASEPARTY
          (col_allowdelete, col_casepartycase, col_casepartydict_unittype,
           col_casepartyppl_caseworker, col_casepartyexternalparty,
           col_casepartyppl_businessrole, col_casepartyppl_skill,
           col_casepartyppl_team, col_name)
        VALUES
          (0, v_caseid, v_partytypeid, v_CASEWORKER_ID, 0,0,0,0, v_purposeName);    
      END IF;
              
    END IF;--NVL(v_WORKBASKET_ID, 0)<>0
    
  END IF;

  /*CREATE MDM DATA*/
  v_RootObjectName := 'CASE';
  v_result         := f_MDM_getCaseOrCTinfoFn(calc_CaseId       => v_calc_caseid,
                                              calc_CaseTypeId   => v_CASETYPE_ID,
                                              calc_TaskId       => v_taskid,
                                              CaseID            => v_caseid,
                                              CaseTypeID        => v_CASETYPE_ID,
                                              create_ConfigCode => v_CreateConfigCode,
                                              create_ConfigId   => v_CreateConfigId,
                                              create_ConfigName => v_CreateConfigName,
                                              create_ModelId    => v_CreateModelId,
                                              edit_ConfigCode   => v_EditConfigCode,
                                              edit_ConfigId     => v_EditConfigId,
                                              edit_ConfigName   => v_EditConfigName,
                                              edit_ModelId      => v_EditModelId,
                                              TaskId            => NULL);
                                                                                            
  IF NVL(v_CreateConfigId, 0) = 0 THEN
    /*v_tempErrMsg := 'ERROR: Can''t find the MDM Create Configuration for the Case with ID ' || TO_CHAR(v_caseid) ;
    v_tempErrCd := 102;
    GOTO cleanup;*/
    NULL; --this allows a Case to be created even if it's MDM model has not been created yet
  ELSE
    v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Using Create Config ID ' || TO_CHAR(v_CreateConfigId));

    v_result := f_DOM_populateDynInsCache(ConfigId       => v_CreateConfigId,
                                          Input          => v_inputXML,
                                          RootObjectId   => v_CaseId,
                                          RootObjectName => v_RootObjectName,
                                          Session        => v_session);

    v_result := f_DOM_executeDynIns(ConfigId => v_CreateConfigId, Session => v_session);

     /*CASE ROUTING*/
    v_result := f_DCM_copyCaseToCache(CaseId => v_CaseId);
    v_result := f_dcm_invalidatecase(CaseId => v_CaseId);
    v_result := f_dcm_casequeueproc7();
    v_result := f_DCM_updateCaseFromCache(CaseId => v_CaseId);
    v_result := f_DCM_clearCache(CaseId => v_CaseId);

    /*GET CASE DATA FOR HISTORY PURPOSES*/
    v_result := f_SOM_getCaseWithData(CaseTypeId => v_CASETYPE_ID, ErrorCode => v_tempErrCd, ErrorMessage => v_tempErrMsg, RootObjectId => v_CaseId);

    IF NVL(v_tempErrCd, 0) > 0 THEN
      v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR: There was a problem retrieving Case MDM data');
      GOTO cleanup;
    ELSE
      v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'INFO: Retrieved Case Data with ' || v_tempErrMsg);
    END IF;

    /*CREATE HISTORY*/
    v_result := f_HIST_createHistoryFn(AdditionalInfo => NULL,
                                       IsSystem       => NULL,
                                       MESSAGE        => NULL,
                                       MessageCode    => 'CaseModified',
                                       TargetID       => v_CaseId,
                                       TargetType     => 'CASE');

    /*--SUCCESS BLOCK*/
    :ERRORCODE       := 0;
    :ERRORMESSAGE    := '';
    :SUCCESSRESPONSE := v_tempSccss;
    :EXECUTIONLOG    := v_message;
    --RETURN;
    GOTO cleanup;
  END IF;

  /*--ERROR BLOCK*/
  <<cleanup>>
      
  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_CASE_MDM- AND*/
  /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
  IF NVL(v_caseid, 0)<>0 THEN
    v_result := F_dcm_processcommonevent(InData           =>v_InputXML,
                                         OutData          =>v_outData,
                                         Attributes       => NULL,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => v_CASETYPE_ID,
                                         commoneventtype  => 'CREATE_CASE_MDM',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'AFTER',
                                         eventtype        => 'ACTION',
                                         historymessage   => v_historymsg,
                                         procedureid      => NULL,
                                         taskid           => NULL,
                                         tasktypeid       => NULL,
                                         validationresult => v_validationresult);
    /*--write to history*/
    IF v_historymsg IS NOT NULL THEN
      v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                         issystem       => 0,
                                         MESSAGE        => 'Action Common event(s)',
                                         messagecode    => 'CommonEvent',
                                         targetid       => v_caseid,
                                         targettype     => 'CASE');
    END IF; 
  END IF;   
  
  /* WARNING HANDLING */
  IF v_validationresult=0 THEN
    v_WarningCode    := v_errorcode;
    v_WarningMessage := v_errormessage; 
  END IF;
      
  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR CODE: ' || v_tempErrCd);
  v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'ERROR MSG: ' || v_tempErrMsg);
  IF v_CaseId > 0 and nvl(v_tempErrCd, 0) > 0 THEN
    v_result := f_HIST_createHistoryFn(AdditionalInfo => v_message,
                                       IsSystem       => 0,
                                       MESSAGE        => NULL,
                                       MessageCode    => 'GenericEventFailure',
                                       TargetID       => v_CaseId,
                                       TargetType     => 'CASE');
  END IF;

  :ERRORCODE       := v_tempErrCd;
  :ERRORMESSAGE    := v_tempErrMsg;
  :EXECUTIONLOG    := v_message;
  :SUCCESSRESPONSE := '';
  :WARNINGCODE     := v_WarningCode;
  :WARNINGMESSAGE  := v_WarningMessage;
  

EXCEPTION
  WHEN OTHERS THEN
    v_message        := f_UTIL_addToMessage(originalMsg => v_message, newMsg => 'SQL ERROR: ');
    v_message        := f_UTIL_addToMessage(originalMsg => v_message, newMsg => dbms_utility.format_error_backtrace);
    v_message        := f_UTIL_addToMessage(originalMsg => v_message, newMsg => Dbms_Utility.format_error_stack);
    :ERRORCODE       := 103;
    :ERRORMESSAGE    := 'There was an error creating the Case';
    :EXECUTIONLOG    := v_message;
    :SUCCESSRESPONSE := '';
    :WARNINGCODE     := v_WarningCode;
    :WARNINGMESSAGE  := v_WarningMessage;
    
END;