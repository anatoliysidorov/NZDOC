DECLARE
  v_CaseId               INTEGER;
  v_CaseTypeId           INTEGER;
  v_AvailableCaseTypeIds VARCHAR2(32767);

BEGIN
  v_CaseId     := :CaseId;
  v_CaseTypeId := F_DCM_GETCASETYPEFORCASE(v_CaseId);

  IF (v_CaseTypeId IS NOT NULL) THEN
    SELECT (LISTAGG(clt.col_caselinktmplchildcasetype, ',') WITHIN GROUP(ORDER BY clt.col_caselinktmplchildcasetype))
      INTO v_AvailableCaseTypeIds
      FROM tbl_caselinktmpl clt
      LEFT JOIN tbl_dict_casesystype ct
        ON ct.col_id = clt.col_caselinktmplchildcasetype
     WHERE clt.col_caselinktmplprntcasetype = v_CaseTypeId
       AND NVL(ct.col_isdeleted, 0) = 0
       AND f_dcm_iscasetypecreatealwms(AccessObjectId => (SELECT Id
                                                            FROM TABLE(f_dcm_getcasetypeaolist())
                                                           WHERE CaseTypeId = clt.COL_CASELINKTMPLCHILDCASETYPE)) = 1;
  END IF;

  :AvailableCaseTypeIds := v_AvailableCaseTypeIds;

END;