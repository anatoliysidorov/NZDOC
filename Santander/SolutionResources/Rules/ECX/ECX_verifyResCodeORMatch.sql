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
begin
  v_TaskDependencyId := TaskDependencyId;
  v_result := 0;
  v_stateClosed := f_dcm_getTaskClosedState();
  v_Input := '<CustomData><Attributes>';
  v_Input := v_Input || '<ChildDependencyId>' || to_char(v_TaskDependencyId) || '</ChildDependencyId>';
  v_Input := v_Input || '<ChildDependencyType_CONST>FSCO</ChildDependencyType_CONST>';
  v_Input := v_Input || '<ParentWorkitemActivity>' || v_stateClosed || '</ParentWorkitemActivity>';
  v_Input := v_Input || '</Attributes></CustomData>';
  v_configcode := 'TASK_SEARCH';
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