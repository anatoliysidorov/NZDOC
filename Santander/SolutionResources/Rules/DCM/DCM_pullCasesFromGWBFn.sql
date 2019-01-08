declare
  v_WorkbasketId Integer;
  v_PrivateWorkbasketId Integer;
  v_result number;
  v_query varchar2(2000);
  v_cur sys_refcursor;
  v_Id Integer;
  v_CaseworkerId Integer;
  v_NumberOfRecords Integer;
  v_Rating Integer;
  v_CaseActivity nvarchar2(255);
  v_RowNumber Integer;
  v_CaseId Integer;
  v_CaseName nvarchar2(255);
  v_WIId Integer;
  v_ProcessorCode nvarchar2(255);
  v_ErrorCode number;
  v_ErrorMessage nclob;
  v_validationresult    NUMBER;
  v_historyMsg          nclob;
  v_CaseTypeId          INTEGER;
  v_outData CLOB;
  
begin
  v_WorkbasketId := :WorkbasketId;
  v_CaseworkerId := :CaseworkerId;
  v_NumberOfRecords := :NumberOfRecords;
  v_outData      := NULL;
  
  begin
    select wb.col_processorcode2 into v_ProcessorCode from tbl_ppl_workbasket wb
     inner join tbl_dict_workbaskettype wbt on wb.col_workbasketworkbaskettype = wbt.col_id
     where wb.col_id = v_WorkbasketId and wbt.col_code = 'GROUP';
    exception
      when NO_DATA_FOUND then
        v_ProcessorCode := null;
        v_ErrorCode := 101;
        v_ErrorMessage := 'No group workbasket found';
        :ErrorCode := v_ErrorCode;
        :ErrorMessage := v_ErrorMessage;
        return -1;
  end;
  
  if (v_ProcessorCode is null) or (v_ProcessorCode = '') then
    v_ErrorCode := 102;
    v_ErrorMessage := 'No processor for case extraction from group workbasket exists';
    :ErrorCode := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
    return -1;
  end if;
  
  begin
    select wb.col_id into v_PrivateWorkbasketId from tbl_ppl_workbasket wb
    inner join tbl_dict_workbaskettype wbt on wb.col_workbasketworkbaskettype = wbt.col_id
    where wb.col_caseworkerworkbasket = v_CaseworkerId and wb.col_isdefault = 1 and wbt.col_code = 'PERSONAL';
    exception
      when NO_DATA_FOUND then
        v_ErrorCode := 103;
        v_ErrorMessage := 'Default personal workbasket not found';
        :ErrorCode := v_ErrorCode;
        :ErrorMessage := v_ErrorMessage;
        return -1;
      when TOO_MANY_ROWS then
        v_ErrorCode := 104;
        v_ErrorMessage := 'More than one default personal workbasket found';
        :ErrorCode := v_ErrorCode;
        :ErrorMessage := v_ErrorMessage;
        return -1;
  end;
  
  v_query := 'select Id, CaseworkerId, CaseActivity, RowNumber, CaseId, CaseName, WIId, Rating from table(' ||
             v_ProcessorCode || '(Caseworkerid=>' || v_CaseworkerId || ',WorkbasketId=>' || v_WorkbasketId || ',NumberOfRecords=>' || v_NumberOfRecords || '))';
  open v_cur for v_query;
  loop
    fetch v_cur into v_Id, v_CaseworkerId, v_CaseActivity, v_RowNumber, v_CaseId, v_CaseName, v_WIId, v_Rating;
    exit when v_cur%notfound;
    
    --FIND CASE TYPE 
    BEGIN
      SELECT COL_CASEDICT_CASESYSTYPE
      INTO v_CaseTypeId
      FROM tbl_case
      WHERE col_id = v_CaseId;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_CaseTypeId := NULL;
    END;    
    
    v_validationresult := 1; 
    v_historyMsg :=NULL;
    
    --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE 
    --PULL_CASE_FROM_GROUP_WORKBASKET- AND 
    --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--   
    v_result := f_DCM_processCommonEvent(
                InData           => NULL,
                OutData          => v_outData,    
                Attributes =>NULL,
                code => NULL, 
                caseid => v_caseid, 
                casetypeid => v_casetypeid, 
                commoneventtype => 'PULL_CASE_FROM_GROUP_WORKBASKET', 
                errorcode => v_errorcode, 
                errormessage => v_errormessage, 
                eventmoment => 'BEFORE', 
                eventtype => 'VALIDATION', 
                HistoryMessage =>v_historyMsg,
                procedureid => NULL, 
                taskid => NULL, 
                tasktypeid => NULL, 
                validationresult => v_validationresult); 
                
    --write to history  
    IF v_historyMsg IS NOT NULL THEN
       v_result := f_HIST_createHistoryFn(
        AdditionalInfo => v_historyMsg,  
        IsSystem=>0, 
        Message=> 'Validation Common event(s)',
        MessageCode => 'CommonEvent', 
        TargetID => v_caseid, 
        TargetType=>'CASE'
       );
    END IF;  
    
    IF Nvl(v_validationresult, 0) = 0 THEN 
      :ErrorCode := v_errorcode; 
      :ErrorMessage := v_errormessage; 
      exit; 
    END IF; 
     
    IF v_validationresult = 1 THEN        
      update tbl_case set col_caseppl_workbasket = v_PrivateWorkbasketId where col_id = v_CaseId;
            
      --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE 
      --PULL_CASE_FROM_GROUP_WORKBASKET- AND 
      --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--  
      v_result := f_DCM_processCommonEvent(
                  InData           => NULL,
                  OutData          => v_outData,          
                  Attributes =>NULL,
                  code => NULL, 
                  caseid => v_caseid, 
                  casetypeid => v_casetypeid, 
                  commoneventtype => 'PULL_CASE_FROM_GROUP_WORKBASKET', 
                  errorcode => v_errorcode, 
                  errormessage => v_errormessage, 
                  eventmoment => 'AFTER', 
                  eventtype => 'ACTION',
                  HistoryMessage =>v_historyMsg,                
                  procedureid => NULL, 
                  taskid => NULL, 
                  tasktypeid => NULL, 
                  validationresult => v_validationresult
                  ); 
                  
      --write to history  
      IF v_historyMsg IS NOT NULL THEN
         v_result := f_HIST_createHistoryFn(
          AdditionalInfo => v_historyMsg,  
          IsSystem=>0, 
          Message=> 'Action Common event(s)',
          MessageCode => 'CommonEvent', 
          TargetID => v_caseid, 
          TargetType=>'CASE'
         );
      END IF;          
    END IF;
  end loop;
  
  close v_cur;
end;