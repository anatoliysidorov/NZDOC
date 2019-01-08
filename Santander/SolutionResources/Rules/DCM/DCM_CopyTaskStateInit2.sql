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
  select gen_tbl_map_taskstateinitiat.nextval into v_counter from dual;
  begin
   insert into tbl_map_taskstateinitiation(col_map_taskstateinittask,col_processorcode,col_assignprocessorcode,col_map_tskstinit_initmtd,col_map_tskstinit_tskst,
                                          col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
   (select tsk.col_id, col_processorcode, col_assignprocessorcode, col_map_tskstinit_initmtd, col_map_tskstinit_tskst, v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
    from tbl_map_taskstateinitiation tsi
     inner join tbl_task tsk on tsi.col_map_taskstateinittasktmpl = tsk.col_id2
   where tsk.col_casetask = v_CaseId);
   exception
     when DUP_VAL_ON_INDEX then
       :ErrorCode := 100;
       :ErrorMessage := 'DCM_CopyTaskStateInit: ' || SUBSTR(SQLERRM, 1, 200);
       return -1;
     when OTHERS then
       :ErrorCode := 100;
       :ErrorMessage := 'DCM_CopyTaskStateInit: ' || SUBSTR(SQLERRM, 1, 200);
       return -1;
  end;
  select gen_tbl_map_taskstateinitiat.currval into v_lastcounter from dual;
  for rec in (select col_id from tbl_map_taskstateinitiation where col_id between v_counter and v_lastcounter)
  loop
    update tbl_map_taskstateinitiation set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
end;