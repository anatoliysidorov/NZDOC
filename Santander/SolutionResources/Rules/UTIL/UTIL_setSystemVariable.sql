DECLARE
  v_result       NUMBER;
  v_EnvId        NUMBER;
  v_SysVarName   NVARCHAR2(32767);
  v_SysVarValue  NVARCHAR2(32767);
  v_count_names  INTEGER;
  v_count_values INTEGER;

  v_errorcode    INTEGER;
  v_errormessage NVARCHAR2(255);
BEGIN

  v_SysVarName  := :SYSVAR_NAME;
  v_SysVarValue := :SYSVAR_VALUE;

  v_errorcode    := 0;
  v_errormessage := '';

  -- get environment information
  SELECT VALUE INTO v_EnvId FROM CONFIG WHERE NAME = 'ENVIRONMENT_ID';

  -- check on the same number of elements in SYSVAR_NAME as there are in SYSVAR_VALUE
  SELECT COUNT(regexp_substr(v_SysVarName, '[[:' || 'alnum:]_]+', 1, LEVEL))
    INTO v_count_names
    FROM dual
  CONNECT BY dbms_lob.getlength(regexp_substr(v_SysVarName, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0;
  SELECT COUNT(regexp_substr(v_SysVarValue, '[[:' || 'alnum:]_]+', 1, LEVEL))
    INTO v_count_values
    FROM dual
  CONNECT BY dbms_lob.getlength(regexp_substr(v_SysVarValue, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0;

  IF (v_count_names <> v_count_values) THEN
    v_errorcode    := 101;
    v_errormessage := 'The number of names does not correspond to the number of values';
    GOTO cleanup;
  END IF;

  BEGIN
    FOR rec IN (SELECT t_names.name   AS NAME,
                       t_values.value AS VALUE
                  FROM (SELECT ROWNUM AS rn_name,
                               regexp_substr(v_SysVarName, '[[:' || 'alnum:]_]+', 1, LEVEL) AS NAME
                          FROM dual
                        CONNECT BY dbms_lob.getlength(regexp_substr(v_SysVarName, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) t_names,
                       (SELECT ROWNUM AS rn_value,
                               regexp_substr(v_SysVarValue, '[[:' || 'alnum:]_]+', 1, LEVEL) AS VALUE
                          FROM dual
                        CONNECT BY dbms_lob.getlength(regexp_substr(v_SysVarValue, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) t_values
                 WHERE t_names.rn_name = t_values.rn_value) LOOP
    
      -- set System variables
      v_result := @TOKEN_SYSTEMDOMAINUSER@.INST_UPDATESYSVAR(v_EnvId, rec.name, rec.value, '1', '');
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode    := 102;
      v_errormessage := SUBSTR(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :ErrorCode    := v_errorcode;
  :ErrorMessage := v_errormessage;
END;