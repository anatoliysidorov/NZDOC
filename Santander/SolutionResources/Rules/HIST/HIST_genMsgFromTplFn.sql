DECLARE
  --input params
  v_targetid INTEGER;
  v_targettype NVARCHAR2(40);
  v_messagecode NVARCHAR2(255);
  --calculated and other
  v_delim  CHAR(1);
  v_delim2 CHAR(1);
  v_placeholders NVARCHAR2(255);
  v_template NCLOB;
  v_idx PLS_INTEGER;
  l_idx PLS_INTEGER;
  r_idx PLS_INTEGER;
  l_value    VARCHAR2(32767);
  l_template VARCHAR2(32767);
  v_count PLS_INTEGER;
  v_placeholder NVARCHAR2(255);
  v_value NVARCHAR2(255);
  v_processorcode NVARCHAR2(255);
  v_result NCLOB;
BEGIN
  --bind variables
  v_targetid    := :TargetId;
  v_targettype  := Lower(:TargetType);
  v_messagecode := Lower(:MessageCode);
  
  --other
  v_delim        := '~';
  v_delim2       := '=';
  v_placeholders := '';
  
  --FIND THE MESSAGE TEMPLATE
  BEGIN
    SELECT col_template
    INTO v_template
    FROM tbl_message
    WHERE Lower(col_code) = Lower(v_messagecode);
  EXCEPTION
  WHEN no_data_found THEN
    RETURN 'No message template found with code ' || v_messagecode;
  END;
  
  --EXTRACT ALL PLACEHOLDERS FROM MESSAGE TEMPLATE
  l_template := v_template;
  v_count    := 1;
  LOOP
    l_idx     := Regexp_instr(l_template, '@([^@]+)@', 1, v_count, 0, 'i');
    IF l_idx   > 0 THEN
    
      r_idx   := Regexp_instr(l_template, '@([^@]+)@', 1, v_count, 1, 'i');
      l_value := Trim('@' FROM SUBSTR(l_template, l_idx, r_idx - l_idx));
      
      BEGIN
        SELECT col_placeholder,
          col_value,
          col_processorcode
        INTO v_placeholder,
          v_value,
          v_processorcode
        FROM tbl_messageplaceholder
        WHERE Lower(col_placeholder) = Lower(l_value);
      EXCEPTION
      WHEN no_data_found THEN
        RETURN 'Placeholder not found with code';
      WHEN too_many_rows THEN
        RETURN 'Placeholder not found';
      END;
      
      IF LENGTH(v_placeholders) > 0 THEN
        v_placeholders         := v_placeholders || v_delim;
      END IF;
      
      IF v_processorcode IS NOT NULL THEN
        v_placeholders   := v_placeholders || v_placeholder || v_delim2 || F_UTIL_genericInvokerFn(ProcessorName => v_processorcode, TargetId => v_targetid, TargetType => v_targettype);
      ELSIF v_value      IS NOT NULL THEN
        v_placeholders   := v_placeholders || v_placeholder || v_delim2 || v_value;
      ELSE
        RETURN 'Placeholder cannot be resolved';
      END IF;
      
    ELSE
      EXIT;
    END IF;
    v_count := v_count + 1;
  END LOOP;
  
  --MERGE PLACEHOLDERS WITH MESSAGE
  v_result := F_HIST_mergePlcsTmpl(p_delim => v_delim, p_delim2 => v_delim2, p_placeholders => v_placeholders, p_template => v_template);
  
  --RETURN THE CALCULATED MESSAGE
  RETURN v_result;
END;