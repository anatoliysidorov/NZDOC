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
   select gen_tbl_taskdependencycc.nextval into v_counter from dual;

   insert into tbl_taskdependencycc(col_taskdpchldcctaskstinitcc,col_taskdpprntcctaskstinitcc,col_type,col_processorcode,col_taskdependencyorder,col_isdefault,
                                           col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
   (select tsic2.col_id, tsip2.col_id, td.col_type, td.col_processorcode, col_taskdependencyorder, col_isdefault, v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
    --DESIGN
    from tbl_taskdependencytmpl td
    inner join tbl_map_taskstateinittmpl tsic on td.col_taskdpchldtptaskstinittp = tsic.col_id
    inner join tbl_taskcc tskc on tsic.col_map_taskstinittpltasktpl = tskc.col_id2
    --RUNTIME
    inner join tbl_map_taskstateinitcc tsic2 on tskc.col_id = tsic2.col_map_taskstateinitcctaskcc and tsic.col_map_tskstinittpl_tskst = tsic2.col_map_tskstinitcc_tskst
    --DESIGN
    inner join tbl_map_taskstateinittmpl tsip on td.col_taskdpprnttptaskstinittp = tsip.col_id
    inner join tbl_taskcc tskp on tsip.col_map_taskstinittpltasktpl = tskp.col_id2
    --RUNTIME
    inner join tbl_map_taskstateinitcc tsip2 on tskp.col_id = tsip2.col_map_taskstateinitcctaskcc and tsip.col_map_tskstinittpl_tskst = tsip2.col_map_tskstinitcc_tskst
    where tskc.col_casecctaskcc = v_CaseId and tskp.col_casecctaskcc = v_CaseId
   );
   
   select gen_tbl_taskdependencycc.currval into v_lastcounter from dual;

  for rec in (select col_id from tbl_taskdependencycc where col_id between v_counter and v_lastcounter)
  loop
    update tbl_taskdependencycc set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
  
   exception
     when DUP_VAL_ON_INDEX then
       :ErrorCode := 100;
       :ErrorMessage := 'DCM_CopyTaskDependencyCC: ' || SUBSTR(SQLERRM, 1, 200);
       return -1;
     when OTHERS then
       :ErrorCode := 100;
       :ErrorMessage := 'DCM_CopyTaskDependencyCC: ' || SUBSTR(SQLERRM, 1, 200);
       return -1;
  end;
end;