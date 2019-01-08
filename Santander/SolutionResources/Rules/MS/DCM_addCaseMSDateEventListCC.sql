declare
  v_CaseId          NUMBER;
  v_stateConfigId   NUMBER;
  v_state           NVARCHAR2(255);
  v_result          NUMBER;
begin
  v_CaseId        := :CaseId;
  v_stateConfigId := :StateConfigId;
  
  for rec in
  (select cs.col_id as CaseStateId, cs.col_code as CaseStateCode, cs.col_name as CaseStateName, cs.col_activity as CaseStateActivity,
       det.col_id as DateEventTypeId, det.col_code as DateEventTypeCode, det.col_name as DateEventTypeName,
       st.col_id AS StateId
   from tbl_dict_casestate cs
   LEFT JOIN TBL_DICT_STATE st ON st.col_statecasestate=cs.col_id AND st.col_statestateconfig=v_stateConfigId
   inner join tbl_dict_csest_dtevtp csdet on cs.col_id = csdet.col_csest_dtevtpcasestate
   inner join tbl_dict_dateeventtype det on csdet.col_csest_dtevtpdateeventtype = det.col_id
   inner join tbl_cw_workitemcc cwi on cs.col_id = cwi.col_cw_workitemccdict_casest
   inner join tbl_casecc cse on cwi.col_id = cse.col_cw_workitemcccasecc
   where cse.col_id = v_CaseId)
   loop
     v_result := f_DCM_createCaseMSDateEventCC (NAME => rec.DateEventTypeCode, 
                                                CASEID => v_CaseId, 
                                                STATEID => rec.StateId);
   end loop;
end;