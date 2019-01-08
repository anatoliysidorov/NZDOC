DECLARE
  v_caseid                   INTEGER;
  v_casename                 NVARCHAR2(255);
  v_casetypeid               INTEGER;
  v_casetype                 NVARCHAR2(255);
  v_procedureid              INTEGER;
  v_procedurecode            NVARCHAR2(255);
  v_adhocproccode            NVARCHAR2(255);
  v_adhocprocid              INTEGER;
  v_adhoctasktypecode        NVARCHAR2(255);
  v_adhoctasktypeid          INTEGER;
  v_sourceid                 INTEGER;
  v_taskid                   INTEGER;
  v_adhocname                NVARCHAR2(255);
  v_taskname                 NVARCHAR2(255);
  v_taskextid                INTEGER;
  v_validationresult         NUMBER;
  v_validationstatus         NUMBER;
  v_result                   NUMBER;
  v_customdata               NCLOB;
  v_customvalidator          NVARCHAR2(255);
  v_customvalresultprocessor NVARCHAR2(255);
  v_description              NCLOB;
  v_draft                    NUMBER;
  v_preventdocfoldercreate   NUMBER;
  v_errorcode                NUMBER;
  v_errormessage             NCLOB;
  v_ownerworkbasketid        INTEGER;
  v_workbasket_name          NVARCHAR2(255);
 
  v_summary                  NCLOB;
  v_casefrom                 NVARCHAR2(255);
  v_priority                 INTEGER;
  v_resolveby                DATE;
  v_successresponse          NCLOB;
  v_targetcaseid             INTEGER;
  v_targettaskid             INTEGER;
  v_debugsession             NVARCHAR2(255);
  v_commoneventcode          NVARCHAR2(255);
  v_historymsg               NCLOB;
  v_historymsg1              NCLOB;
  v_piWorkitemId             NUMBER;
  v_ParentCaseId             INTEGER;
  v_LinkTypeId               INTEGER;
  
  v_MilestoneDiagramID       INTEGER;
  v_MilestoneActivity        NVARCHAR2(255);
  v_IsValid                  INTEGER;
  v_Attributes               NVARCHAR2(32767);
  
  v_FormData NVARCHAR2(32767);
  v_CaseObjectData NVARCHAR2(32767);
  v_InData CLOB;
  v_outData CLOB;
  
  
