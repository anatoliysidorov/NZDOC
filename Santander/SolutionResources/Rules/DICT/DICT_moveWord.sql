DECLARE
   v_id             INTEGER;
   v_direction      NVARCHAR2(10);
   v_oldOrder       INTEGER;
   v_newOrder       INTEGER;
   v_count          INTEGER;
   v_max            INTEGER;
   v_min            INTEGER;
   v_categoryId     NUMBER;

   v_errorcode      INTEGER;
   v_errormessage   NVARCHAR2(255);
BEGIN
   v_id := :Id;
   v_direction := :Direction;
   v_errorcode := 0;
   v_errormessage := '';

   -- Validations
   BEGIN
      IF (v_id IS NULL)
      THEN
         v_errorcode := 101;
         v_errormessage := 'Id cannot be empty.';
         GOTO error_exception;
      END IF;

      IF (v_direction IS NULL)
      THEN
         v_errorcode := 102;
         v_errormessage := 'Direction cannot be empty.';
         GOTO error_exception;
      END IF;

      SELECT COUNT(col_id)
        INTO v_count
        FROM TBL_DICT_CUSTOMWORD
       WHERE col_id = v_id;

      IF (v_count = 0)
      THEN
         v_errorcode := 103;
         v_errormessage := 'Cannot find Word with Id: ' || TO_CHAR(v_id);
         GOTO error_exception;
      END IF;

      IF (v_direction <> '+1' AND v_direction <> '-1')
      THEN
         v_errorcode := 104;
         v_errormessage := 'Wrong Direction value: "' || v_direction || '".';
         GOTO error_exception;
      END IF;

      -- Get and check CategoryId
      SELECT col_wordcategory
        INTO v_categoryId
        FROM TBL_DICT_CUSTOMWORD
       WHERE col_id = v_id;

      SELECT COUNT(col_id)
        INTO v_count
        FROM TBL_DICT_CUSTOMCATEGORY
       WHERE col_id = v_categoryId;

      IF (v_count = 0)
      THEN
         v_errorcode := 105;
         v_errormessage := 'Cannot find Category with Id: ' || TO_CHAR(v_categoryId);
         GOTO error_exception;
      END IF;
   END;

   SELECT NVL(col_wordorder, 0)
     INTO v_oldOrder
     FROM TBL_DICT_CUSTOMWORD
    WHERE col_id = v_id;

   SELECT MAX(NVL(col_wordorder, 0))                                                                                     --, MIN(NVL(col_wordorder,0))
     INTO v_max                                                                                                                              --, v_min
     FROM TBL_DICT_CUSTOMWORD
    WHERE col_wordcategory = v_categoryId;

   v_min := 1;
   IF (NOT ((v_oldOrder = v_max AND v_direction = '+1') OR (v_oldOrder = v_min AND v_direction = '-1')))
   THEN
      IF (v_direction = '+1')
      THEN
         v_newOrder := v_oldOrder + 1;
      ELSE
         v_newOrder := v_oldOrder - 1;
      END IF;

      SELECT COUNT(col_id)
        INTO v_count
        FROM TBL_DICT_CUSTOMWORD
       WHERE NVL(col_wordorder, 0) = v_newOrder AND col_wordcategory = v_categoryId;

      IF (v_count > 0)
      THEN
         UPDATE TBL_DICT_CUSTOMWORD
            SET col_wordorder = v_oldOrder
          WHERE NVL(col_wordorder, 0) = v_newOrder AND col_wordcategory = v_categoryId;
      END IF;

      UPDATE TBL_DICT_CUSTOMWORD
         SET col_wordorder = v_newOrder
       WHERE col_id = v_id;
   END IF;

  <<error_exception>>
   BEGIN
      :errorCode := v_errorcode;
      :errorMessage := v_errormessage;
   END error_exception;
END;