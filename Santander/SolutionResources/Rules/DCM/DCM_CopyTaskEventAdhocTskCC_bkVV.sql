declare
  v_TaskId Integer;
  v_createdby nvarchar2(255);
  v_createddate date;
  v_modifiedby nvarchar2(255);
  v_modifieddate date;
  v_owner nvarchar2(255);
   v_counter number;
  v_lastcounter number;
begin
  v_TaskId := :TaskId;
  v_owner := SYS_CONTEXT('CLIENTCONTEXT','AccessSubject');
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  begin
  select GEN_TBL_TASKEVENTCC.nextval into v_counter from dual;
  
  insert into tbl_taskeventcc(col_processorcode, col_taskeventcctaskstinitcc, col_taskeventmomnttaskeventcc, 
                              col_taskeventtypetaskeventcc,col_taskeventorder,col_createdby,col_createddate,
                              col_modifiedby,col_modifieddate,col_owner)
  (select te.col_processorcode, tsi2.col_id, te.col_taskeventmomnttaskeventcc, te.col_taskeventtypetaskeventcc,
          te.col_taskeventorder, v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
  from tbl_taskeventcc te
 --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
  inner join tbl_map_taskstateinitcc tsi on te.col_taskeventcctaskstinitcc = tsi.col_id
  inner join tbl_dict_tasksystype tst on tsi.col_taskstateinitcc_tasktype = tst.col_id
  --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
  inner join tbl_map_taskstateinitcc tsi2 on tsi2.col_map_taskstateinitcctaskcc = v_TaskId and 
                                                 tsi.col_map_tskstinitcc_tskst = tsi2.col_map_tskstinitcc_tskst
  where tst.col_id = (select col_taskccdict_tasksystype from tbl_taskcc where col_id = v_TaskId));
  
  select GEN_TBL_TASKEVENTCC.currval into v_lastcounter from dual;

  for rec in (select col_id from tbl_taskeventcc where col_id between v_counter and v_lastcounter)
  loop
    update tbl_taskeventcc set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
  
  exception
     when DUP_VAL_ON_INDEX then
       return -1;
     when OTHERS then
       return -1;
  end;
end;
