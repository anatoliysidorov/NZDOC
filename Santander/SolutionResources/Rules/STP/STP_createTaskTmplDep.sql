declare
  v_result number;
  v_parenttmpl Integer;
  v_childtmpl Integer;
  v_parenttsi Integer;
  v_childtsi Integer;
  v_taskdep Integer;
  v_processorcode nvarchar2(255);
  v_paramname_csv nclob;
  v_paramvalue_csv nclob;
  v_lastcounter number;
begin
  v_parenttmpl := :ParentTmpl;
  v_childtmpl := :ChildTmpl;
  v_processorcode := :ProcessorCode;
  v_paramname_csv := :ParamName_CSV;
  v_paramvalue_csv := :ParamValue_CSV;
  begin
    select tsi.col_id into v_parenttsi
      from tbl_map_taskstateinitiation tsi
      inner join tbl_tasktemplate tt on tsi.col_map_taskstateinittasktmpl = tt.col_id
      inner join tbl_procedure pr on tt.col_proceduretasktemplate = pr.col_id
      inner join tbl_dict_casesystype cst on pr.col_proceduredict_casesystype = cst.col_id
      inner join tbl_dict_taskstate ts on tsi.col_map_tskstinit_tskst = ts.col_id and nvl(cst.col_stateconfigcasesystype,0) = nvl(ts.col_stateconfigtaskstate,0)
        and ts.col_id = f_dcm_getTaskClosedState3(StateConfigId => ts.col_stateconfigtaskstate)
      where tt.col_id = v_parenttmpl;
    exception
      when NO_DATA_FOUND then
        v_parenttsi := null;
        return -1;
  end;
  begin
    select tsi.col_id into v_childtsi
      from tbl_map_taskstateinitiation tsi
      inner join tbl_tasktemplate tt on tsi.col_map_taskstateinittasktmpl = tt.col_id
      inner join tbl_procedure pr on tt.col_proceduretasktemplate = pr.col_id
      inner join tbl_dict_casesystype cst on pr.col_proceduredict_casesystype = cst.col_id
      inner join tbl_dict_taskstate ts on tsi.col_map_tskstinit_tskst = ts.col_id and nvl(cst.col_stateconfigcasesystype,0) = nvl(ts.col_stateconfigtaskstate,0)
        and ts.col_id = f_dcm_getTaskStartedState3(StateConfigId => ts.col_stateconfigtaskstate)
      where tt.col_id = v_childtmpl;
    exception
      when NO_DATA_FOUND then
        v_parenttsi := null;
        return -1;
  end;
  begin
    select col_id into v_taskdep
      from tbl_taskdependency td
      where col_tskdpndchldtskstateinit = v_childtsi and col_tskdpndprnttskstateinit = v_parenttsi;
    exception
    when NO_DATA_FOUND then
      v_taskdep := null;
  end;
  if nvl(v_taskdep,0) > 0 then
    update tbl_taskdependency set col_processorcode = v_processorcode, col_type = 'FSCLR' where col_id = v_taskdep;
  else
    insert into tbl_taskdependency (col_tskdpndchldtskstateinit, col_tskdpndprnttskstateinit, col_processorcode, col_type, col_code) values (v_childtsi, v_parenttsi, v_processorcode, 'FSCLR', sys_guid());
    select gen_tbl_taskdependency.currval into v_taskdep from dual;
  end if;
  delete from tbl_autoruleparameter where col_autoruleparamtaskdep = v_taskdep;
  for rec in (select s1.name as paramname, s2.name as paramvalue, s1."LEVEL" as nlevel, s2."LEVEL" as vlevel
              from (select regexp_substr('v_paramname_csv','[^,]+', 1, level) as name, level as "LEVEL" from dual
              connect by regexp_substr('v_paramname_csv', '[^,]+', 1, level) is not null) s1
              inner join (select regexp_substr('v_paramvalue_csv','[^,]+', 1, level) as name, level as "LEVEL" from dual
              connect by regexp_substr('v_paramvalue_csv', '[^,]+', 1, level) is not null) s2
              on s1."LEVEL" = s2."LEVEL"
              order by nlevel)
  loop
    insert into tbl_autoruleparameter(col_autoruleparamtaskdep, col_paramcode, col_paramvalue)
      values(v_taskdep, rec.paramname, rec.paramvalue);
    select gen_tbl_autoruleparameter.currval into v_lastcounter from dual;
    update tbl_autoruleparameter set col_code = sys_guid() where col_id = v_lastcounter;
  end loop;
  update tbl_map_taskstateinitiation set col_processorcode = null where col_id = v_childtsi;
end;