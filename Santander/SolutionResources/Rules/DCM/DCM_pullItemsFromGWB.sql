declare
  v_CaseworkerId Integer;
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(155);
  v_NumberOfRecords number;
  v_NumberOfCases number;
  v_NumberOfTasks number;
  v_Workbasketid Integer;
  v_result number;
begin
  v_WorkbasketId := :WorkbasketId;
  v_CaseworkerId := NVL(:CaseworkerId, f_UTIL_getCWfromAcode(sys_context('CLIENTCONTEXT', 'AccessSubject')));
  v_NumberOfRecords := :NumberOfRecords;
  v_result := f_dcm_invokesplitpullitemsproc(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, NumberOfCases => v_NumberOfCases, NumberOfRecords => v_NumberOfRecords, NumberOfTasks => v_NumberOfTasks, WorkbasketId => v_WorkbasketId);
  v_result := f_dcm_pullcasesfromgwbfn(CaseworkerId => v_CaseworkerId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, NumberOfRecords => v_NumberOfCases, WorkbasketId => v_WorkbasketId);
  v_result := f_dcm_pulltasksfromgwbfn(CaseworkerId => v_CaseworkerId, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, NumberOfRecords => v_NumberOfTasks, WorkbasketId => v_WorkbasketId);
end;