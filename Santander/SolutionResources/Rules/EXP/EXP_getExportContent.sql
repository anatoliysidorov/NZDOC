DECLARE
  v_tag          NVARCHAR2(255);
  v_caseTypeCode NVARCHAR2(255);
  v_caseTypeId   NUMBER;
  v_detailsXml   NCLOB;

BEGIN
  v_tag          := :TagExcluded;
  v_caseTypeCode := :CaseTypeCode;
  v_caseTypeId   := :CaseTypeId;
  v_detailsXml   := NULL;

  -- get CaseType Code
  IF v_caseTypeCode IS NULL AND v_caseTypeId IS NOT NULL THEN
    BEGIN
      SELECT col_code INTO v_caseTypeCode FROM tbl_dict_casesystype WHERE col_id = v_caseTypeId;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_caseTypeCode := NULL;
    END;
  END IF;

  IF (v_tag IS NOT NULL) THEN
    BEGIN
      SELECT XMLELEMENT("components", XMLAGG(XMLELEMENT("component", XMLATTRIBUTES(o.code AS "code", o.TYPE AS "type")))).getclobval()
        INTO v_detailsXml
        FROM (SELECT code, TYPE
                FROM vw_EXP_AppBaseContent
               WHERE (tag IS NULL OR UPPER(tag) != UPPER(v_tag))
                 AND UPPER(TYPE) NOT IN (N'RELATION')
              UNION ALL
              SELECT code, N'Relation' AS TYPE
                FROM @TOKEN_SYSTEMDOMAINUSER@.CONF_BORELATION
               WHERE SOURCEOBJECTID IN (SELECT ID
                                          FROM vw_EXP_AppBaseContent
                                         WHERE (tag IS NULL OR UPPER(tag) != UPPER(v_tag))
                                           AND UPPER(TYPE) IN (N'BUSINESSOBJECT'))
                 AND TARGETOBJECTID IN (SELECT ID
                                          FROM vw_EXP_AppBaseContent
                                         WHERE (tag IS NULL OR UPPER(tag) != UPPER(v_tag))
                                           AND UPPER(TYPE) IN (N'BUSINESSOBJECT'))
              UNION ALL
              SELECT fo.col_apicode AS code, N'BusinessObject' AS TYPE
                FROM tbl_fom_object fo
                LEFT JOIN tbl_dom_object do
                  ON do.col_dom_objectfom_object = fo.col_id
                LEFT JOIN tbl_dom_model dm
                  ON dm.col_id = do.col_dom_objectdom_model
                LEFT JOIN tbl_mdm_model mm
                  ON mm.col_id = dm.col_dom_modelmdm_model
                LEFT JOIN tbl_dict_casesystype dict_casetype
                  ON dict_casetype.col_casesystypemodel = mm.col_id
               WHERE UPPER(dict_casetype.col_code) = UPPER(v_caseTypeCode)
                 AND lower(do.col_type) != 'parentbusinessobject'
                 AND lower(do.col_type) != 'referenceobject'
              UNION ALL
              SELECT rs.col_apicode AS code, N'Relation' AS TYPE
                FROM tbl_fom_object fo
                LEFT JOIN tbl_fom_relationship rs
                  ON rs.col_childfom_relfom_object = fo.col_id
                LEFT JOIN tbl_dom_object do
                  ON do.col_dom_objectfom_object = fo.col_id
                LEFT JOIN tbl_dom_model dm
                  ON dm.col_id = do.col_dom_objectdom_model
                LEFT JOIN tbl_mdm_model mm
                  ON mm.col_id = dm.col_dom_modelmdm_model
                LEFT JOIN tbl_dict_casesystype dict_casetype
                  ON dict_casetype.col_casesystypemodel = mm.col_id
               WHERE UPPER(dict_casetype.col_code) = UPPER(v_caseTypeCode)
                 AND lower(do.col_type) != 'parentbusinessobject'
                 AND lower(do.col_type) != 'referenceobject') o;
    
    EXCEPTION
      WHEN OTHERS THEN
        v_detailsXml := NULL;
    END;
  END IF;
  :DetailsXml := dbms_xmlgen.CONVERT(v_detailsXml, dbms_xmlgen.ENTITY_ENCODE);
END;