declare
  v_CaseId Integer;
begin
  v_CaseId := :CaseId;
  --AUTO RULE PARAMETERS FOR CASE EVENTS
  delete from tbl_autoruleparamcc where col_caseeventccautoruleparcc in
                             (select col_id from tbl_caseeventcc where col_caseeventcccasestinitcc in
                               (select col_id from tbl_map_casestateinitcc where col_map_casestateinitcccasecc = v_CaseId));
  --SELECT ALL RULE PARAMETERS RELATED TO TASK STATE INITIATION
  delete from tbl_autoruleparamcc where col_ruleparcc_taskstateinitcc in (select col_id from tbl_map_taskstateinitcc
                                  where col_map_taskstateinitcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId));
  --SELECT ALL RULEPARAMETERS FOR TASK EVENTS
  delete from tbl_autoruleparamcc where col_taskeventccautoruleparmcc in (select col_id from tbl_taskeventcc where col_taskeventcctaskstinitcc in (select col_id from tbl_map_taskstateinitcc
                                  where col_map_taskstateinitcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId)));
  --SELECT ALL RULEPARAMETERS FOR AUTOMATIC TASKS
  delete from tbl_autoruleparamcc where col_autoruleparamcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId);
  --SELECT ALL RULEPARAMETERS FOR TASK DEPENDENCIES
  delete from tbl_autoruleparamcc where col_autoruleparamcctaskdepcc in (select col_id from tbl_taskdependencycc
                             where col_taskdpprntcctaskstinitcc in (select col_id from tbl_map_taskstateinitcc
                              where col_map_taskstateinitcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId))
                              and col_taskdpchldcctaskstinitcc in (select col_id from tbl_map_taskstateinitcc
                              where col_map_taskstateinitcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId)));
  --SELECT ALL RULE PARAMETERS RELATED TO CASE STATE INITIATION
  delete from tbl_autoruleparamcc where col_ruleparcc_casestateinitcc in (select col_id from tbl_map_casestateinitcc
                             where col_map_casestateinitcccasecc = v_CaseId);
  --SELECT ALL RULE PARAMETERS RELATED TO SLA ACTIONS
  delete from tbl_autoruleparamcc where col_autoruleparccslaactioncc in (select col_id from tbl_slaactioncc where col_slaactionccslaeventcc in
                            (select col_id from tbl_slaeventcc where col_slaeventcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId)));
  --CASE EVENTS
  delete from tbl_caseeventcc where col_caseeventcccasestinitcc in (select col_id from tbl_map_casestateinitiation where col_map_casestateinitcase = v_CaseId);
  
  --CASE DEPENDENCIES
  delete from tbl_casedependencycc 
  where (col_casedpchldcccasestinitcc in (select col_id from tbl_map_casestateinitcc
                                          where col_map_casestateinitcccasecc = v_caseid
                                         )) and
        (col_casedpprntcccasestinitcc in (select col_id from tbl_map_casestateinitcc
                                          where col_map_casestateinitcccasecc = v_caseid
                                         )); 
                                         
  -- CASE STATE INITIATION  
  delete from tbl_map_casestateinitcc where col_map_casestateinitcccasecc = v_CaseId;
  --HISTORY FOR CASE
  delete from tbl_historycc where col_historycccasecc = v_CaseId;
  --DATE EVENTS FOR CASE
  delete from tbl_dateeventcc where col_dateeventcccasecc = v_CaseId;
  --SLA ACTIONS
  delete from tbl_slaactioncc where col_slaactionccslaeventcc in (select col_id from tbl_slaeventcc where col_slaeventcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId));
  --SLA EVENTS
  delete from tbl_slaeventcc where col_slaeventcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId);
  --TASK EVENTS
  delete from tbl_taskeventcc where col_taskeventcctaskstinitcc in (select col_id from tbl_map_taskstateinitcc
                                  where col_map_taskstateinitcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId));
  --TASK DEPENDENCIES
  delete from tbl_taskdependencycc where col_taskdpchldcctaskstinitcc in (select col_id from tbl_map_taskstateinitcc
                                  where col_map_taskstateinitcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId))
                                  and col_taskdpprntcctaskstinitcc in (select col_id from tbl_map_taskstateinitcc
                                  where col_map_taskstateinitcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId));
  
 
  --TASK STATE INITIATION
  delete from tbl_map_taskstateinitcc where col_map_taskstateinitcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId);
  --TASK WORKITEMS
  delete from tbl_tw_workitemcc where col_id in (select col_tw_workitemcctaskcc from tbl_taskcc where col_casecctaskcc = v_CaseId);
  --HISTORY FOR TASKS IN CASE
  delete from tbl_historycc where col_historycctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId);
  --DATE EVENTS FOR TASKS IN CASE
  delete from tbl_dateeventcc where col_dateeventcctaskcc in (select col_id from tbl_taskcc where col_casecctaskcc = v_CaseId);
  --CASE WORKITEMS
  delete from tbl_cw_workitemcc where col_id = (select col_cw_workitemcase from tbl_case where col_id = v_CaseId);
  --TASKS
  delete from tbl_taskcc where col_casecctaskcc = v_CaseId;
  --CASE
  delete from tbl_casecc where col_id = v_CaseId;
end;