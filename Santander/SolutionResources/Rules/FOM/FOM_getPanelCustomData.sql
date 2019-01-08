declare
  v_CaseId Integer;
  v_TaskId Integer;
  v_input nclob;
  v_sort nvarchar2(255);
  v_dir nvarchar2(255);
  v_UIElementCode nvarchar2(255);
  v_ProcessorCode nvarchar2(255);
  v_cur sys_refcursor;
  v_result number;
begin
  v_CaseId := :CaseId;
  v_TaskId := :TaskId;
  v_input := :Input;
  v_sort := :Sort;
  v_dir := :Dir;
  v_UIElementCode := :UIElementCode;
  begin
    select col_processorcode into v_ProcessorCode from tbl_fom_uielement where lower(col_code) = lower(v_UIElementCode);
    exception
    when NO_DATA_FOUND then
      v_ProcessorCode := null;
      return;
  end;
  if v_ProcessorCode is not null then
    v_cur := f_dcm_invokeItemsProcessor2(CaseId => v_CaseId, Dir => v_dir, Input => v_input, ProcessorName => v_ProcessorCode, Sort => v_sort, TaskId => v_TaskId);
  end if;
  :Items := v_cur;
end;