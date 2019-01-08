declare
  v_ConfigId Integer;
  v_input nclob;
  v_RootObjectId Integer;
  v_RootObjectName nvarchar2(255);
  v_session nvarchar2(255);
  v_result number;
begin
  v_ConfigId := :ConfigId;
  v_input := :Input;
  v_RootObjectId := :RootObjectIdId;
  v_RootObjectName := upper(:RootObjectName);
  if v_RootObjectName is null then
    v_RootObjectName := 'CASE';
  end if;
  v_result := f_DOM_populateDynUpdCache(ConfigId => v_ConfigId, Input => v_input, RootObjectId => v_RootObjectId, RootObjectName => v_RootObjectName, Session => v_session);
  v_result := f_DOM_executeDynUpd(ConfigId => v_ConfigId, Session => v_session);
end;