BEGIN
  v_casetypeid    := :CASESYSTYPE_ID;
  v_casetype      := :CASESYSTYPE_CODE;
  v_procedureid   := :PROCEDURE_ID;
  v_procedurecode := :PROCEDURE_CODE;
  v_customdata    := :CUSTOMDATA;
  IF v_customdata IS NULL THEN
    v_customdata := '<CustomData><Attributes></Attributes></CustomData>';
  END IF;
  v_priority               := :PRIORITY_ID;
  v_summary                := :SUMMARY;
  v_casefrom               := NVL(:CaseFrom, 'main'); /*--options are either 'main' or 'portal'*/
  v_resolveby              := :ResolveBy;
  v_description            := :DESCRIPTION;
  v_draft                  := NVL(:Draft, 0);
  v_ownerworkbasketid      := :OWNER_WORKBASKET_ID;
  v_adhocproccode          := :AdhocProcCode;
  v_adhocprocid            := :AdhocProcId;
  v_targetcaseid           := :TargetCaseId;
  v_targettaskid           := :TargetTaskId;
  v_adhoctasktypecode      := :AdhocTaskTypeCode;
  v_adhoctasktypeid        := :AdhocTaskTypeId;
  v_adhocname              := :AdHocName;
  v_InData                 := :InData;
  
  :CaseName                := NULL;
  :Case_Id                 := NULL;
  :ErrorCode               := NULL;
  :ErrorMessage            := NULL;
  :SuccessResponse         := NULL;
  :Task_Id                 := NULL;
  :OutData                 := NULL;
  v_preventdocfoldercreate := NVL(:preventDocFolderCreate, 0);
  v_commoneventcode        := lower(to_char(Sys_guid()));
  v_historymsg             := NULL;
  v_historymsg1            := NULL;
  v_piWorkitemId           := :PIWorkitemId;
  v_ParentCaseId           := :PARENT_CASE_ID;
  v_LinkTypeId             := :LINK_TYPE_ID;
  v_Attributes             := NULL;
  v_FormData               := NULL;
  v_CaseObjectData         := NULL;
  v_outData                := NULL;

  IF NVL(v_casetypeid, 0) = 0 AND v_casetype IS NULL AND v_adhocproccode IS NULL AND NVL(v_adhocprocid, 0) = 0 AND NVL(v_targetcaseid, 0) = 0 AND
     NVL(v_targettaskid, 0) = 0 AND v_adhoctasktypecode IS NULL AND NVL(v_adhoctasktypeid, 0) = 0 THEN
    :ErrorCode       := 112;
    :ErrorMessage    := 'Insufficient information for case/procedure/task creation';
    :SuccessResponse := :ErrorMessage;
    RETURN - 1;
  END IF;

  IF NVL(v_casetypeid, 0) = 0 AND v_casetype IS NULL AND v_adhocproccode IS NULL AND NVL(v_adhocprocid, 0) = 0 AND NVL(v_targetcaseid, 0) = 0 AND
     NVL(v_targettaskid, 0) = 0 AND (v_adhoctasktypecode IS NOT NULL OR NVL(v_adhoctasktypeid, 0) > 0) THEN
    :ErrorCode       := 113;
    :ErrorMessage    := 'To create adhoc task you must specify target case or task';
    :SuccessResponse := :ErrorMessage;
    RETURN - 1;
  END IF;

  
  IF v_casetype IS NOT NULL THEN
    BEGIN
      SELECT col_id INTO v_result FROM tbl_dict_casesystype WHERE Lower(col_code) = Lower(v_casetype);
    
    EXCEPTION
      WHEN no_data_found THEN
        v_result := NULL;
    END;
	
	  IF v_result IS NOT NULL THEN
		v_casetypeid := v_result;
	  END IF;
  END IF;

  --FORMULATE XML FOR CASE
  IF v_casetypeid > 0 THEN
	--formulate Case Object Data (so that the structure will be like in MDM)
	IF  f_UTIL_extractXmlAsTextFn(INPUT => v_customdata, PATH=>'/CustomData/Attributes/Object/Item[OBJECTCODE="CASE"]') IS NULL THEN
		v_CaseObjectData := '<Object ObjectCode="CASE"><Item>'; 
		v_CaseObjectData := v_CaseObjectData || '<PARENTID>' ||TO_CHAR(v_ParentCaseId) ||'</PARENTID>';
		v_CaseObjectData := v_CaseObjectData || '<LINKTYPE_ID>' ||TO_CHAR(v_LinkTypeId) ||'</LINKTYPE_ID>';
		v_CaseObjectData := v_CaseObjectData || '<SUMMARY><![CDATA[' || v_summary || ']]></SUMMARY>';
		v_CaseObjectData := v_CaseObjectData || '<DESCRIPTION><![CDATA[' || v_description || ']]></DESCRIPTION>';
		v_CaseObjectData := v_CaseObjectData || '<PRIORITY_ID>'  ||TO_CHAR(v_priority) || '</PRIORITY_ID>';
		v_CaseObjectData := v_CaseObjectData || '<CASESYSTYPE_ID>'  ||TO_CHAR(v_casetypeid) || '</CASESYSTYPE_ID>';
		v_CaseObjectData := v_CaseObjectData || '<DRAFT>'  ||TO_CHAR(v_draft) || '</DRAFT>';
		v_CaseObjectData := v_CaseObjectData || '<OWNER_WORKBASKET_ID>'  ||TO_CHAR(v_ownerworkbasketid) || '</OWNER_WORKBASKET_ID>';
		v_CaseObjectData := v_CaseObjectData || '</Item></Object>';
	END IF;
	
	--get the rest of the custom data
	v_FormData := f_UTIL_extractXmlAsTextFn(INPUT => v_customdata, PATH=>'CustomData/Attributes/*');

  END IF;

  --Check if CaseType is disabled
  IF v_casetypeid > 0 THEN
    BEGIN
      SELECT col_isdeleted INTO v_result FROM tbl_dict_casesystype WHERE col_id = v_casetypeid;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_result := NULL;
      WHEN TOO_MANY_ROWS THEN
        v_result := NULL;
    END;
    IF nvl(v_result, 0) > 0 THEN
      :ErrorCode       := 111;
      :ErrorMessage    := 'Case type is disabled. You can not create case of specified case type';
      :SuccessResponse := :ErrorMessage;
      RETURN - 1;
    END IF;
  END IF;
  /*--Check if user has permission to create case of specified case type*/
  IF v_casetypeid > 0 THEN
    BEGIN
      SELECT id INTO v_result FROM TABLE(F_dcm_getcasetypeaolist()) WHERE casetypeid = v_casetypeid;
    
    EXCEPTION
      WHEN no_data_found THEN
        v_result := NULL;
      WHEN too_many_rows THEN
        v_result := NULL;
    END;
    IF NVL(v_result, 0) > 0 THEN
      v_result := F_dcm_iscasetypecreatealwms(accessobjectid => v_result);
    END IF;
    IF NVL(v_result, 0) = 0 THEN
      :ErrorCode       := 114;
      :ErrorMessage    := 'You do not have permission to create case of specified case type';
      :SuccessResponse := :ErrorMessage;
      RETURN - 1;
    END IF;
  END IF;

  IF NVL(v_casetypeid, 0) > 0 THEN
    v_result := F_dcm_getprocforcasetype(casesystypeid => v_casetypeid, procedurecode => v_procedurecode, procedureid => v_procedureid);
  END IF;

  IF v_adhocproccode IS NOT NULL THEN
    BEGIN
      SELECT col_id INTO v_adhocprocid FROM tbl_procedure WHERE Lower(col_code) = Lower(v_adhocproccode);
    
    EXCEPTION
      WHEN no_data_found THEN
        v_adhocprocid := NULL;
    END;
  END IF;

  IF v_adhocprocid IS NULL AND adhocprocid IS NOT NULL THEN
    v_adhocprocid := adhocprocid;
  END IF;

  BEGIN
    SELECT col_customvalidator INTO v_customvalidator FROM tbl_dict_casesystype WHERE col_id = v_casetypeid;
  
  EXCEPTION
    WHEN no_data_found THEN
      v_customvalidator := NULL;
  END;

  IF NVL(v_targetcaseid, 0) = 0 AND NVL(v_targettaskid, 0) > 0 THEN
    BEGIN
      SELECT col_casetask INTO v_targetcaseid FROM tbl_task WHERE col_id = v_targettaskid;
    
    EXCEPTION
      WHEN no_data_found THEN
        v_targetcaseid   := NULL;
        :ErrorCode       := 102;
        :ErrorMessage    := 'Target Task Id not found';
        :SuccessResponse := :ErrorMessage;
        RETURN - 1;
    END;
  END IF;

  IF v_customvalidator IS NOT NULL THEN
    v_validationresult := F_dcm_invokecasevalidation(caseid => v_caseid, customdata => v_customdata, validator => v_customvalidator);
  
    IF NVL(v_casetypeid, 0) = 0 AND NVL(v_caseid, 0) > 0 THEN
      BEGIN
        SELECT col_casedict_casesystype INTO v_casetypeid FROM tbl_case WHERE col_id = v_caseid;
      
      EXCEPTION
        WHEN no_data_found THEN
          v_casetypeid     := NULL;
          v_caseid         := NULL;
          :ErrorCode       := 110;
          :ErrorMessage    := 'Validation failed: Case not found';
          :SuccessResponse := :ErrorMessage;
          RETURN - 1;
      END;
    END IF;
  
    IF NVL(v_casetypeid, 0) > 0 THEN
      BEGIN
        SELECT col_customvalresultprocessor INTO v_customvalresultprocessor FROM tbl_dict_casesystype WHERE col_id = v_casetypeid;
      
      EXCEPTION
        WHEN no_data_found THEN
          v_customvalresultprocessor := NULL;
      END;
      IF v_customvalresultprocessor IS NOT NULL THEN
        v_validationstatus := F_dcm_invokevalresprocessor(casetypeid       => v_casetypeid,
                                                          errorcode        => v_errorcode,
                                                          errormessage     => v_errormessage,
                                                          processorcode    => v_customvalresultprocessor,
                                                          validationresult => v_validationresult);
        IF v_validationstatus > 0 THEN
          :ErrorCode       := v_errorcode;
          :ErrorMessage    := v_errormessage;
          :SuccessResponse := :ErrorMessage;
          RETURN - 1;
        END IF;
      END IF;
    END IF;
  ELSIF v_targetcaseid IS NOT NULL THEN
    BEGIN
      SELECT col_id INTO v_caseid FROM tbl_case WHERE col_id = v_targetcaseid;
    
    EXCEPTION
      WHEN no_data_found THEN
        v_caseid         := NULL;
        :ErrorCode       := 101;
        :ErrorMessage    := 'Target Case Id not found';
        :SuccessResponse := :ErrorMessage;
        RETURN - 1;
    END;
  ELSE
    v_validationresult := 0;
  END IF;

  /*--CREATE CASE SECTION*/
  IF NVL(v_caseid, 0) = 0 THEN
    IF F_dbg_isdebugon(casetypeid => v_casetypeid, procedureid => v_procedureid) > 0 THEN
      v_debugsession    := F_dbg_createdebugsession(caseid => v_caseid);
      v_successresponse := 'Debug session: ' || TO_CHAR(v_debugsession);
      successresponse   := v_successresponse;
    END IF;
  
    /*--COPY RECORDS FROM DESIGNTIME BO INTO RUNTIME BO*/
    v_result := F_dcm_copycommonevents(caseid      => NULL,
                                       casetypeid  => v_casetypeid,
                                       code        => v_commoneventcode,
                                       procedureid => NULL,
                                       tasktypeid  => NULL,
                                       taskid      => NULL);
  
    /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -CREATE_CASE- AND*/
    /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
    v_validationresult := 1;
	v_Attributes := '<LinkCode>'||v_commoneventcode||'</LinkCode>';
	v_Attributes := v_Attributes || v_CaseObjectData;
	v_Attributes := v_Attributes || v_FormData;	
  
    v_result := F_dcm_processcommonevent(InData           => v_InData,
                                         OutData          => v_outData,    
                                         Attributes       => v_Attributes,
                                         code             => v_commoneventcode,
                                         caseid           => NULL,
                                         casetypeid       => v_casetypeid,
                                         commoneventtype  => 'CREATE_CASE',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'BEFORE',
                                         eventtype        => 'VALIDATION',
                                         historymessage   => v_historymsg,
                                         procedureid      => NULL,
                                         taskid           => NULL,
                                         tasktypeid       => NULL,
                                         validationresult => v_validationresult);
  
    IF NVL(v_validationresult, 0) = 0 THEN
      :ErrorCode       := v_errorcode;
      :ErrorMessage    := v_errormessage;
      :SuccessResponse := :ErrorMessage;      
    
      /*--UPDATE RECORDS INSIDE RUNTIME BO with CODE=v_commonEventCode (link to created Case)*/
      UPDATE tbl_commonevent SET col_commoneventcase = 0 WHERE lower(col_linkcode) = v_commoneventcode;
    
      RETURN - 1;
    END IF;
  
    IF v_validationresult = 1 THEN
    
      /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_CASE- AND*/
      /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
      v_validationresult := 1;
      v_result := F_dcm_processcommonevent(InData           => v_InData,
                                           OutData          => v_outData,    
                                           Attributes       => v_Attributes,
                                           code             => v_commoneventcode,
                                           caseid           => NULL,
                                           casetypeid       => v_casetypeid,
                                           commoneventtype  => 'CREATE_CASE',
                                           errorcode        => v_errorcode,
                                           errormessage     => v_errormessage,
                                           eventmoment      => 'BEFORE',
                                           eventtype        => 'ACTION',
                                           historymessage   => v_historymsg1,
                                           procedureid      => NULL,
                                           taskid           => NULL,
                                           tasktypeid       => NULL,
                                           validationresult => v_validationresult);    
    
      /*--CALL CREATE CASE RULE*/
      v_result := F_dcm_createcasefromctfn(case_id                => v_caseid,
                                           casename               => v_casename,
                                           casesystype_code       => v_casetype,
                                           casesystype_id         => v_casetypeid,
                                           customdata             => v_customdata,
                                           description            => v_description,
                                           documentsnames         => documentsnames,
                                           documentsurls          => documentsurls,
                                           draft                  => v_draft,
                                           errorcode              => v_errorcode,
                                           errormessage           => v_errormessage,
                                           owner_workbasket_id    => v_ownerworkbasketid,
                                           priority_id            => v_priority,
                                           procedure_code         => v_procedurecode,
                                           procedure_id           => v_procedureid,
                                           resolveby              => v_resolveby,
                                           successresponse        => v_successresponse,
                                           summary                => v_summary,
                                           preventdocfoldercreate => v_preventdocfoldercreate,
                                           casefrom               => v_casefrom);
    
      /*--SET OUTPUT*/
      case_id          := v_caseid;
      casename         := v_casename;
      :ErrorCode       := v_errorcode;
      :ErrorMessage    := v_errormessage;
      :SuccessResponse := v_successresponse;      
      
      IF NVL(v_errorcode, 0) NOT IN (0, 200) THEN
        RETURN - 1;
      END IF;      
    
      IF (v_ParentCaseId IS NOT NULL AND v_LinkTypeId IS NOT NULL) THEN
        v_result := F_DCM_CreateModifyCaseLinkFn(ErrorCode         => v_errorcode,
                                                 ErrorMessage      => v_errormessage,
                                                 LINKID            => NULL,
                                                 LINK_PARENTCASEID => v_ParentCaseId,
                                                 LINK_CHILDCASEID  => v_caseid,
                                                 LINK_DESCRIPTION  => 'Create Case and Link',
                                                 LINK_TYPE         => v_LinkTypeId);
      END IF;
    
      /*--UPDATE RECORDS INSIDE RUNTIME BO with CODE=v_commonEventCode (link to created Case)*/
      UPDATE tbl_commonevent SET col_commoneventcase = v_caseid WHERE lower(col_linkcode) = v_commoneventcode;
    
      /*--write to history*/
      IF v_historymsg IS NOT NULL THEN
        v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                           issystem       => 0,
                                           MESSAGE        => 'Validation Common event(s)',
                                           messagecode    => 'CommonEvent',
                                           targetid       => v_caseid,
                                           targettype     => 'CASE');
      END IF;
      
      /*--write to history*/
      IF v_historymsg1 IS NOT NULL THEN
        v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg1,
                                           issystem       => 0,
                                           MESSAGE        => 'Action Common event(s)',
                                           messagecode    => 'CommonEvent',
                                           targetid       => v_caseid,
                                           targettype     => 'CASE');
      END IF;      
                    
      /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_CASE- AND*/
      /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
		v_Attributes := v_CaseObjectData;
		v_Attributes := v_Attributes || v_FormData;	
      v_result := F_dcm_processcommonevent(InData           => v_InData,
                                           OutData          => v_outData,    
                                           Attributes       => v_Attributes,
                                           code             => NULL,
                                           caseid           => v_caseid,
                                           casetypeid       => v_casetypeid,
                                           commoneventtype  => 'CREATE_CASE',
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
    
      /*--EXECUTE ALL EVENTS FOR NEW CASE WITH "NEW" STATE  */
      /*--AKA "PROCESS EVENTS AFTER ENTERING THE MILESTONE" */
/*      
      v_MilestoneActivity  :=NULL;
      v_MilestoneDiagramID :=NULL;
      v_IsValid            :=1; 
      BEGIN
        SELECT cs.COL_MILESTONEACTIVITY, s.COL_STATESTATECONFIG 
        INTO v_MilestoneActivity, v_MilestoneDiagramID
        FROM TBL_CASE cs
        LEFT JOIN TBL_DICT_STATE s ON s.col_ID =cs.COL_CASEDICT_STATE
        WHERE cs.COL_ID=v_caseid;
      EXCEPTION WHEN OTHERS THEN 
        --do nothing
        v_MilestoneActivity  :=NULL;
        v_MilestoneDiagramID :=NULL;
        v_IsValid            :=1;
      END;
      
      v_result := f_DCM_processMSStateEvents(ATTRIBUTES =>NULL,
                                             CASEID=> v_CaseId,
                                             ERRORCODE=>v_errorCode,
                                             ERRORMESSAGE =>v_errorMessage,
                                             EVTMOMENT=>'AFTER',
                                             EVTSTATE=>v_MilestoneActivity,
                                             EVTTYPE=>'ACTION',
                                             ISVALID=>v_IsValid,
                                             STATECONFIGID=>v_MilestoneDiagramID);
*/


      /*--ATTACH WORKITEM FROM DOCUMENT INDEXING*/
      IF NVL(v_piWorkitemId, 0) <> 0 THEN
        v_result := f_pi_attachworkitemtocasefn(caseid       => v_caseid,
                                                errorcode    => v_errorcode,
                                                errormessage => v_errormessage,
                                                workitemid   => v_piWorkitemId);
      
        IF NVL(v_errorcode, 0) > 0 THEN
          RETURN - 1;
        END IF;
      END IF;
    
    END IF;
    /*--v_validationresult = 1*/
IF F_dbg_isdebugon(casetypeid => v_casetypeid, procedureid => v_procedureid) > 0 THEN
DECLARE 
     v_owner_caller    VARCHAR2(255);
     v_name_caller     VARCHAR2(255);
     v_lineno_caller   NUMBER;
     v_caller_t VARCHAR2(255);
     who_called_mee VARCHAR2(4000);
BEGIN
     OWA_UTIL.who_called_me(owner => v_owner_caller,
                           name => v_name_caller,
                           lineno => v_lineno_caller,
                           caller_t => v_caller_t); 
     who_called_mee :=  v_owner_caller||'.'||v_name_caller||' line: '||v_lineno_caller||' - '|| v_caller_t;
    v_result := F_dbg_createdbgtrace(caseid   => v_caseid,
                                     location => $$PLSQL_LINE,
                                     MESSAGE  => 'Case ' || TO_CHAR(v_caseid) || ' created',
                                     rule     => $$PLSQL_UNIT,
                                     taskid   => NULL,
                                     who_called_me => who_called_mee,
                                     Params_Value => params(ADHOCNAME,ADHOCPROCCODE,ADHOCPROCID,ADHOCTASKTYPECODE,ADHOCTASKTYPEID,CASE_ID,CASEFROM,CASENAME,CASESYSTYPE_CODE,CASESYSTYPE_ID,CUSTOMDATA,DESCRIPTION,DOCUMENTSNAMES,DOCUMENTSURLS,DRAFT,ERRORCODE,ERRORMESSAGE,LINK_TYPE_ID,OWNER_WORKBASKET_ID,PARENT_CASE_ID,PIWORKITEMID,PREVENTDOCFOLDERCREATE,PRIORITY_ID,PROCEDURE_CODE,PROCEDURE_ID,RESOLVEBY,SUCCESSRESPONSE,SUMMARY,TARGETCASEID,TARGETTASKID,TASK_ID),
                                     Params_name => 'ADHOCNAME,ADHOCPROCCODE,ADHOCPROCID,ADHOCTASKTYPECODE,ADHOCTASKTYPEID,CASE_ID,CASEFROM,CASENAME,CASESYSTYPE_CODE,CASESYSTYPE_ID,CUSTOMDATA,DESCRIPTION,DOCUMENTSNAMES,DOCUMENTSURLS,DRAFT,ERRORCODE,ERRORMESSAGE,LINK_TYPE_ID,OWNER_WORKBASKET_ID,PARENT_CASE_ID,PIWORKITEMID,PREVENTDOCFOLDERCREATE,PRIORITY_ID,PROCEDURE_CODE,PROCEDURE_ID,RESOLVEBY,SUCCESSRESPONSE,SUMMARY,TARGETCASEID,TARGETTASKID,TASK_ID',
                                     called_stack => DBMS_UTILITY.FORMAT_CALL_STACK);
END;
END IF;
    /*--EO CREATE CASE SECTION*/
    
    /*--CREATE ADHOC PROC SECTION*/
  ELSIF NVL(v_caseid, 0) > 0 AND (v_adhocproccode IS NOT NULL OR v_adhocprocid IS NOT NULL) THEN
    IF F_dbg_isdebugon(casetypeid => v_casetypeid, procedureid => v_procedureid) > 0 THEN
      v_debugsession    := F_dbg_createdebugsession(caseid => v_caseid);
      v_successresponse := 'Debug session: ' || TO_CHAR(v_debugsession);
      successresponse   := v_successresponse;
    END IF;
  
    IF v_targettaskid IS NULL THEN
      BEGIN
        SELECT MIN(col_id)
          INTO v_sourceid
          FROM tbl_task
         WHERE col_casetask = v_caseid
           AND col_parentid = 0;
      
      EXCEPTION
        WHEN no_data_found THEN
          v_sourceid := NULL;
      END;
    ELSE
      v_sourceid := v_targettaskid;
    END IF;
    
    v_Attributes:='<AttachedProcCode>'||TO_CHAR(v_adhocproccode)||'</AttachedProcCode>'||                  
                  '<RootName>'||TO_CHAR(v_adhocname)||'</RootName>'||
                  '<SourceTaskId>'||TO_CHAR(v_sourceid)||'</SourceTaskId>'||
                  '<TaskId>'||TO_CHAR(v_taskid)||'</TaskId>'||
                  '<WorkbasketId>'||TO_CHAR(v_ownerworkbasketid)||'</WorkbasketId>';  
	v_Attributes := v_Attributes || v_FormData;					  
  
    /*--COPY RECORDS FROM DESIGNTIME BO INTO RUNTIME BO*/
    v_result := F_dcm_copycommonevents(caseid      => v_caseid,
                                       casetypeid  => NULL,
                                       code        => NULL,
                                       procedureid => v_adhocprocid,
                                       tasktypeid  => NULL,
                                       taskid      => NULL);
  
    /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_PROC- AND*/
    /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
    v_validationresult := 1;
  
    v_result := F_dcm_processcommonevent(InData           => v_InData,
                                         OutData          => v_outData,    
                                         Attributes       => v_Attributes,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => NULL,
                                         commoneventtype  => 'CREATE_ADHOC_PROC',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'BEFORE',
                                         eventtype        => 'VALIDATION',
                                         historymessage   => v_historymsg,
                                         procedureid      => v_adhocprocid,
                                         taskid           => NULL,
                                         tasktypeid       => NULL,
                                         validationresult => v_validationresult);
  
    /*--write to history*/
    IF v_historymsg IS NOT NULL THEN
      v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                         issystem       => 0,
                                         MESSAGE        => 'Validation Common event(s)',
                                         messagecode    => 'CommonEvent',
                                         targetid       => v_sourceid,
                                         targettype     => 'TASK');
    END IF;
  
    IF NVL(v_validationresult, 0) = 0 THEN
      :ErrorCode       := v_errorcode;
      :ErrorMessage    := v_errormessage;
      :SuccessResponse := :ErrorMessage;
    
      RETURN - 1;
    END IF;
  
    IF v_validationresult = 1 THEN
      /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_PROC- AND*/
      /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
      v_result := F_dcm_processcommonevent(InData           => v_InData,
                                           OutData          => v_outData,    
                                           Attributes       => v_Attributes,
                                           code             => NULL,
                                           caseid           => v_caseid,
                                           casetypeid       => NULL,
                                           commoneventtype  => 'CREATE_ADHOC_PROC',
                                           errorcode        => v_errorcode,
                                           errormessage     => v_errormessage,
                                           eventmoment      => 'BEFORE',
                                           eventtype        => 'ACTION',
                                           historymessage   => v_historymsg,
                                           procedureid      => v_adhocprocid,
                                           taskid           => NULL,
                                           tasktypeid       => NULL,
                                           validationresult => v_validationresult);
    
      /*--write to history*/
      IF v_historymsg IS NOT NULL THEN
        v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                           issystem       => 0,
                                           MESSAGE        => 'Action Common event(s)',
                                           messagecode    => 'CommonEvent',
                                           targetid       => v_sourceid,
                                           targettype     => 'TASK');
      END IF;    
    
      v_result := F_dcm_insertadhocprocposfn(attachedproccode       => v_adhocproccode,
                                             attachedprocedure      => v_adhocprocid,
                                             casefrom               => v_casefrom,
                                             caseid                 => v_caseid,
                                             deleteroot             => 0,
                                             description            => v_description,
                                             documentsnames         => documentsnames,
                                             documentsurls          => documentsurls,
                                             draft                  => v_draft,
                                             errorcode              => v_errorcode,
                                             errormessage           => v_errormessage,
                                             input                  => v_customdata,
                                             position               => NULL,
                                             rootname               => v_adhocname,
                                             sourceid               => v_sourceid,
                                             taskid                 => v_taskid,
                                             workbasketid           => v_ownerworkbasketid,
                                             preventdocfoldercreate => v_preventdocfoldercreate);
    
      :Task_Id      := v_taskid;
      :Case_Id      := v_caseid;
      :ErrorCode    := v_errorcode;
      :ErrorMessage := v_errormessage;
    
      IF NVL(v_errorcode, 0) NOT IN (0, 200) THEN
        RETURN - 1;
      END IF;
    
      /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_PROC-*/
      /*--AND EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
      v_result := F_dcm_processcommonevent(InData           => v_InData,
                                           OutData          => v_outData,    
                                           Attributes       => v_Attributes,
                                           code             => NULL,
                                           caseid           => v_caseid,
                                           casetypeid       => NULL,
                                           commoneventtype  => 'CREATE_ADHOC_PROC',
                                           errorcode        => v_errorcode,
                                           errormessage     => v_errormessage,
                                           eventmoment      => 'AFTER',
                                           eventtype        => 'ACTION',
                                           historymessage   => v_historymsg,
                                           procedureid      => v_adhocprocid,
                                           taskid           => NULL,
                                           tasktypeid       => NULL,
                                           validationresult => v_validationresult);
    
      /*--write to history*/
      IF v_historymsg IS NOT NULL THEN
        v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                           issystem       => 0,
                                           MESSAGE        => 'Action Common event(s)',
                                           messagecode    => 'CommonEvent',
                                           targetid       => v_sourceid,
                                           targettype     => 'TASK');
      END IF;
    END IF;
    /*--v_validationresult = 1*/
    v_result := F_dbg_createdbgtrace(caseid   => v_caseid,
                                     location => 'After f_DCM_insertAdhocProcPosFn',
                                     MESSAGE  => 'In case ' || TO_CHAR(v_caseid) || ' adhoc procedure created',
                                     rule     => 'DCM_createCaseWithOptions',
                                     taskid   => NULL);
    /*--EO CREATE ADHOC PROC SECTION*/
    
    /*--CREATE ADHOC TASK SECTION*/
  ELSIF NVL(v_caseid, 0) > 0 AND (v_adhoctasktypecode IS NOT NULL OR v_adhoctasktypeid IS NOT NULL) THEN
    IF F_dbg_isdebugon(casetypeid => v_casetypeid, procedureid => v_procedureid) > 0 THEN
      v_debugsession    := F_dbg_createdebugsession(caseid => v_caseid);
      v_successresponse := 'Debug session: ' || TO_CHAR(v_debugsession);
      successresponse   := v_successresponse;
    END IF;
  
    IF v_targettaskid IS NULL THEN
      BEGIN
        SELECT MIN(col_id)
          INTO v_sourceid
          FROM tbl_task
         WHERE col_casetask = v_caseid
           AND col_parentid = 0;
      
      EXCEPTION
        WHEN no_data_found THEN
          v_sourceid := NULL;
      END;
    ELSE
      v_sourceid := v_targettaskid;
    END IF;
    
    v_Attributes:='<TaskSysTypeCode>'||TO_CHAR(v_adhoctasktypecode)||'</TaskSysTypeCode>'||
                  '<RootName>'||TO_CHAR(v_adhocname)||'</RootName>'||
                  '<SourceTaskId>'||TO_CHAR(v_sourceid)||'</SourceTaskId>'||                  
                  '<TaskName>'||TO_CHAR(v_taskname)||'</TaskName>'||
                  '<WorkbasketId>'||TO_CHAR(v_ownerworkbasketid)||'</WorkbasketId>';     
	v_Attributes := v_Attributes || v_FormData;	
    /*--COPY RECORDS FROM DESIGNTIME BO INTO RUNTIME BO*/
    v_result := F_dcm_copycommonevents(caseid      => v_caseid,
                                       casetypeid  => NULL,
                                       code        => NULL,
                                       procedureid => NULL,
                                       tasktypeid  => v_adhoctasktypeid,
                                       taskid      => NULL);
  
    /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT 
    TYPE -CREATE_ADHOC_TASK- AND EVENT MOMENT -BEFORE- EXIST. 
    IF THEY EXIST PROCESS THEM--*/    
    v_validationresult := 1;
  
    v_result := F_dcm_processcommonevent(InData           => v_InData,
                                         OutData          => v_outData,    
                                         Attributes       => v_Attributes,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => NULL,
                                         commoneventtype  => 'CREATE_ADHOC_TASK',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'BEFORE',
                                         eventtype        => 'VALIDATION',
                                         historymessage   => v_historymsg,
                                         procedureid      => NULL,
                                         taskid           => NULL,
                                         tasktypeid       => v_adhoctasktypeid,
                                         validationresult => v_validationresult);
  
    /*--write to history*/
    IF v_historymsg IS NOT NULL THEN
      v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                         issystem       => 0,
                                         MESSAGE        => 'Validation Common event(s)',
                                         messagecode    => 'CommonEvent',
                                         targetid       => v_sourceid,
                                         targettype     => 'TASK');
    END IF;
  
    IF NVL(v_validationresult, 0) = 0 THEN
      :ErrorCode       := v_errorcode;
      :ErrorMessage    := v_errormessage;
      :SuccessResponse := :ErrorMessage;
    
      /*--UPDATE RECORDS INSIDE RUNTIME BO (link to created task)*/
      UPDATE tbl_commonevent
         SET col_commoneventtask = 0
       WHERE col_commoneventcase = v_caseid
         AND col_commoneventtasktype = v_adhoctasktypeid
         AND col_commoneventtask IS NULL;
    
      RETURN - 1;
    END IF;
  
    IF v_validationresult = 1 THEN
    
      /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_TASK- 
          AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM
       --*/
      v_validationresult := 1;
    
      v_result := F_dcm_processcommonevent(InData           => v_InData,
                                           OutData          => v_outData,    
                                           Attributes       => v_Attributes,
                                           code             => NULL,
                                           caseid           => v_caseid,
                                           casetypeid       => NULL,
                                           commoneventtype  => 'CREATE_ADHOC_TASK',
                                           errorcode        => v_errorcode,
                                           errormessage     => v_errormessage,
                                           eventmoment      => 'BEFORE',
                                           eventtype        => 'ACTION',
                                           historymessage   => v_historymsg,
                                           procedureid      => NULL,
                                           taskid           => NULL,
                                           tasktypeid       => v_adhoctasktypeid,
                                           validationresult => v_validationresult);
    
      /*--write to history*/
      IF v_historymsg IS NOT NULL THEN
        v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                           issystem       => 0,
                                           MESSAGE        => 'Action Common event(s)',
                                           messagecode    => 'CommonEvent',
                                           targetid       => v_sourceid,
                                           targettype     => 'TASK');
      END IF;
      
      v_result := F_dcm_createadhoctaskposfn(caseid        => v_caseid,
                                             description   => v_description,
                                             errorcode     => v_errorcode,
                                             errormessage  => v_errormessage,
                                             icon          => NULL,
                                             input         => v_customdata,
                                             NAME          => v_adhocname,
                                             position      => NULL,
                                             sourceid      => v_sourceid,
                                             taskextid     => v_taskextid,
                                             taskid        => v_taskid,
                                             taskname      => v_taskname,
                                             tasksystype   => v_adhoctasktypecode,
                                             tasksystypeid => v_adhoctasktypeid,
                                             workbasketid  => v_ownerworkbasketid);
    
      :ErrorCode    := v_errorcode;
      :ErrorMessage := v_errormessage;
      :Task_Id      := v_taskid;
      :Case_Id      := v_caseid;
    
      /*--UPDATE RECORDS INSIDE RUNTIME BO (link to created task)*/
      UPDATE tbl_commonevent
         SET col_commoneventtask = v_taskid
       WHERE col_commoneventcase = v_caseid
         AND col_commoneventtasktype = v_adhoctasktypeid
         AND col_commoneventtask IS NULL;
    
      IF NVL(v_errorcode, 0) NOT IN (0, 200) THEN
        RETURN - 1;
      END IF;
    
      /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_TASK- AND*/
      /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
      v_result := F_dcm_processcommonevent(InData           => v_InData,
                                           OutData          => v_outData,    
                                           Attributes       => v_Attributes,
                                           code             => NULL,
                                           caseid           => v_caseid,
                                           casetypeid       => NULL,
                                           commoneventtype  => 'CREATE_ADHOC_TASK',
                                           errorcode        => v_errorcode,
                                           errormessage     => v_errormessage,
                                           eventmoment      => 'AFTER',
                                           eventtype        => 'ACTION',
                                           historymessage   => v_historymsg,
                                           procedureid      => NULL,
                                           taskid           => v_taskid,
                                           tasktypeid       => v_adhoctasktypeid,
                                           validationresult => v_validationresult);
     
      /*--write to history*/
      IF v_historymsg IS NOT NULL THEN
        v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                           issystem       => 0,
                                           MESSAGE        => 'Action Common event(s)',
                                           messagecode    => 'CommonEvent',
                                           targetid       => v_sourceid,
                                           targettype     => 'TASK');
      END IF;
    END IF;
    /*--v_validationresult = 1*/
    v_result := F_dbg_createdbgtrace(caseid   => v_caseid,
                                     location => 'After f_DCM_createAdhocTaskPosFn',
                                     MESSAGE  => 'In case ' || TO_CHAR(v_caseid) || ' adhoc task created',
                                     rule     => 'DCM_createCaseWithOptions',
                                     taskid   => NULL);
  END IF;
  /*--create adhoc task section*/
  
  /*--create adhoc proc section (VV I dont know why)*/
  IF v_validationresult = 101 AND (v_adhocproccode IS NOT NULL OR v_adhocprocid IS NOT NULL) THEN
    IF v_targettaskid IS NULL THEN
      IF F_dbg_isdebugon(casetypeid => v_casetypeid, procedureid => v_procedureid) > 0 THEN
        v_debugsession    := F_dbg_createdebugsession(caseid => v_caseid);
        v_successresponse := 'Debug session: ' || TO_CHAR(v_debugsession);
        successresponse   := v_successresponse;
      END IF;
    
      BEGIN
        SELECT MIN(col_id)
          INTO v_sourceid
          FROM tbl_task
         WHERE col_casetask = v_caseid
           AND col_parentid = 0;
      
      EXCEPTION
        WHEN no_data_found THEN
          v_sourceid := NULL;
      END;
    ELSE
      v_sourceid := v_targettaskid;
    END IF;
  
    /*--COPY RECORDS FROM DESIGNTIME BO INTO RUNTIME BO*/
    v_result := F_dcm_copycommonevents(caseid      => v_caseid,
                                       casetypeid  => NULL,
                                       code        => NULL,
                                       procedureid => v_adhocprocid,
                                       tasktypeid  => NULL,
                                       taskid      => NULL);
  
    /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_PROC- AND*/
    /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
    v_validationresult := 1;
  
    v_result := F_dcm_processcommonevent(InData           => v_InData,
                                         OutData          => v_outData,    
                                         Attributes       => NULL,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => NULL,
                                         commoneventtype  => 'CREATE_ADHOC_PROC',
                                         errorcode        => v_errorcode,
                                         errormessage     => v_errormessage,
                                         eventmoment      => 'BEFORE',
                                         eventtype        => 'VALIDATION',
                                         historymessage   => v_historymsg,
                                         procedureid      => v_adhocprocid,
                                         taskid           => NULL,
                                         tasktypeid       => NULL,
                                         validationresult => v_validationresult);
  
    /*--write to history*/
    IF v_historymsg IS NOT NULL THEN
      v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                         issystem       => 0,
                                         MESSAGE        => 'Validation Common event(s)',
                                         messagecode    => 'CommonEvent',
                                         targetid       => v_sourceid,
                                         targettype     => 'TASK');
    END IF;
  
    IF NVL(v_validationresult, 0) = 0 THEN
      :ErrorCode       := v_errorcode;
      :ErrorMessage    := v_errormessage;
      :SuccessResponse := :ErrorMessage;
    
      RETURN - 1;
    END IF;
  
    IF v_validationresult = 1 THEN
      v_result := F_dcm_insertadhocprocposfn(attachedproccode       => v_adhocproccode,
                                             attachedprocedure      => v_adhocprocid,
                                             casefrom               => v_casefrom,
                                             caseid                 => v_caseid,
                                             deleteroot             => 0,
                                             description            => v_description,
                                             documentsnames         => documentsnames,
                                             documentsurls          => documentsurls,
                                             draft                  => v_draft,
                                             errorcode              => v_errorcode,
                                             errormessage           => v_errormessage,
                                             input                  => v_customdata,
                                             position               => NULL,
                                             rootname               => v_adhocname,
                                             sourceid               => v_sourceid,
                                             taskid                 => v_taskid,
                                             workbasketid           => NULL,
                                             preventdocfoldercreate => 1);
    
      :ErrorCode    := v_errorcode;
      :ErrorMessage := v_errormessage;
      :Task_Id      := v_taskid;
      :Case_Id      := v_caseid;
    
      IF NVL(v_errorcode, 0) NOT IN (0, 200) THEN
        RETURN - 1;
      END IF;
    
      /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_PROC- AND*/
      /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
      v_result := F_dcm_processcommonevent(InData           => v_InData,
                                           OutData          => v_outData,    
                                           Attributes       => NULL,
                                           code             => NULL,
                                           caseid           => v_caseid,
                                           casetypeid       => NULL,
                                           commoneventtype  => 'CREATE_ADHOC_PROC',
                                           errorcode        => v_errorcode,
                                           errormessage     => v_errormessage,
                                           eventmoment      => 'AFTER',
                                           eventtype        => 'ACTION',
                                           historymessage   => v_historymsg,
                                           procedureid      => v_adhocprocid,
                                           taskid           => NULL,
                                           tasktypeid       => NULL,
                                           validationresult => v_validationresult);
    
      /*--write to history*/
      IF v_historymsg IS NOT NULL THEN
        v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                           issystem       => 0,
                                           MESSAGE        => 'Action Common event(s)',
                                           messagecode    => 'CommonEvent',
                                           targetid       => v_sourceid,
                                           targettype     => 'TASK');
      END IF;
    END IF;
    /*--v_validationresult = 1*/
    v_result := F_dbg_createdbgtrace(caseid   => v_caseid,
                                     location => 'After f_DCM_insertAdhocProcPosFn',
                                     MESSAGE  => 'In case ' || TO_CHAR(v_caseid) || ' adhoc procedure created',
                                     rule     => 'DCM_createCaseWithOptions',
                                     taskid   => NULL);
  END IF;
  /*--eo create adhoc proc section*/
  IF NVL(v_errorcode, 0) NOT IN (0, 200) THEN
    RETURN - 1;
  END IF;

  v_result := F_dbg_createdbgtrace(caseid   => v_caseid,
                                   location => 'End of DCM_createCaseWithOptions',
                                   MESSAGE  => 'Case ' || TO_CHAR(v_caseid) || ' creation finished',
                                   rule     => 'DCM_createCaseWithOptions',
                                   taskid   => NULL);
END;