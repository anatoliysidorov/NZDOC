DECLARE
  c_words SYS_REFCURSOR;

  v_sql        VARCHAR2(2000);
  v_categoryId NUMBER;
  v_field      NVARCHAR2(255);
  v_direction  NVARCHAR2(5);

  v_Id        NUMBER;
  v_WordOrder NUMBER;
  v_result	  NUMBER;

  v_errorcode    INTEGER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_categoryId := :CategoryId;
  v_field      := NVL(UPPER(:Field), 'NAME');
  v_direction  := NVL(UPPER(:Direction), 'ASC');

  v_errorcode    := 0;
  v_errormessage := '';

  -- Validations
  BEGIN
    IF (v_categoryId IS NULL) THEN
      v_errorcode    := 101;
      v_errormessage := 'Id can not be empty';
      GOTO error_exception;
    END IF;
  
    IF (v_direction NOT IN ('ASC', 'DESC')) THEN
      v_errorcode    := 102;
      --v_errormessage := 'Wrong Direction value: "' || v_direction || '".';
	    v_errormessage := 'Wrong Direction value: {{MESS_DIRECTION}}';
		v_result := LOC_i18n(
		  MessageText => v_errormessage,
		  MessageResult => v_errormessage,
		  MessageParams => NES_TABLE(
			Key_Value('MESS_DIRECTION', v_direction)
		  )
		);
		GOTO error_exception;
    END IF;
  END;

  BEGIN
    v_sql := 'SELECT col_id AS Id, RANK() OVER (PARTITION BY col_wordcategory ORDER BY UPPER(col_' || v_field || ') ' || v_direction ||
             ') AS WordOrder FROM TBL_DICT_CUSTOMWORD WHERE col_wordcategory = ' || to_char(v_categoryId);
  
    OPEN c_words FOR v_sql;
  
    LOOP
      FETCH c_words INTO v_Id, v_WordOrder;
      EXIT WHEN c_words%NOTFOUND;
    
      UPDATE TBL_DICT_CUSTOMWORD
         SET col_wordorder = v_WordOrder
       WHERE col_id = v_Id;
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode    := 103;
      v_errormessage := SUBSTR(SQLERRM, 1, 200);
  END;

  <<error_exception>>
  BEGIN
    :errorCode    := v_errorcode;
    :errorMessage := v_errormessage;
  END error_exception;
END;
