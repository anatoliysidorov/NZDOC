DECLARE
v_taskid number;
v_emaillist nclob;
BEGIN
v_taskid := :TaskId;
v_emaillist := EMPTY_CLOB();
:Result := v_emaillist;
v_emaillist := 'nlavrush@gmail.com,nlavrushenko@eccentex.com';
:Result := v_emaillist;
END;