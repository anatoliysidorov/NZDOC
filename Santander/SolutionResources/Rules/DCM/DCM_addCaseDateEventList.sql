declare
  v_CaseId Integer;
  v_state nvarchar2(255);
  v_result number;
begin
  v_CaseId := :CaseId;
  v_state := :state;
  for rec in
  (select cs.col_id as CaseStateId, cs.col_code as CaseStateCode, cs.col_name as CaseStateName, cs.col_activity as CaseStateActivity,
          det.col_id as DateEventTypeId, det.col_code as DateEventTypeCode, det.col_name as DateEventTypeName
   from tbl_dict_casestate cs
   inner join tbl_dict_csest_dtevtp csdet on cs.col_id = csdet.col_csest_dtevtpcasestate
   inner join tbl_dict_dateeventtype det on csdet.col_csest_dtevtpdateeventtype = det.col_id
   where cs.col_activity = v_state)
   loop
     v_result := f_DCM_createCaseDateEvent (Name => rec.DateEventTypeCode, CaseId => v_CaseId);
   end loop;
end;