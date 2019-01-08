DECLARE
  v_id          INTEGER;
  v_direction   NVARCHAR2(10);
  v_oldOrder    INTEGER;
  v_newOrder    INTEGER;
  v_count       INTEGER;
  v_max         INTEGER;
  v_min         INTEGER;

  v_ErrorCode     NUMBER;
  v_ErrorMessage  NVARCHAR2(255);
BEGIN
  v_id := :ID;
  v_direction := :Direction;
  v_ErrorCode := 0;
  v_ErrorMessage := '';

  /*   Validation   */
  BEGIN
    IF(v_id IS NULL)THEN
      v_ErrorCode   := 101;
      v_ErrorMessage  := 'Id cannot be empty.';
      GOTO ErrorException;
    END IF;

    IF(v_direction IS NULL)THEN
      v_ErrorCode   := 102;
      v_ErrorMessage  := 'Direction cannot be empty.';
      GOTO ErrorException;
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM TBL_SOM_RESULTATTR
    WHERE COL_ID = v_id;

    IF(v_count = 0)THEN
      v_ErrorCode   := 103;
      v_ErrorMessage  := 'Cannot find SearchAttribute with Id: ' || v_id;
      GOTO ErrorException;
    END IF;

    IF(v_direction <> '+1' AND v_direction <> '-1')THEN
      v_ErrorCode   := 104;
      v_ErrorMessage  := 'Wrong Direction value: "' || v_direction || '".';
      GOTO ErrorException;
    END IF;
  END;

  SELECT COL_SORDER
  INTO v_oldOrder
  FROM TBL_SOM_RESULTATTR
  WHERE COL_ID = v_id;

  SELECT MAX(COL_SORDER), MIN(COL_SORDER)
  INTO v_max, v_min
  FROM TBL_SOM_RESULTATTR
  WHERE COL_SOM_RESULTATTRSOM_CONFIG = (SELECT COL_SOM_RESULTATTRSOM_CONFIG
    FROM TBL_SOM_RESULTATTR
    WHERE COL_ID = v_id);

  v_min := 1;
  IF(NOT((v_oldOrder = v_max AND v_direction = '+1')OR(v_oldOrder = v_min AND v_direction = '-1'))) THEN
    IF(v_direction = '+1')THEN
      v_newOrder := v_oldOrder + 1;
    ELSE
      v_newOrder := v_oldOrder - 1;
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM TBL_SOM_RESULTATTR
    WHERE COL_SORDER = v_newOrder
      AND COL_SOM_RESULTATTRSOM_CONFIG = (SELECT COL_SOM_RESULTATTRSOM_CONFIG
      FROM TBL_SOM_RESULTATTR
      WHERE COL_ID = v_id);

    IF(v_count>0)THEN
      UPDATE TBL_SOM_RESULTATTR
      SET COL_SORDER = v_oldOrder
      WHERE COL_SORDER = v_newOrder
        AND COL_SOM_RESULTATTRSOM_CONFIG = (SELECT COL_SOM_RESULTATTRSOM_CONFIG
        FROM TBL_SOM_RESULTATTR
        WHERE COL_ID = v_id);
    END IF;

    UPDATE TBL_SOM_RESULTATTR
    SET COL_SORDER = v_newOrder
    WHERE COL_ID = v_id;
  END IF;

  <<ErrorException>>
  BEGIN
    :ErrorCode    := v_ErrorCode;
    :ErrorMessage := v_ErrorMessage;
  END ErrorException;
END;