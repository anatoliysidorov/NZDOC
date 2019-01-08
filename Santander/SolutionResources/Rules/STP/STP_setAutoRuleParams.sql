DECLARE
  v_objecttargettype NVARCHAR2(255);
  v_objecttargetrid  NUMBER;
  v_paramcodes       NCLOB;
  v_paramvalues      NCLOB;
  v_count_codes      INT;
  v_count_values     INT;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_objecttargettype := :ObjectTargetType;
  v_objecttargetrid  := :ObjectTargetrId;
  v_paramcodes       := :ParamCodes;
  v_paramvalues      := :ParamValues;
  v_count_codes      := 0;
  v_count_values     := 0;

  v_errorcode    := 0;
  v_errormessage := '';

  BEGIN
    -- check on the same number of "units" in ParamCodes as there are in ParamValues
    SELECT COUNT(to_char(regexp_substr(v_paramcodes, '[[:' || 'alnum:]_]+', 1, LEVEL)))
      INTO v_count_codes
      FROM dual
    CONNECT BY dbms_lob.getlength(regexp_substr(v_paramcodes, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0;
    SELECT COUNT(to_char(regexp_substr(v_paramvalues, '[[:' || 'alnum:]_]+', 1, LEVEL)))
      INTO v_count_values
      FROM dual
    CONNECT BY dbms_lob.getlength(regexp_substr(v_paramvalues, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0;
  
    IF (v_count_codes <> v_count_values) THEN
      v_errorcode    := 102;
      v_errormessage := 'The number of codes does not correspond to the number of values';
      GOTO cleanup;
    END IF;
  
    -- If ObjectTargetType = 'SLAACTION'
    IF (UPPER(v_objecttargettype) = 'SLAACTION') THEN
      -- delete all AutoRuleParameters for that SLAAction
      DELETE FROM TBL_AUTORULEPARAMETER WHERE col_autoruleparamslaaction = v_objecttargetrid;
    
      -- insert new ParamCodes and ParamValues
      FOR rec IN (SELECT t_codes.paramcode   AS paramcode,
                         t_values.paramvalue AS paramvalue
                    FROM (SELECT ROWNUM AS rn_code,
                                 to_char(regexp_substr(v_paramcodes, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS paramcode
                            FROM dual
                          CONNECT BY dbms_lob.getlength(regexp_substr(v_paramcodes, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) t_codes,
                         (SELECT ROWNUM AS rn_value,
                                 to_char(regexp_substr(v_paramvalues, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS paramvalue
                            FROM dual
                          CONNECT BY dbms_lob.getlength(regexp_substr(v_paramvalues, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) t_values
                   WHERE t_codes.rn_code = t_values.rn_value) LOOP
        INSERT INTO TBL_AUTORULEPARAMETER (col_autoruleparamslaaction, col_paramcode, col_paramvalue, col_code) VALUES (v_objecttargetrid, rec.paramcode, rec.paramvalue, sys_guid());
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode    := 101;
      v_errormessage := SUBSTR(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;