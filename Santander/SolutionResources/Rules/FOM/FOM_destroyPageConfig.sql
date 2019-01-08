DECLARE
  v_id          NUMBER;
  v_description NCLOB;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN
  v_id := :Id;

  v_errorcode    := 0;
  v_errormessage := '';

  --Input params check
  IF v_id IS NULL THEN
    v_errormessage := 'Id can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;

  -- delete from ac_acl
  DELETE FROM tbl_ac_acl WHERE col_aclaccessobject IN (SELECT col_id FROM tbl_ac_accessobject WHERE col_accessobjectuielement IN (SELECT col_id FROM tbl_fom_uielement WHERE col_parentid = v_id));
  DELETE FROM tbl_ac_acl WHERE col_aclaccessobject = (SELECT col_id FROM tbl_ac_accessobject WHERE col_accessobjectuielement = v_id);

  -- delete from ac_accessobject
  DELETE FROM tbl_ac_accessobject WHERE col_accessobjectuielement IN (SELECT col_id FROM tbl_fom_uielement WHERE col_parentid = v_id);
  DELETE FROM tbl_ac_accessobject WHERE col_accessobjectuielement = v_id;

  -- delete relations between UI elements and DOM Attributes
  DELETE FROM TBL_UIELEMENT_DOM_ATTRIBUTE WHERE COL_FOM_UIELEMENT_ID IN (SELECT uie.COL_ID FROM TBL_FOM_UIELEMENT uie WHERE uie.col_parentid = v_id);
  DELETE FROM TBL_UIELEMENT_DOM_ATTRIBUTE WHERE COL_FOM_UIELEMENT_ID IN (SELECT uie.COL_ID FROM TBL_FOM_UIELEMENT uie WHERE uie.col_id = v_id);

  -- update Modified By/Date for tbl_FOM_Page
  SELECT col_description INTO v_description FROM tbl_fom_page WHERE col_id = (SELECT col_uielementpage FROM tbl_fom_uielement WHERE col_id = v_id);
  UPDATE tbl_fom_page SET col_description = v_description WHERE col_id = (SELECT col_uielementpage FROM tbl_fom_uielement WHERE col_id = v_id);

  -- delete from fom_pageconfig
  DELETE tbl_fom_uielement WHERE col_parentid = v_id;
  DELETE tbl_fom_uielement WHERE col_id = v_id;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
