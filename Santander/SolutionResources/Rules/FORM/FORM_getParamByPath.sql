declare
  v_input    xmltype;
  v_param    nvarchar2(255);
  v_result   nvarchar2(255);
begin
  v_input := XMLType(:Input);
  v_param := :Param;

  v_result := v_input.extract(Param).getStringval();
  return v_result;

end;