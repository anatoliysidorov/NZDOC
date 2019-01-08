DECLARE 
    v_mywb            INTEGER; 
    v_errorcode       NUMBER; 
    v_errormessage    NCLOB; 
    v_numberofrecords NUMBER; 
    v_workbasketid    INTEGER; 
    v_result          NUMBER; 
    
    v_validationresult    NUMBER; 
    v_CaseId              NUMBER;
    v_historyMsg          NCLOB;
    v_outData CLOB;
    v_Attributes       NVARCHAR2(4000);
    
BEGIN 
    v_workbasketid := :WorkbasketId; 
    v_mywb := F_dcm_getmypersonalworkbasket(); 
    v_numberofrecords := :NumberOfRecords; 
    v_outData      := NULL;
    
    IF (NVL(v_workbasketid, 0) = 0) THEN 
        v_errorcode := 106; 
        v_errormessage := 'Workbasket not found'; 
        :ErrorCode := v_errorcode; 
        :ErrorMessage := v_errormessage; 
        RETURN; 
    END IF; 

    IF (NVL(v_mywb, 0) = 0) THEN 
      v_errorcode := 106; 
      v_errormessage := 'There is no case worker or the case worker does not have a work basket'; 
      :ErrorCode := v_errorcode; 
      :ErrorMessage := v_errormessage; 
      RETURN; 
    END IF;
    
     v_Attributes:='<WorkbasketId>'||TO_CHAR(v_workbasketid)||'</WorkbasketId>'||                                     
                   '<PersonalWorkbasketId>'||TO_CHAR(v_mywb)||'</PersonalWorkbasketId>'||
                   '<NumberOfRecords>'||TO_CHAR(v_numberofrecords)||'</NumberOfRecords>';    
    
    
    FOR rec IN
    ( SELECT col_id AS caseid, col_casedict_casesystype AS casetypeid
      FROM tbl_case
      WHERE  col_caseppl_workbasket = v_workbasketid 
      AND ROWNUM <= v_numberofrecords       
    )
    LOOP
    
      v_validationresult := 1;
    
      --CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -PULL_CASE_FROM_GROUP_WORKBASKET- AND 
      --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM-- 
      v_result := f_DCM_processCommonEvent(
                  InData           => NULL,
                  OutData          => v_outData,        
                  Attributes =>v_Attributes,
                  code => NULL, 
                  caseid => rec.caseid, 
                  casetypeid => rec.casetypeid, 
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
          TargetID => rec.caseid, 
          TargetType=>'CASE'
         );
      END IF;                

      IF Nvl(v_validationresult, 0) = 0 THEN 
        :ErrorCode := v_errorcode; 
        :ErrorMessage := v_errormessage;       
        EXIT; 
      END IF;  
      
      --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -PULL_CASE_FROM_GROUP_WORKBASKET- AND 
      --EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM-- 
      v_result := f_DCM_processCommonEvent(
                  InData           => NULL,
                  OutData          => v_outData,        
                  Attributes =>v_Attributes,
                  code => NULL, 
                  caseid => rec.caseid, 
                  casetypeid => rec.casetypeid, 
                  commoneventtype => 'PULL_CASE_FROM_GROUP_WORKBASKET', 
                  errorcode => v_errorcode, 
                  errormessage => v_errormessage, 
                  eventmoment => 'BEFORE', 
                  eventtype => 'ACTION', 
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
          Message=> 'Action Common event(s)',
          MessageCode => 'CommonEvent', 
          TargetID => rec.caseid, 
          TargetType=>'CASE'
         );
      END IF;       
      
     
      UPDATE tbl_case 
      SET    col_caseppl_workbasket = v_mywb 
      WHERE  col_id=rec.caseid;

      --CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -PULL_CASE_FROM_GROUP_WORKBASKET- AND 
      --EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--	
      v_result := f_DCM_processCommonEvent(
                  InData           => NULL,
                  OutData          => v_outData,              
                  Attributes =>NULL,
                  code => NULL, 
                  caseid => rec.caseid, 
                  casetypeid => rec.casetypeid, 
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
          TargetID => rec.caseid, 
          TargetType=>'CASE'
         );
      END IF;      
    
    END LOOP;
END; 