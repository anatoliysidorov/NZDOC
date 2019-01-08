DECLARE
  v_fromid         NUMBER;
  v_toid           NUMBER;
  v_position       NVARCHAR2(255);
  v_order          NUMBER;
  v_toorder        NUMBER;
  v_categoryId     NUMBER;
  v_count          INTEGER;
  v_result		   NUMBER;

  v_errorcode    INTEGER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_fromid   := :FromID;
  v_toid     := :ToID;
  v_position := :Position;
  v_order    := 1;

  v_errorcode    := 0;
  v_errormessage := '';

  --Check the input params
  IF v_fromid IS NULL THEN
    v_errormessage := 'From Id can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  ELSIF v_toid IS NULL THEN
    v_errormessage := 'To Id can not be empty';
    v_errorcode    := 102;
    GOTO cleanup;
  ELSIF v_position IS NULL THEN
    v_errormessage := 'Position can not be empty';
    v_errorcode    := 103;
    GOTO cleanup;
  END IF;

  -- Get and check CategoryId
  SELECT col_wordcategory
  INTO v_categoryId
  FROM TBL_DICT_CUSTOMWORD
  WHERE col_id = v_fromid;

  SELECT COUNT(col_id)
  INTO v_count
  FROM TBL_DICT_CUSTOMCATEGORY
  WHERE col_id = v_categoryId;

  IF (v_count = 0) THEN
    v_errorcode := 105;
    --v_errormessage := 'Cannot find Category with Id: ' || TO_CHAR(v_categoryId);
	v_errormessage := 'Cannot find Category with Id: {{MESS_CATEGORYID}}';
	v_result := LOC_i18n(
	  MessageText => v_errormessage,
	  MessageResult => v_errormessage,
	  MessageParams => NES_TABLE(
		Key_Value('MESS_CATEGORYID', TO_CHAR(v_categoryId))
	  )
	);
    GOTO cleanup;
  END IF;

  BEGIN
    FOR rec IN (SELECT col_id AS id
                FROM TBL_DICT_CUSTOMWORD
                WHERE col_wordcategory = v_categoryId
                ORDER BY col_wordorder) 
	LOOP
    
      IF rec.id = v_fromid THEN
        continue;
      END IF;
    
      IF (rec.id = v_toid AND lower(v_position) = 'before') THEN
        v_toorder := v_order;
        v_order   := v_order + 1;
      END IF;
    
      UPDATE TBL_DICT_CUSTOMWORD SET col_wordorder = v_order WHERE col_id = rec.id;
    
      IF (rec.id = v_toid AND lower(v_position) = 'after') THEN
        v_order   := v_order + 1;
        v_toorder := v_order;
      END IF;
    
      v_order := v_order + 1;
    END LOOP;
  
    UPDATE TBL_DICT_CUSTOMWORD SET col_wordorder = v_toorder WHERE col_id = v_fromid;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errormessage := substr(SQLERRM, 1, 200);
      v_errorcode    := 104;
      ROLLBACK;
      GOTO cleanup;
  END;

  <<cleanup>>
  :errorMessage := v_errormessage;
  :errorCode    := v_errorcode;
END;