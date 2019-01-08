DECLARE
v_taskid number;
v_xml nclob;
BEGIN
v_taskid := :TaskId;
v_xml := EMPTY_CLOB();
:Result := v_xml;
v_xml := '<CustomData><Attributes></Attributes></CustomData>';
:Result := v_xml;
END;