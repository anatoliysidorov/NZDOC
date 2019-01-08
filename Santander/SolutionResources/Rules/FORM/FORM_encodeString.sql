declare
  v_input    nclob;
  buf        nclob;
begin
  v_input := :Input;
  buf := v_input;
  buf := replace(buf, '&', '&amp;');
  buf := replace(buf, '''', '&apos;');
  buf := replace(buf, '"', '&quot;');
  buf := replace(buf, '>', '&gt;');
  buf := replace(buf, '<', '&lt;');
  return buf;
end;