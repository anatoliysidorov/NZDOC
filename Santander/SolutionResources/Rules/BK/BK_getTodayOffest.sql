DECLARE
  v_format     VARCHAR2(50);
  v_def_format VARCHAR2(50) := 'Mon DD, YYYY';
  v_offset number;
BEGIN
  v_offset := :Offset;
  if( v_offset is NULL) then v_offset := 0; ENd IF;

  SELECT to_char(SYSDATE+v_offset, v_def_format) INTO :ResultText FROM dual;

EXCEPTION
  WHEN OTHERS THEN
    SELECT to_char(SYSDATE+v_offset, v_def_format) INTO :ResultText FROM dual;

END;