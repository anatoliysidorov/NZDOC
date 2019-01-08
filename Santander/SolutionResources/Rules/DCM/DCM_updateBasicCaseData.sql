DECLARE
  v_caseid              INTEGER;
  v_casetypeid          INTEGER;
  v_summary             NVARCHAR2(255);
  v_description         NCLOB;
  v_result              INTEGER;
  v_customdataprocessor NVARCHAR2(255);
  v_customdata          NCLOB;
  v_standarddata        NCLOB;
  v_prevcustomdata      NCLOB;
  v_submittedcustomdata NCLOB;
  v_recordidext         INTEGER;
  v_customdataxml       XMLTYPE;
  v_priority_id         INTEGER;
  v_draft               INTEGER;
  v_justcustomdata      INTEGER;
  v_validationresult    NUMBER;
  v_errorcode           NUMBER;
  v_errormessage        NCLOB;
  v_historyMsg          NCLOB;
  v_Attributes          NCLOB;
  v_outData CLOB;

BEGIN
  v_historyMsg := NULL;

  --COMMON ATTRIBUTES 
  v_caseid              := :ID;
  v_summary             := :SUMMARY;
  v_description         := :DESCRIPTION;
  v_submittedcustomdata := :CUSTOMDATA;
  v_priority_id         := :PRIORITY_ID;
  v_draft               := :DRAFT;
  v_justcustomdata      := Nvl(:JustCustomData, 0);

  v_errorcode    := 0;
  v_errormessage := '';
  v_outData      := NULL;

  IF v_submittedcustomdata IS NULL THEN
    v_submittedcustomdata := '<CustomData><Attributes></Attributes></CustomData>';
  END IF;

  v_prevcustomdata := F_dcm_getcasecustomdata(caseid => v_caseid);
  v_customdata     := F_form_mergecustomdata(input => v_prevcustomdata, input2 => v_submittedcustomdata);

  IF v_justcustomdata = 0 THEN
    v_standarddata := '<SUMMARY><![CDATA[' || v_summary || ']]></SUMMARY>';
    v_standarddata := v_standarddata || '<DESCRIPTION><![CDATA[' || v_description || ']]></DESCRIPTION>';
    v_standarddata := v_standarddata || '<PRIORITY_ID>' || TO_CHAR(v_priority_id) || '</PRIORITY_ID>';
    v_standarddata := v_standarddata || '<DRAFT>' || TO_CHAR(v_draft) || '</DRAFT>';
  END IF;

  --FIND CASE TYPE AND GET ANY CUSTOM PROCESSORS 
  BEGIN
    SELECT col_casedict_casesystype INTO v_casetypeid FROM tbl_case WHERE col_id = v_caseid;
  EXCEPTION
    WHEN no_data_found THEN
      v_casetypeid := NULL;
  END;

  v_Attributes := '<JustCustomData>' || TO_CHAR(v_justcustomdata) || '</JustCustomData>' || '<PreviousData>' ||
                  f_UTIL_extractXmlAsTextFn(INPUT => utl_i18n.unescape_reference(v_PrevCustomData), PATH => '/CustomData/Attributes/*') || '</PreviousData>' || '<NewData>' ||
                  f_UTIL_extractXmlAsTextFn(INPUT => v_customdata, PATH => '/CustomData/Attributes/*') || '<Object ObjectCode="CASE"><Item>' || v_standarddata || '</Item></Object>' || '</NewData>';

  v_validationresult := 1;

  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -UPDATE_CASE_DATA- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM-- 
  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => v_casetypeid,
                                       commoneventtype  => 'UPDATE_CASE_DATA',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'VALIDATION',
                                       HistoryMessage   => v_historyMsg,
                                       procedureid      => NULL,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);

  --write to history  
  IF v_historyMsg IS NOT NULL THEN
    v_result := f_HIST_createHistoryFn(AdditionalInfo => v_historyMsg, IsSystem => 0, Message => 'Validation Common event(s)', MessageCode => 'CommonEvent', TargetID => v_caseid, TargetType => 'CASE');
  END IF;

  IF Nvl(v_validationresult, 0) = 0 THEN
    :SuccessResponse := '';
    :errorCode       := v_errorcode;
    :errorMessage    := v_errormessage;
    RETURN;
  END IF;

  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_CASE_DATA- AND 
  --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM-- 
  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => v_casetypeid,
                                       commoneventtype  => 'UPDATE_CASE_DATA',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'ACTION',
                                       HistoryMessage   => v_historyMsg,
                                       procedureid      => NULL,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);

  --write to history  
  IF v_historyMsg IS NOT NULL THEN
    v_result := f_HIST_createHistoryFn(AdditionalInfo => v_historyMsg, IsSystem => 0, Message => 'Action Common event(s)', MessageCode => 'CommonEvent', TargetID => v_caseid, TargetType => 'CASE');
  END IF;

  BEGIN
    SELECT col_updatecustdataprocessor INTO v_customdataprocessor FROM tbl_dict_casesystype WHERE col_id = v_casetypeid;
  EXCEPTION
    WHEN no_data_found THEN
      v_customdataprocessor := NULL;
  END;

  --EXECUTE CUSTOM PROCESSORS IF NEEDED 
  --add basic information into CustomData/Attributes for legacy reasons
  v_customdata := f_UTIL_extractXmlAsTextFn(INPUT => v_customdata, PATH => '/CustomData/Attributes/*') || v_standarddata;
  v_customdata := v_customdata || '<Object ObjectCode="CASE"><Item>' || v_standarddata || '</Item></Object>';
  v_customdata := '<CustomData><Attributes>' || v_customdata || '</Attributes></CustomData>';
  IF v_customdataprocessor IS NOT NULL THEN
    v_recordidext := F_dcm_invokecasecusdataproc3(caseid => v_caseid, input => v_customdata, processorname => v_customdataprocessor);
    -- v_RecordIdExt := f_dcm_invokeCaseCusDataProc(CaseId => v_CaseId, Input => v_CustomData, ProcessorName => v_customdataprocessor);
  
    v_customdataxml := Xmltype(v_customdata);
    --set custom data even if it's been processed by the custom processor 
  ELSE
    v_recordidext   := NULL;
    v_customdataxml := Xmltype(v_customdata);
  END IF;

  --SET XML TO CASE(CASEEXT) FOR CACHE PURPOSES, EVEN IF A CUSTOM PROCESSOR USED IT 
  UPDATE tbl_caseext SET col_customdata = v_customdataxml, col_description = v_description WHERE col_caseextcase = v_caseid;

  --UPDATE OTHER CASE DATA IF NEEDED 
  IF v_justcustomdata = 0 THEN
    UPDATE tbl_case SET col_summary = v_summary, col_stp_prioritycase = v_priority_id, col_draft = v_draft WHERE col_id = v_caseid;
  END IF;

  --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -UPDATE_CASE_DATA- AND 
  --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--  
  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => v_casetypeid,
                                       commoneventtype  => 'UPDATE_CASE_DATA',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'AFTER',
                                       eventtype        => 'ACTION',
                                       HistoryMessage   => v_historyMsg,
                                       procedureid      => NULL,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);

  --write to history  
  IF v_historyMsg IS NOT NULL THEN
    v_result := f_HIST_createHistoryFn(AdditionalInfo => v_historyMsg, IsSystem => 0, Message => 'Action Common event(s)', MessageCode => 'CommonEvent', TargetID => v_caseid, TargetType => 'CASE');
  END IF;

  :SuccessResponse := 'Update was successfull';
  :errorCode       := v_errorcode;
  :errorMessage    := v_errormessage;

  v_result := f_DCM_createCaseHistoryFn(AdditionalInfo => '', CaseId => v_CaseId, IsSystem => 0, Message => 'Update Basic Case Data was successful', MessageCode => 'CaseModified', MessageTypeId => null);
END;
