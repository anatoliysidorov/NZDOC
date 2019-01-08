DECLARE
  v_ids              NCLOB;
  v_posindexes       NCLOB;
  v_count_ids        INT;
  v_count_posindexes INT;
  v_description      NCLOB;
  v_pageid           NUMBER;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_ids              := :Ids;
  v_posindexes       := :PosIndexes;
  v_count_ids        := 0;
  v_count_posindexes := 0;

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  -- check on the same number of elements in Ids as there are in PosIndexes
  SELECT COUNT(to_number(regexp_substr(v_ids, '[[:' || 'alnum:]_]+', 1, LEVEL))) INTO v_count_ids FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(v_ids, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0;
  SELECT COUNT(to_number(regexp_substr(v_posindexes, '[[:' || 'alnum:]_]+', 1, LEVEL)))
    INTO v_count_posindexes
    FROM dual
  CONNECT BY dbms_lob.getlength(regexp_substr(v_posindexes, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0;

  IF (v_count_ids <> v_count_posindexes) THEN
    v_errorcode    := 102;
    v_errormessage := 'The number of ids does not correspond to the number of values';
    GOTO cleanup;
  END IF;

  BEGIN
    FOR rec IN (SELECT t_ids.id              AS elementId,
                       t_posindexes.posindex AS positionIndex
                  FROM (SELECT ROWNUM AS rn_id,
                               to_number(regexp_substr(v_ids, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id
                          FROM dual
                        CONNECT BY dbms_lob.getlength(regexp_substr(v_ids, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) t_ids,
                       (SELECT ROWNUM AS rn_posindex,
                               to_number(regexp_substr(v_posindexes, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS posindex
                          FROM dual
                        CONNECT BY dbms_lob.getlength(regexp_substr(v_posindexes, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) t_posindexes
                 WHERE t_ids.rn_id = t_posindexes.rn_posindex) LOOP
      UPDATE tbl_fom_uielement SET col_positionindex = rec.positionIndex WHERE col_id = rec.elementId;
      :affectedRows := :affectedRows + 1;
    END LOOP;
  
    -- update Modified By/Date for tbl_FOM_Page
    SELECT col_uielementpage
      INTO v_pageid
      FROM tbl_fom_uielement
     WHERE col_id = (SELECT to_number(regexp_substr(v_ids, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id
                       FROM dual
                      WHERE rownum = 1
                     CONNECT BY dbms_lob.getlength(regexp_substr(v_ids, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0);
    SELECT col_description INTO v_description FROM tbl_fom_page WHERE col_id = v_pageid;
    UPDATE tbl_fom_page SET col_description = v_description WHERE col_id = v_pageid;
  EXCEPTION
    WHEN OTHERS THEN
      :affectedRows  := 0;
      v_errorcode    := 101;
      v_errormessage := SUBSTR(SQLERRM, 1, 200);
  END;

  --set success message
  :SuccessResponse := 'Reordered {{MESS_COUNT}} elements';
  :MESS_COUNT      := to_char(:affectedRows);

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
