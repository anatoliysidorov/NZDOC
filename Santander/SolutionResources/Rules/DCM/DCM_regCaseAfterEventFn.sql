declare
  v_CaseId Integer;
  v_CaseEventMoment nvarchar2(255);
  v_result number;
begin
  v_CaseId := :CaseId;
  v_CaseEventMoment := 'after';
  begin
    insert into tbl_caseeventqueue (col_caseeventqueuecaseevent, col_caseeventqueueprocstatus)
     (select ce.col_id, (select col_id from tbl_dict_processingstatus where col_code = 'NEW')
        from tbl_caseevent ce
        inner join tbl_dict_taskeventmoment dtem on ce.col_taskeventmomentcaseevent = dtem.col_id
        inner join tbl_dict_taskeventtype dtet on ce.col_taskeventtypecaseevent = dtet.col_id
        inner join tbl_map_casestateinitiation mcsi on ce.col_caseeventcasestateinit = mcsi.col_id
        inner join tbl_dict_casestate dcs on mcsi.col_map_csstinit_csst = dcs.col_id
        inner join tbl_dict_initmethod dim on mcsi.col_casestateinit_initmethod = dim.col_id
        inner join tbl_case cs on mcsi.col_map_casestateinitcase = cs.col_id
        inner join tbl_cw_workitem cwi on cs.col_cw_workitemcase = cwi.col_id and cwi.col_activity = dcs.col_activity
        where lower(dtem.col_code) = lower(v_CaseEventMoment)
        --ONLY REGULAR RULES (NOT FUNCTIONS) ARE QUEUED FOR EXECUTION
        and lower(substr(ce.col_processorcode, 1, 5)) = 'root_'
        and cs.col_id = v_CaseId);
    exception
      when DUP_VAL_ON_INDEX then
        return -1;
  end;
  v_result := f_DCM_caseEventQueueProc(CaseId => v_CaseId);
end;