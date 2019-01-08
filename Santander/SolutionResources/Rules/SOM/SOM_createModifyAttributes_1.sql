DECLARE
  v_input             NCLOB;
  v_configid          NUMBER;
  v_name              NVARCHAR2(255);
  v_fomattributeid    NUMBER;
  v_pathtoparentid    NUMBER;
  v_count             INT;
  v_gridconfig        VARCHAR2(4000);
  v_searchconfig      VARCHAR2(4000);
  v_isId              NUMBER;
  v_formid            NUMBER;
  v_formidupdate      NUMBER;
  v_RenderControlId   NUMBER;
  v_RenderControlName NVARCHAR2(255);
  v_RenderControlCode NVARCHAR2(255);

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN

  v_count    := 0;
  v_input    := :XMLInput;
  v_configid := :SomConfigId;
    v_RenderControlId   := 0;
    v_RenderControlCode := NULL;
    v_RenderControlName := NULL;

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';

  -- validation on Id is Exist
  IF NVL(v_configid, 0) > 0 THEN
    v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_configid, tablename => 'TBL_SOM_CONFIG');
    IF v_errorcode > 0 THEN
      GOTO cleanup;
    END IF;
  END IF;

  :SuccessResponse := 'Attributes were updated';

  -- delete attributes
  BEGIN
    -- soft delete result attributes
    UPDATE tbl_som_resultattr d
       SET d.col_isdeleted = 1
     WHERE d.col_id IN (SELECT s.col_id
                        FROM (SELECT sr.col_id, dr.col_code
                                FROM tbl_som_resultattr sr
                               INNER JOIN tbl_dom_renderobject dr
                                  ON dr.col_id = sr.col_som_resattrrenderobject
                               WHERE sr.col_som_resultattrsom_config = v_configid
                                 AND sr.col_isrender = 1
                                 AND sr.col_som_resultattrfom_attr IS NULL
                              UNION ALL
                              SELECT col_id, col_code
                                FROM tbl_som_resultattr
                               WHERE col_som_resultattrsom_config = v_configid
                                 AND NVL(col_isrender, 0) = 0) s
                       WHERE UPPER(s.col_code) NOT IN
                             (SELECT UPPER(d.extract('/CODE/text()').getstringval()) AS Code
                                FROM TABLE(XMLSequence(XMLType(v_input).extract('/CUSTOMDATA/GRID/COLUMNS/COLUMN/CODE'))) d)
                         AND s.col_id IN (SELECT sra.col_id
                                          FROM tbl_som_resultattr sra
                                         INNER JOIN tbl_som_attribute sa
                                            ON sa.col_code = sra.col_code
                                           AND (sa.col_som_attributesom_object IN (SELECT so.col_id
                                                                                     FROM tbl_som_config sc
                                                                                    INNER JOIN tbl_som_model sm
                                                                                       ON sm.col_id = sc.col_som_configsom_model
                                                                                    INNER JOIN tbl_som_object so
                                                                                       ON so.col_som_objectsom_model = sm.col_id
                                                                                    WHERE sc.col_id = v_configid))
                                         WHERE sra.col_som_resultattrsom_config = v_configid
                                        UNION ALL
                                        SELECT sr.col_id
                                          FROM tbl_som_resultattr sr
                                         INNER JOIN tbl_dom_renderobject dr
                                            ON dr.col_id = sr.col_som_resattrrenderobject
                                         WHERE sr.col_som_resultattrsom_config = v_configid
                                           AND sr.col_isrender = 1
                                           AND sr.col_som_resultattrfom_attr IS NULL))
        OR d.col_resultattrresultattrgroup IN
           (SELECT s.col_id
              FROM (SELECT sr.col_id, dr.col_code
                      FROM tbl_som_resultattr sr
                     INNER JOIN tbl_dom_renderobject dr
                        ON dr.col_id = sr.col_som_resattrrenderobject
                     WHERE sr.col_som_resultattrsom_config = v_configid
                       AND sr.col_isrender = 1
                       AND sr.col_som_resultattrfom_attr IS NULL
                    UNION ALL
                    SELECT col_id, col_code
                      FROM tbl_som_resultattr
                     WHERE col_som_resultattrsom_config = v_configid
                       AND NVL(col_isrender, 0) = 0) s
             WHERE UPPER(s.col_code) NOT IN
                   (SELECT UPPER(d.extract('/CODE/text()').getstringval()) AS Code
                      FROM TABLE(XMLSequence(XMLType(v_input).extract('/CUSTOMDATA/GRID/COLUMNS/COLUMN/CODE'))) d)
               AND s.col_id IN (SELECT sra.col_id
                                FROM tbl_som_resultattr sra
                               INNER JOIN tbl_som_attribute sa
                                  ON sa.col_code = sra.col_code
                                 AND (sa.col_som_attributesom_object IN (SELECT so.col_id
                                                                           FROM tbl_som_config sc
                                                                          INNER JOIN tbl_som_model sm
                                                                             ON sm.col_id = sc.col_som_configsom_model
                                                                          INNER JOIN tbl_som_object so
                                                                             ON so.col_som_objectsom_model = sm.col_id
                                                                          WHERE sc.col_id = v_configid))
                               WHERE sra.col_som_resultattrsom_config = v_configid
                              UNION ALL
                              SELECT sr.col_id
                                FROM tbl_som_resultattr sr
                               INNER JOIN tbl_dom_renderobject dr
                                  ON dr.col_id = sr.col_som_resattrrenderobject
                               WHERE sr.col_som_resultattrsom_config = v_configid
                                 AND sr.col_isrender = 1
                                 AND sr.col_som_resultattrfom_attr IS NULL));
  
    -- delete search attributes
    DELETE FROM tbl_som_searchattr
     WHERE col_som_searchattrsom_config = v_configid
       AND UPPER(col_code) NOT IN
           (SELECT UPPER(d.extract('/CODE/text()').getstringval()) AS Code
              FROM TABLE(XMLSequence(XMLType(v_input).extract('/CUSTOMDATA/SEARCH/FIELDS/FIELD/CODE'))) d)
       AND col_id IN (SELECT ssa.col_id
                        FROM tbl_som_searchattr ssa
                       INNER JOIN tbl_som_attribute sa
                          ON sa.col_code = ssa.col_code
                         AND (sa.col_som_attributesom_object IN (SELECT so.col_id
                                                                   FROM tbl_som_config sc
                                                                  INNER JOIN tbl_som_model sm
                                                                     ON sm.col_id = sc.col_som_configsom_model
                                                                  INNER JOIN tbl_som_object so
                                                                     ON so.col_som_objectsom_model = sm.col_id
                                                                  WHERE sc.col_id = v_configid))
                       WHERE ssa.col_som_searchattrsom_config = v_configid);
  EXCEPTION
    WHEN OTHERS THEN
      v_errorcode      := 101;
      v_errormessage   := SUBSTR(SQLERRM, 1, 200);
      :SuccessResponse := '';
      GOTO cleanup;
  END;

  -- update result attributes
  FOR cur IN (SELECT UPPER(extractvalue(VALUE(d), ' COLUMN/CODE')) AS Code,
                     extractvalue(VALUE(d), ' COLUMN/SORDER') AS SOrder,
                     extractvalue(VALUE(d), ' COLUMN/JSONDATA') AS JsonData,
                     extractvalue(VALUE(d), ' COLUMN/ISRENDER') AS IsRender,
                     extractvalue(VALUE(d), ' COLUMN/RENDERCONTROLCODE') AS RenderControlCode
                FROM TABLE(XMLSequence(extract(XMLType(v_input), '/CUSTOMDATA/GRID/COLUMNS/COLUMN'))) d) LOOP
  
    v_RenderControlId   := 0;
    v_RenderControlCode := NULL;
    v_RenderControlName := NULL;
  
    -- check by Code
    SELECT COUNT(s.col_id)
      INTO v_count
      FROM (SELECT sr.col_id, dr.col_code
              FROM tbl_som_resultattr sr
             INNER JOIN tbl_dom_renderobject dr
                ON dr.col_id = sr.col_som_resattrrenderobject
             WHERE sr.col_som_resultattrsom_config = v_configid
               AND sr.col_isrender = 1
               AND sr.col_som_resultattrfom_attr IS NULL
            UNION ALL
            SELECT col_id, col_code
              FROM tbl_som_resultattr
             WHERE col_som_resultattrsom_config = v_configid
               AND NVL(col_isrender, 0) = 0) s
     WHERE UPPER(s.col_code) = cur.Code;
  
    IF v_count > 0 THEN
      -- get Render Control Id
      IF (cur.RenderControlCode IS NOT NULL) THEN
        v_RenderControlId := f_util_getidbycode(code => cur.RenderControlCode, tablename => 'tbl_dom_rendercontrol');
        IF (v_RenderControlId IS NOT NULL) THEN
          BEGIN
            SELECT col_name, col_code INTO v_RenderControlName, v_RenderControlCode FROM tbl_dom_rendercontrol WHERE col_id = v_RenderControlId;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
        END IF;
      ELSE
        IF (NVL(cur.IsRender, 0) = 1) THEN
          -- get Default Render Control Id
          BEGIN
            SELECT rc.col_id, rc.col_name, rc.col_code
              INTO v_RenderControlId, v_RenderControlName, v_RenderControlCode
              FROM tbl_dom_rendercontrol rc
             INNER JOIN tbl_dom_renderobject ro
                ON ro.col_id = rc.col_rendercontrolrenderobject
             WHERE UPPER(ro.col_code) = cur.Code
               AND rc.col_isdefault = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              NULL;
          END;
        END IF;
      END IF;
    
      IF (NVL(cur.IsRender, 0) = 1) THEN
        BEGIN
          -- update result attribute
          UPDATE tbl_som_resultattr d
             SET d.col_sorder                   = cur.SOrder,
                 d.col_jsondata                 = cur.JsonData,
                 d.col_som_resultattrrenderctrl = v_RenderControlId,
                 d.col_code                     = 'RC_' || v_RenderControlCode,
                 d.col_name                     = v_RenderControlName,
                 d.col_isdeleted                = 0
           WHERE d.col_id IN (SELECT s.col_id
                              FROM (SELECT sr.col_id, dr.col_code
                                      FROM tbl_som_resultattr sr
                                     INNER JOIN tbl_dom_renderobject dr
                                        ON dr.col_id = sr.col_som_resattrrenderobject
                                     WHERE sr.col_som_resultattrsom_config = v_configid
                                       AND sr.col_isrender = 1
                                       AND sr.col_som_resultattrfom_attr IS NULL
                                    UNION ALL
                                    SELECT col_id, col_code
                                      FROM tbl_som_resultattr
                                     WHERE col_som_resultattrsom_config = v_configid
                                       AND NVL(col_isrender, 0) = 0) s
                             WHERE UPPER(s.col_code) = cur.Code);
        
          -- todo - update grouped attributes -> isdeleted = 0
        
          /*              OR col_resultattrresultattrgroup IN (SELECT col_id
           FROM (SELECT sr.col_id, dr.col_code
                   FROM tbl_som_resultattr sr
                  INNER JOIN tbl_dom_renderobject dr
                     ON dr.col_id = sr.col_som_resattrrenderobject
                  WHERE sr.col_som_resultattrsom_config = v_configid
                    AND sr.col_isrender = 1
                    AND sr.col_som_resultattrfom_attr IS NULL
                 UNION ALL
                 SELECT col_id, col_code
                   FROM tbl_som_resultattr
                  WHERE col_som_resultattrsom_config = v_configid
                    AND NVL(col_isrender, 0) = 0)
          WHERE UPPER(col_code) = cur.Code);*/
          --             AND col_som_resultattrsom_config = v_configid
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            NULL;
            --            dbms_output.put_line(cur.Code || ' render');
          --            dbms_output.put_line('');
        END;
      
      ELSE
        UPDATE tbl_som_resultattr
           SET col_sorder = cur.SOrder, col_jsondata = cur.JsonData, col_isdeleted = 0
         WHERE UPPER(col_code) = cur.Code
           AND col_som_resultattrsom_config = v_configid
           AND NVL(col_isrender, 0) = 0;
      
      END IF;
    ELSE
      -- insert result attribute
      -- get data
      BEGIN
        SELECT sa.col_som_attrfom_attr, sa.col_name
          INTO v_fomattributeid, v_name
          FROM tbl_som_attribute sa
         INNER JOIN tbl_som_object so
            ON so.col_Id = sa.col_som_attributesom_object
         INNER JOIN tbl_som_config sc
            ON sc.col_som_configsom_model = so.col_som_objectsom_model
           AND sc.col_Id = v_configid
         WHERE UPPER(sa.col_code) = cur.Code;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_fomattributeid := NULL;
          v_name           := cur.Code;
      END;
    
      BEGIN
        SELECT d.col_dom_object_pathtoprntext
          INTO v_pathtoparentid
          FROM tbl_som_config sc
         INNER JOIN tbl_som_model sm
            ON sm.col_id = sc.col_som_configsom_model
         INNER JOIN tbl_dom_model dm
            ON dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
         INNER JOIN tbl_dom_object d
            ON d.col_dom_objectdom_model = dm.col_id
         INNER JOIN tbl_dom_attribute da
            ON da.col_dom_attributedom_object = d.col_id
         WHERE sc.col_id = v_configid
           AND UPPER(da.col_code) = cur.Code;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_pathtoparentid := NULL;
      END;
    
      BEGIN
        INSERT INTO tbl_som_resultattr
          (col_code,
           col_name,
           col_som_resultattrfom_attr,
           col_som_resultattrfom_path,
           col_som_resultattrsom_config,
           col_sorder,
           col_jsondata,
           col_isdeleted)
        VALUES
          (cur.Code, v_name, v_fomattributeid, v_pathtoparentid, v_configid, cur.SOrder, cur.JsonData, 0);
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          NULL;
          --          dbms_output.put_line(cur.Code);
        --          dbms_output.put_line('');
      END;
    END IF;
  END LOOP;

  -- update search attributes
  FOR cur IN (SELECT UPPER(extractvalue(VALUE(d), ' FIELD/CODE')) AS Code,
                     extractvalue(VALUE(d), ' FIELD/SORDER') AS SOrder,
                     extractvalue(VALUE(d), ' FIELD/JSONDATA') AS JsonData,
                     extractvalue(VALUE(d), ' FIELD/CASEINSENSITIVE') AS CaseInSensitive,
                     extractvalue(VALUE(d), ' FIELD/ISLIKE') AS IsLike
                FROM TABLE(XMLSequence(extract(XMLType(v_input), '/CUSTOMDATA/SEARCH/FIELDS/FIELD'))) d) LOOP
  
    -- check on Code
    SELECT COUNT(col_id)
      INTO v_count
      FROM tbl_som_searchattr
     WHERE UPPER(col_code) = cur.Code
       AND col_som_searchattrsom_config = v_configid;
  
    IF v_count > 0 THEN
      -- update search attribute
      UPDATE tbl_som_searchattr
         SET col_sorder = cur.SOrder, col_jsondata = cur.JsonData
       WHERE UPPER(col_code) = cur.Code
         AND col_som_searchattrsom_config = v_configid;
    ELSE
      -- insert search attribute
      -- get data
      BEGIN
        SELECT sa.col_som_attrfom_attr, sa.col_name
          INTO v_fomattributeid, v_name
          FROM tbl_som_attribute sa
         INNER JOIN tbl_som_object so
            ON so.col_Id = sa.col_som_attributesom_object
         INNER JOIN tbl_som_config sc
            ON sc.col_som_configsom_model = so.col_som_objectsom_model
           AND sc.col_Id = v_configid
         WHERE UPPER(sa.col_code) = cur.Code;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_fomattributeid := NULL;
          v_name           := cur.Code;
      END;
    
      BEGIN
        SELECT d.col_dom_object_pathtoprntext
          INTO v_pathtoparentid
          FROM tbl_som_config sc
         INNER JOIN tbl_som_model sm
            ON sm.col_id = sc.col_som_configsom_model
         INNER JOIN tbl_dom_model dm
            ON dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
         INNER JOIN tbl_dom_object d
            ON d.col_dom_objectdom_model = dm.col_id
         INNER JOIN tbl_dom_attribute da
            ON da.col_dom_attributedom_object = d.col_id
         WHERE sc.col_id = v_configid
           AND UPPER(da.col_code) = cur.Code;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_pathtoparentid := NULL;
      END;
    
      INSERT INTO tbl_som_searchattr
        (col_code,
         col_name,
         col_som_searchattrfom_attr,
         col_som_searchattrfom_path,
         col_som_searchattrsom_config,
         col_sorder,
         col_iscaseincensitive,
         col_islike,
         col_jsondata)
      VALUES
        (cur.Code, v_name, v_fomattributeid, v_pathtoparentid, v_configid, cur.SOrder, cur.CaseInSensitive, cur.IsLike, cur.JsonData);
    END IF;
  END LOOP;

  -- update general configs
  BEGIN
  
    SELECT extractvalue(xmltype(v_input), 'CUSTOMDATA/GRID/SETTINGS') INTO v_gridconfig FROM dual;
  
    SELECT extractvalue(xmltype(v_input), 'CUSTOMDATA/SEARCH/SETTINGS') INTO v_searchconfig FROM dual;
  
    UPDATE tbl_som_config
       SET col_gridconfig   = v_gridconfig,
           col_searchconfig = v_searchconfig,
           col_srchqry      = NULL,
           col_fromqry      = NULL,
           col_xmlfromqry   = NULL,
           col_whereqry     = NULL
     WHERE col_id = v_configid;
  EXCEPTION
    WHEN OTHERS THEN
      :SuccessResponse := '';
  END;

  -- update relation to form
  BEGIN
    v_count := 0;
    SELECT d.extract('/FORMID/text()').getnumberval() INTO v_formid FROM TABLE(XMLSequence(XMLType(v_input).extract('/CUSTOMDATA/FORMID'))) d;
  
    IF v_formid IS NOT NULL THEN
      SELECT COUNT(col_id)
        INTO v_count
        FROM tbl_mdm_searchpage
       WHERE col_searchpagesom_config = v_configid
         AND col_formmode = 'CREATE';
      IF v_count > 0 THEN
        UPDATE tbl_mdm_searchpage
           SET col_searchpagemdm_form = v_formid
         WHERE col_searchpagesom_config = v_configid
           AND col_formmode = 'CREATE';
      ELSE
        INSERT INTO tbl_mdm_searchpage (col_searchpagemdm_form, col_searchpagesom_config, col_formmode) VALUES (v_formid, v_configid, 'CREATE');
      END IF;
    ELSE
      DELETE FROM tbl_mdm_searchpage
       WHERE col_searchpagesom_config = v_configid
         AND col_formmode = 'CREATE';
    END IF;
  
    v_count := 0;
    SELECT d.extract('/FORMIDUPDATE/text()').getnumberval()
      INTO v_formidupdate
      FROM TABLE(XMLSequence(XMLType(v_input).extract('/CUSTOMDATA/FORMIDUPDATE'))) d;
  
    IF v_formidupdate IS NOT NULL THEN
      SELECT COUNT(col_id)
        INTO v_count
        FROM tbl_mdm_searchpage
       WHERE col_searchpagesom_config = v_configid
         AND col_formmode = 'UPDATE';
      IF v_count > 0 THEN
        UPDATE tbl_mdm_searchpage
           SET col_searchpagemdm_form = v_formidupdate
         WHERE col_searchpagesom_config = v_configid
           AND col_formmode = 'UPDATE';
      ELSE
        INSERT INTO tbl_mdm_searchpage
          (col_searchpagemdm_form, col_searchpagesom_config, col_formmode)
        VALUES
          (v_formidupdate, v_configid, 'UPDATE');
      END IF;
    ELSE
      DELETE FROM tbl_mdm_searchpage
       WHERE col_searchpagesom_config = v_configid
         AND col_formmode = 'UPDATE';
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
