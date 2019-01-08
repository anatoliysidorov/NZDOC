declare
--v_result nvarchar(255);
begin
  -- Call the function
  select sys_context('CLIENTCONTEXT', 'AccessSubject') INTO :result from dual;
end;