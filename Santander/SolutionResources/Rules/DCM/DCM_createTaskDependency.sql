declare
  v_result number;
  v_parenttask Integer;
  v_childtask Integer;
  v_parenttsi Integer;
  v_childtsi Integer;
  v_taskdep Integer;
  v_processorcode nvarchar2(255);
  v_paramname_csv nclob;
  v_paramvalue_csv nclob;
begin
  v_parenttask := :ParentTask;
  v_childtask := :ChildTask;
  v_processorcode := :ProcessorCode;
  v_paramname_csv := :ParamName_CSV;
  v_paramvalue_csv := :ParamValue_CSV;
  begin
    select tsi.col_id into v_parenttsi
      from tbl_map_taskstateinitiation tsi
      inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
      inner join tbl_dict_tasksystype tst on tsk.col_taskdict_tasksystype  = tst.col_id
      inner join tbl_dict_taskstate ts on tsi.col_map_tskstinit_tskst = ts.col_id 
      and nvl(tst.col_stateconfigtasksystype ,0) = nvl(ts.col_stateconfigtaskstate,0)
        and ts.col_id = f_dcm_getTaskStartedState3(StateConfigId => ts.col_stateconfigtaskstate)
     where tsk.col_id = v_parenttask;
    exception
      when NO_DATA_FOUND then
        v_parenttsi := null;
        return -1;
  end;
  begin
    select tsi.col_id 
    into v_childtsi
      from tbl_map_taskstateinitiation tsi
      inner join tbl_task tsk on tsi.col_map_taskstateinittask = tsk.col_id
      inner join tbl_dict_tasksystype tst on tsk.col_taskdict_tasksystype  = tst.col_id
      inner join tbl_dict_taskstate ts on tsi.col_map_tskstinit_tskst = ts.col_id 
      and nvl(tst.col_stateconfigtasksystype ,0) = nvl(ts.col_stateconfigtaskstate,0)
        and ts.col_id = f_dcm_getTaskStartedState3(StateConfigId => ts.col_stateconfigtaskstate)
      where tsk.col_id = v_childtask;
    exception
      when NO_DATA_FOUND then
        v_parenttsi := null;
        return -1;
  end;

  MERGE INTO tbl_taskdependency tdep
  USING ( SELECT v_childtsi chld, v_parenttsi prnt, v_processorcode proccode 
        FROM dual
        ) dl
  ON (tdep.col_tskdpndprnttskstateinit = dl.prnt AND tdep.col_tskdpndchldtskstateinit = dl.chld)
  WHEN MATCHED THEN 
    UPDATE SET tdep.col_processorcode = dl.proccode , col_type = 'FSCLR' 
  WHEN NOT MATCHED THEN   
    INSERT (col_tskdpndchldtskstateinit, col_tskdpndprnttskstateinit, col_processorcode, col_type, col_code) 
    VALUES (v_childtsi, v_parenttsi, v_processorcode, 'FSCLR', sys_guid())
  ;
  
 SELECT col_id 
  INTO v_taskdep
      FROM tbl_taskdependency td
     WHERE col_tskdpndchldtskstateinit = v_childtsi 
     AND col_tskdpndprnttskstateinit = v_parenttsi; 
     
  DELETE FROM tbl_autoruleparameter 
   WHERE col_autoruleparamtaskdep = v_taskdep;
   
   
   
   
  IF dbms_lob.GETLENGTH(v_paramname_csv) != 0 AND dbms_lob.GETLENGTH(v_paramvalue_csv) != 0 and v_taskdep IS NOT NULL THEN 
      for rec in (select s1.name as paramname, s2.name as paramvalue, s1."LEVEL" as nlevel, s2."LEVEL" as vlevel
              from (select regexp_substr(to_char(v_paramname_csv),'[^,]+', 1, level) as name, level as "LEVEL" from dual
              connect by regexp_substr(to_char(v_paramname_csv), '[^,]+', 1, level) is not null) s1
              inner join (select regexp_substr(to_char(v_paramvalue_csv),'[^,]+', 1, level) as name, level as "LEVEL" from dual
              connect by regexp_substr(to_char(v_paramvalue_csv), '[^,]+', 1, level) is not null) s2
              on s1."LEVEL" = s2."LEVEL"
              order by nlevel)
    loop
        insert into tbl_autoruleparameter(col_autoruleparamtaskdep, col_paramcode, col_paramvalue, col_code)
        values(v_taskdep, rec.paramname, rec.paramvalue, sys_guid());
    end loop;
  end if;
  
  update tbl_map_taskstateinitiation set col_processorcode = null where col_id = v_childtsi;
  
end;