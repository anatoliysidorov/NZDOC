DECLARE
  v_Id           NUMBER;
  v_ErrorCode    NUMBER := 0;
  v_ErrorMessage NVARCHAR2(255 CHAR) := '';
BEGIN
  v_Id := :Id;
  --Input params check
  IF v_Id IS NULL
  THEN
    v_ErrorMessage := 'Id can not be empty';
    v_ErrorCode := 101;
    GOTO cleanup;
  END IF;

  -- delete from ac_acl
  /*DELETE FROM TBL_AC_ACL
    WHERE col_aclaccessobject IN (SELECT COL_ID
          FROM TBL_AC_ACCESSOBJECT
          WHERE COL_ACCESSOBJECTUIELEMENT IN (SELECT COL_ID
                FROM TBL_FOM_UIELEMENT
                WHERE COL_PARENTID = v_Id)); */
  DELETE FROM TBL_AC_ACL
    WHERE col_aclaccessobject = (SELECT COL_ID
          FROM TBL_AC_ACCESSOBJECT
          WHERE COL_ACCESSOBJECTUIELEMENT = v_Id);

  -- delete from ac_accessobject
  /*DELETE FROM TBL_AC_ACCESSOBJECT
    WHERE COL_ACCESSOBJECTUIELEMENT IN (SELECT COL_ID
          FROM TBL_FOM_UIELEMENT
          WHERE COL_PARENTID = v_Id);*/
  DELETE FROM TBL_AC_ACCESSOBJECT
    WHERE COL_ACCESSOBJECTUIELEMENT = v_Id;

  -- delete from fom_uielement
  DELETE TBL_FOM_UIELEMENT
    WHERE COL_PARENTID = v_Id;
  DELETE TBL_FOM_UIELEMENT
    WHERE COL_ID = v_Id;

<< cleanup >>
  :errorCode := v_ErrorCode;
  :errorMessage := v_ErrorMessage;
END;