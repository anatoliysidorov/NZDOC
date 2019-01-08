DECLARE
  v_Id            NUMBER;
  v_ErrorCode     NUMBER;
  v_ErrorMessage  NVARCHAR2(255);
  v_linkExist     NUMBER;
  v_result        NUMBER;
BEGIN
  v_ErrorCode := 0;
  v_ErrorMessage := '';
  :affectedRows := 0;
  :SuccessResponse := EMPTY_CLOB();
  v_Id := :ID;
  
  ---Input params check
  IF (v_Id IS NULL) THEN
    v_ErrorMessage := 'Id can not be empty';
    v_ErrorCode := 101;
    GOTO cleanup;
  END IF;

  SELECT COUNT(*)
    INTO v_linkExist
    FROM TBL_AC_ACCESSOBJECT
   WHERE COL_ACCESSOBJACCESSOBJTYPE = v_Id
     AND ROWNUM = 1;

  IF (v_linkExist > 0) THEN
    v_ErrorMessage := 'You can not delete this Access Object Type.'
                   || '<br>There are one or more Access Object records referencing this Access Object Type.'
                   || '<br>Change or remove those references and try again.';
    v_ErrorCode := 102;
    GOTO cleanup;
  ELSE
    SELECT COUNT(*)
      INTO v_linkExist
      FROM TBL_AC_PERMISSION
     WHERE COL_PERMISSIONACCESSOBJTYPE = v_Id
       AND ROWNUM = 1;

    IF (v_linkExist > 0) THEN
      v_ErrorMessage := 'You can not delete this Access Object Type.'
                     || '<br>There are one or more Permission records referencing this Access Object Type.'
                     || '<br>Change or remove those references and try again.';
      v_ErrorCode := 103;
      GOTO cleanup;
    ELSE
      DELETE TBL_AC_ACCESSOBJECTTYPE
       WHERE COL_ID = v_Id;
      :affectedRows := SQL%ROWCOUNT;
      v_result := LOC_I18N(
        MessageText => 'Deleted {{MESS_COUNT}} items',
        MessageResult => :SuccessResponse,
        MessageParams => NES_TABLE(Key_Value('MESS_COUNT', :affectedRows)));
    END IF;
  END IF;
<< cleanup >>
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode := v_ErrorCode;
END;