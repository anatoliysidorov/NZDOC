DECLARE
  v_errorCode    NUMERIC;
  v_errorMessage NVARCHAR2(255);

  v_CaseDependencyId NUMERIC;

BEGIN
  v_errorCode    := 0;
  v_errorMessage := '';

  v_CaseDependencyId := :Id;

  -- delete Auto Rule Parameters
  BEGIN
    DELETE FROM TBL_AUTORULEPARAMETER
     WHERE COL_AUTORULEPARAMCASEDEP = v_CaseDependencyId;
  EXCEPTION
    WHEN OTHERS THEN
      v_errorCode    := 100;
      v_errorMessage := Substr(SQLERRM, 1, 200);
      GOTO cleanup;
  END;

  -- delete Case Dependency
  BEGIN
    DELETE FROM TBL_CASEDEPENDENCY WHERE COL_ID = v_CaseDependencyId;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_errorCode    := 1;
      v_errorMessage := 'Error during deleting Case Dependency';
      GOTO cleanup;
    WHEN OTHERS THEN
      v_errorCode    := 100;
      v_errorMessage := Substr(SQLERRM, 1, 200);
      GOTO cleanup;
  END;

  <<cleanup>>
  :errorMessage := v_errorMessage;
  :errorCode    := v_errorCode;
END;