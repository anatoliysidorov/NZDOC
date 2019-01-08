declare
  v_result number;
  v_TaskId Integer;
  v_MessageCode nvarchar2(255);
  v_message nclob;
begin
  v_TaskId := :TaskId;
  v_result := 1;
  v_MessageCode := 'SampleValidation';
  v_message := f_HIST_genMsgFromTplFn(TargetType=>'task', TargetId=>v_TaskId, MessageCode=> v_MessageCode);
  :ValidationResult := v_result;
  :Message := v_message;
end;