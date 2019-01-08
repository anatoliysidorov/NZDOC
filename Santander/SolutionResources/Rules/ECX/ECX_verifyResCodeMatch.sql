declare
  v_result number;
  v_TaskDependencyId Integer;
  v_ResolutionCode nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_Input varchar2(32676);
  v_configid Integer;
  v_configcode nvarchar2(255);
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
  v_Items sys_refcursor;
  v_TotalCount Integer;
  v_StateConfigId Integer;
begin
  v_TaskDependencyId := TaskDependencyId;
  v_result := 0;
  begin
    select tst.col_stateconfigtasksystype into v_StateConfigId
      from tbl_dict_tasksystype tst
      inner join tbl_task tsk on tst.col_id = tsk.col_taskdict_tasksystype
      inner join tbl_map_taskstateinitiation tsi on tsk.col_id = tsi.col_map_taskstateinittask
      inner join tbl_taskdependency td on tsi.col_id = td.col_tskdpndprnttskstateinit
      where td.col_id = v_TaskDependencyId;
    exception
    when NO_DATA_FOUND then
    v_StateConfigId := null;
  end;
  v_stateClosed := f_dcm_getTaskClosedState2(StateConfigId => v_StateConfigId);
  v_Input := '<CustomData><Attributes>';
  v_Input := v_Input || '<ChildDependencyCCId>' || to_char(v_TaskDependencyId) || '</ChildDependencyCCId>';
  v_Input := v_Input || '<ChildDependencyCCType_CONST>FSCLR</ChildDependencyCCType_CONST>';
  v_Input := v_Input || '<PWorkitemCCActivity>' || v_stateClosed || '</PWorkitemCCActivity>';
  v_Input := v_Input || '</Attributes></CustomData>';
  v_configcode := 'TASKCC_SEARCH';
  begin
    select col_id into v_configid from tbl_som_config where col_code = v_configcode;
    exception
    when NO_DATA_FOUND then
    TaskResult := 0;
    return 0;
  end;
  v_result := f_SOM_dynamicSearchFn(ConfigId => v_configid, DIR => null, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, FIRST => null, ITEMS => v_Items,
                                         Input => v_Input, LIMIT => null, SORT => null, AccessSubjectCode => null, TotalCount => v_TotalCount);
  if v_TotalCount > 0 then
    v_result := 1;
  else
    v_result := 0;
  end if;
  TaskResult := v_result;
  return v_result;
end;