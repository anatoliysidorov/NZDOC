DECLARE
  v_stateConfig INTEGER;
  v_res         INTEGER;
BEGIN

  :ErrorCode    := 0;
  :ErrorMessage := '';
  v_stateConfig := :STATECONFIG;

  IF (v_stateConfig IS NULL) THEN
    :ErrorCode    := 101;
    :ErrorMessage := 'State Config is required';
    RETURN 0;
  END IF;

  -- validation if record is not exist
  IF NVL(v_stateconfig, 0) > 0 THEN
    v_res := f_UTIL_getId(errorcode => :ErrorCode, errormessage => :ErrorMessage, id => v_stateconfig, tablename => 'tbl_DICT_StateConfig');
    IF :ErrorCode > 0 THEN
      RETURN 0;
    END IF;
  END IF;

  FOR rec IN (SELECT col_Id AS ID FROM tbl_dict_CaseState WHERE COL_STATECONFIGCASESTATE = v_stateConfig) LOOP
    -- Clean Case State
    DELETE FROM tbl_dict_csest_dtevtp WHERE col_csest_dtevtpcasestate = rec.ID;
    DELETE FROM tbl_dict_casestatesetup WHERE col_CaseStateSetupCaseState = rec.ID;
    DELETE FROM TBL_AC_ACCESSOBJECT WHERE COL_ACCESSOBJECTCASESTATE = rec.ID;
  
    -- Clean Case Transition
    DELETE FROM TBL_AC_ACCESSOBJECT
     WHERE COL_ACCESSOBJCASETRANSITION IN (SELECT col_Id
                                             FROM tbl_DICT_CaseTransition
                                            WHERE COL_SOURCECASETRANSCASESTATE = rec.ID
                                               OR COL_TARGETCASETRANSCASESTATE = rec.ID);
  
    DELETE FROM tbl_DICT_CaseTransition
     WHERE COL_SOURCECASETRANSCASESTATE = rec.ID
        OR COL_TARGETCASETRANSCASESTATE = rec.ID;
  
    -- Delete Case State record
    DELETE FROM tbl_dict_CaseState WHERE col_id = rec.ID;
  
  END LOOP;

END;