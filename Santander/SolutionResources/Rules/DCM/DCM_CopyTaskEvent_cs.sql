declare
  v_CaseId Integer;
  v_createdby nvarchar2(255);
  v_createddate date;
  v_modifiedby nvarchar2(255);
  v_modifieddate date;
  v_owner nvarchar2(255);
  v_counter number;
  v_lastcounter number;
  
begin
  v_CaseId := :CaseId;
  v_owner := :owner;
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  :ErrorCode := 0;
  :ErrorMessage := null;
  
  begin
  	select GEN_TBL_TASKEVENT.nextval into v_counter from dual;
  
    insert into tbl_taskevent(col_processorcode,col_taskeventtaskstateinit,col_taskeventmomenttaskevent,col_taskeventtypetaskevent,col_taskeventorder,
                              col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
    (select te.col_processorcode,tsi2.col_id,te.col_taskeventmomnttaskeventtp,te.col_taskeventtypetaskeventtp,te.col_taskeventorder,
            v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
      from tbl_taskeventtmpl te
     --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
      inner join tbl_map_taskstateinittmpl tsi on te.col_taskeventtptaskstinittp = tsi.col_id
      inner join tbl_task tsk on tsi.col_map_taskstinittpltasktpl = tsk.col_id2
      --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
      inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinittpl_tskst = tsi2.col_map_tskstinit_tskst
      where tsk.col_casetask = v_CaseId);
      
      select GEN_TBL_TASKEVENT.currval into v_lastcounter from dual;

  for rec in (select col_id from tbl_taskevent where col_id between v_counter and v_lastcounter)
  loop
    update tbl_taskevent set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
      
      exception
        when DUP_VAL_ON_INDEX then
          :ErrorCode := 100;
          :ErrorMessage := 'DCM_CopyTaskEvent: ' || SUBSTR(SQLERRM, 1, 200);
        when OTHERS then
          :ErrorCode := 100;
          :ErrorMessage := 'DCM_CopyTaskEvent: ' || SUBSTR(SQLERRM, 1, 200);
  end;
end;