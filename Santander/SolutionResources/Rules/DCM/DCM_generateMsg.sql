declare
  l_template varchar2(32767);
  v_idx    pls_integer;
  l_idx    pls_integer;
  r_idx    pls_integer;
  l_value  varchar2(32767);
  r_value  varchar2(32767);
begin
  if :p_template is null then return null; end if;

  l_template := :p_template;
  l_idx := 1;
  v_idx := 0;

  loop
    l_idx := regexp_instr(l_template, '@([^@]+)@', 1, 1, 0, 'i');
    if l_idx > 0 then
      r_idx := regexp_instr(l_template, '@([^@]+)@', 1, 1, 1, 'i');

      -- get placeholder name
      l_value := trim('@' from substr(l_template,l_idx,r_idx-l_idx));

      -- get placeholder value
      begin
        select substr(column_value, instr(column_value,:p_delim2)+1, length(column_value)-instr(column_value,:p_delim2))
          into r_value
          from table(asf_splitclob(:p_placeholders, :p_delim))
          where lower(substr(column_value, 1, instr(column_value,'=') - 1)) = lower(l_value);
        exception
          when no_data_found then
            r_value := '';
      end;

      -- replace l_value with '@' to r_value
      l_template := replace(l_template, '@' || l_value || '@', r_value);
      dbms_output.put_line(l_template);

      -- update index
      l_idx := regexp_instr(l_template, '@([^@]+)@', 1, 1, 0, 'i');
    else
      return l_template;
    end if;
  end loop;
  return l_template;
end;