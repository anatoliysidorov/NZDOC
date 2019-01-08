DECLARE
  v_result         NUMBER;
  v_allow          NUMBER;
  v_accessObjectId NUMBER;
  v_permissionCode NVARCHAR2(255);
BEGIN
  v_allow          := 0;
  v_accessObjectId := :AccessObjectId;
  v_permissionCode := :PermissionCode;

  IF v_accessObjectId IS NULL OR v_permissionCode IS NULL THEN
    RETURN v_allow;
  END IF;

  FOR rec IN (SELECT CaseworkerId FROM TABLE(f_DCM_getProxyAssignorList())) LOOP
    SELECT Allowed
      INTO v_result
      FROM TABLE(f_dcm_getCaseworkerAccessFn2(p_AccessObjectId => v_accessObjectId,
                                              p_CaseId         => NULL,
                                              p_CaseworkerId   => rec.CaseworkerId,
                                              p_PermissionId   => (SELECT col_id
                                                                     FROM tbl_ac_permission
                                                                    WHERE col_code = UPPER(v_permissionCode)
                                                                      AND col_permissionaccessobjtype =
                                                                          (SELECT col_id FROM tbl_ac_accessobjecttype WHERE col_code = 'CASE_TYPE')),
                                              p_TaskId         => NULL))
     WHERE caseworkertype = 'CASEWORKER';
    IF v_result = 1 THEN
      v_allow := 1;
      RETURN v_allow;
    END IF;
  END LOOP;

  RETURN v_allow;
END;