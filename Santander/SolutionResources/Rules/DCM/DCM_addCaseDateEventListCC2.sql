declare
  v_CaseId Integer;
  v_state nvarchar2(255);
  v_result number;
begin
  v_CaseId := :CaseId;
  for rec in
  (select cs.col_id as CaseStateId, cs.col_code as CaseStateCode, cs.col_name as CaseStateName, cs.col_activity as CaseStateActivity,
       det.col_id as DateEventTypeId, det.col_code as DateEventTypeCode, det.col_name as DateEventTypeName
   from tbl_dict_casestate cs
   inner join tbl_dict_csest_dtevtp csdet on cs.col_id = csdet.col_csest_dtevtpcasestate
   inner join tbl_dict_dateeventtype det on csdet.col_csest_dtevtpdateeventtype = det.col_id
   inner join tbl_cw_workitemcc cwi on cs.col_id = cwi.col_cw_workitemccdict_casest
   inner join tbl_casecc cse on cwi.col_id = cse.col_cw_workitemcccasecc
   where cse.col_id = v_CaseId)
   loop     
      v_result := f_DCM_createCaseDateEventCC (Name => rec.DateEventTypeCode, CaseId => v_CaseId);
   end loop;
end;