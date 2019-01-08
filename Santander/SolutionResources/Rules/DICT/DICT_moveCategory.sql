DECLARE
  v_SourceRecId NUMBER;
  v_TargetRecId NUMBER;
  v_srcid       NUMBER;
  v_srcname     NVARCHAR2(255);
  v_srcrecid    NVARCHAR2(255);
  v_srcrecorder NUMBER;
  v_srcparentid NUMBER;
  v_trgid       NUMBER;
  v_trgname     NVARCHAR2(255);
  v_trgrecid    NVARCHAR2(255);
  v_trgrecorder NUMBER;
  v_trgparentid NUMBER;
  v_Position    NVARCHAR2(32);

  v_NewParentId NUMBER;
  v_NewRecOrder NUMBER;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_errorcode    := 0;
  v_errormessage := '';

  v_SourceRecId := :SourceRecId;
  v_TargetRecId := :TargetRecId;
  v_Position    := :Position; -- "before", "after" or "append"

  BEGIN
    BEGIN
      SELECT col_id,
             col_name,
             COL_CATEGORYORDER,
             COL_CATEGORYCATEGORY
        INTO v_srcid,
             v_srcname,
             v_srcrecorder,
             v_srcparentid
        FROM TBL_DICT_CUSTOMCATEGORY
       WHERE col_id = v_SourceRecId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorcode    := 101;
        v_errormessage := 'Record with source id ' || to_char(v_SourceRecId) || ' is not found: operation is not allowed';
        GOTO сleanup;
    END;

    BEGIN
      SELECT col_id,
             col_name,
             COL_CATEGORYORDER,
             COL_CATEGORYCATEGORY
        INTO v_trgid,
             v_trgname,
             v_trgrecorder,
             v_trgparentid
        FROM TBL_DICT_CUSTOMCATEGORY
       WHERE col_id = v_TargetRecId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errorcode    := 102;
        v_errormessage := 'Record with target id ' || to_char(v_TargetRecId) || ' is not found: operation is not allowed';
        GOTO сleanup;
    END;

    v_NewParentId := v_trgparentid;
    v_NewRecOrder := v_trgrecorder;
    IF (v_Position = 'append') THEN
      v_NewParentId := v_TargetRecId;
      SELECT MAX(COL_CATEGORYORDER) + 1 INTO v_NewRecOrder FROM TBL_DICT_CUSTOMCATEGORY WHERE COL_CATEGORYCATEGORY = v_TargetRecId;
    END IF;
    IF (v_Position = 'after') THEN
      v_NewRecOrder := v_trgrecorder + 1;

      FOR i IN (SELECT col_id
                  FROM TBL_DICT_CUSTOMCATEGORY
                 WHERE COL_CATEGORYCATEGORY = v_trgparentid
                   AND COL_CATEGORYORDER >= v_NewRecOrder) LOOP
        UPDATE TBL_DICT_CUSTOMCATEGORY SET COL_CATEGORYORDER = COL_CATEGORYORDER + 1 WHERE col_id = i.col_id;
      END LOOP;

    END IF;

    IF (v_Position = 'before') THEN
      v_NewRecOrder := v_trgrecorder;

      FOR i IN (SELECT col_id
                  FROM TBL_DICT_CUSTOMCATEGORY
                 WHERE COL_CATEGORYCATEGORY = v_trgparentid
                   AND COL_CATEGORYORDER >= v_NewRecOrder) LOOP
        UPDATE TBL_DICT_CUSTOMCATEGORY SET COL_CATEGORYORDER = COL_CATEGORYORDER + 1 WHERE col_id = i.col_id;
      END LOOP;
    END IF;

    UPDATE TBL_DICT_CUSTOMCATEGORY SET COL_CATEGORYORDER = v_NewRecOrder, COL_CATEGORYCATEGORY = v_NewParentId WHERE col_id = v_SourceRecId;

    FOR i IN (SELECT col_id,
                     rownum rn
                FROM (SELECT col_id,
                             COL_CATEGORYORDER
                        FROM TBL_DICT_CUSTOMCATEGORY
                       WHERE COL_CATEGORYCATEGORY = v_trgparentid
                       ORDER BY COL_CATEGORYORDER)) LOOP
      UPDATE TBL_DICT_CUSTOMCATEGORY SET COL_CATEGORYORDER = i.rn WHERE col_id = i.col_id;
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode    := 100;
      v_errormessage := SUBSTR(SQLERRM, 1, 200);
  END;

  <<сleanup>>
  :ErrorCode    := v_errorcode;
  :ErrorMessage := v_errormessage;
END;