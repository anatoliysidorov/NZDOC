declare
  v_CaseId          NUMBER;
  v_stateConfigId   NUMBER;
  v_state           NVARCHAR2(255);
  v_result          NUMBER;
begin
  v_CaseId        := :CaseId;
  v_stateConfigId := :StateConfigId;
  IF f_DCM_CSisCaseInCache(v_CaseId)=0 THEN 
    for rec in
    (select cs.col_id as CaseStateId, cs.col_code as CaseStateCode, cs.col_name as CaseStateName, cs.col_activity as CaseStateActivity,
         det.col_id as DateEventTypeId, det.col_code as DateEventTypeCode, det.col_name as DateEventTypeName,
         st.col_id AS StateId
     from tbl_dict_casestate cs
     LEFT JOIN TBL_DICT_STATE st ON st.col_statecasestate=cs.col_id AND st.col_statestateconfig=v_stateConfigId
     inner join tbl_dict_csest_dtevtp csdet on cs.col_id = csdet.col_csest_dtevtpcasestate
     inner join tbl_dict_dateeventtype det on csdet.col_csest_dtevtpdateeventtype = det.col_id
     inner join tbl_cw_workitem cwi on cs.col_id = cwi.col_cw_workitemdict_casestate
     inner join tbl_case cse on cwi.col_id = cse.col_cw_workitemcase
     where cse.col_id = v_CaseId)
     loop
       v_result := f_DCM_createCaseMSDateEvent (NAME => rec.DateEventTypeCode, 
                                                CASEID => v_CaseId, 
                                                STATEID => rec.StateId);
     end loop;
   END IF;--not in cache

  IF f_DCM_CSisCaseInCache(v_CaseId)=1 THEN 
    for rec in
    (select cs.col_id as CaseStateId, cs.col_code as CaseStateCode, cs.col_name as CaseStateName, cs.col_activity as CaseStateActivity,
         det.col_id as DateEventTypeId, det.col_code as DateEventTypeCode, det.col_name as DateEventTypeName,
         st.col_id AS StateId
     from tbl_dict_casestate cs
     LEFT JOIN TBL_DICT_STATE st ON st.col_statecasestate=cs.col_id AND st.col_statestateconfig=v_stateConfigId
     inner join tbl_dict_csest_dtevtp csdet on cs.col_id = csdet.col_csest_dtevtpcasestate
     inner join tbl_dict_dateeventtype det on csdet.col_csest_dtevtpdateeventtype = det.col_id
     inner join tbl_cscw_workitem cwi on cs.col_id = cwi.col_cw_workitemdict_casestate
     inner join tbl_cscase cse on cwi.col_id = cse.col_cw_workitemcase
     where cse.col_id = v_CaseId)
     loop
       v_result := f_DCM_createCaseMSDateEvent (NAME => rec.DateEventTypeCode, 
                                                CASEID => v_CaseId, 
                                                STATEID => rec.StateId);
     end loop;
   END IF;--in cache
end;