DECLARE
  v_input           NCLOB;
  v_configid        NUMBER;
  v_name            NVARCHAR2(255);
  v_fomattributeid  NUMBER;
  v_pathtoparentid  NUMBER;
  v_count           INT;
  v_gridconfig      VARCHAR2(4000);
  v_searchconfig    VARCHAR2(4000);
  v_isId            NUMBER;
  v_formid          NUMBER;
  v_formidupdate    NUMBER;
  v_renderControlId NUMBER;
  v_groupResultAttrId NUMBER;
  v_SOMObjectId NUMBER;
  v_SOMObjectCode NVARCHAR2(255);
  v_SOMObjectType NVARCHAR2(255);

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN

  v_count    := 0;
  v_input    := :XMLInput;
  v_configid := :SomConfigId;

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
    UPDATE tbl_som_resultattr
       SET col_isdeleted = 1
     WHERE col_id IN (SELECT col_id
                        FROM tbl_som_resultattr
                       WHERE col_som_resultattrsom_config = v_configid
                         AND col_som_resultattrrenderattr IS NULL
                         AND UPPER(col_code) NOT IN
                             (SELECT UPPER(d.extract('/CODE/text()').getstringval()) AS Code
                                FROM TABLE(XMLSequence(XMLType(v_input).extract('/CUSTOMDATA/GRID/COLUMNS/COLUMN/CODE'))) d)
                         AND col_id IN (SELECT sra.col_id
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
                                        SELECT col_id
                                          FROM tbl_som_resultattr
                                         WHERE col_som_resultattrsom_config = v_configid
                                           AND col_som_resultattrrenderctrl IS NOT NULL));
  
    -- soft delete search attributes
    UPDATE tbl_som_searchattr
       SET col_isdeleted = 1
     WHERE col_id IN (SELECT col_id
                        FROM tbl_som_searchattr
                       WHERE col_som_searchattrsom_config = v_configid
                         AND col_som_searchattrrenderattr IS NULL
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
                                         WHERE ssa.col_som_searchattrsom_config = v_configid
                                        UNION ALL
                                        SELECT col_id
                                          FROM tbl_som_searchattr
                                         WHERE col_som_searchattrsom_config = v_configid
                                           AND col_som_searchattrrenderctrl IS NOT NULL));
  
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
                     extractvalue(VALUE(d), ' COLUMN/RENDERCONTROLCODE') AS RenderControlCode,
                     extractvalue(VALUE(d), ' COLUMN/RENDEROBJECTID') AS RenderObjectId
                FROM TABLE(XMLSequence(extract(XMLType(v_input), '/CUSTOMDATA/GRID/COLUMNS/COLUMN'))) d) LOOP
  
    v_renderControlId := NULL;
  
    -- check on Code
    SELECT COUNT(col_id)
      INTO v_count
      FROM tbl_som_resultattr
     WHERE UPPER(col_code) = cur.Code
       AND col_som_resultattrsom_config = v_configid;
       
    IF(cur.RenderObjectId IS NOT NULL) THEN
      IF (cur.RenderControlCode IS NOT NULL) THEN
        -- get Render Control Id
        v_renderControlId := f_util_getidbycode(code => cur.RenderControlCode, tablename => 'tbl_dom_rendercontrol');
      ELSE
          -- get Default Render Control Id
          BEGIN
            SELECT rc.col_id INTO v_renderControlId
            FROM tbl_dom_rendercontrol rc
            INNER JOIN tbl_dom_renderobject ro ON ro.col_id = rc.col_rendercontrolrenderobject
            WHERE ro.col_id = cur.RenderObjectId 
                  AND rc.col_isdefault = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
          END;
      END IF;
    END IF;   
  
    IF v_count > 0 THEN
      -- update result attribute
      UPDATE tbl_som_resultattr
         SET col_sorder = cur.SOrder, col_jsondata = cur.JsonData, col_isdeleted = 0, col_som_resultattrrenderctrl = v_renderControlId
       WHERE UPPER(col_code) = cur.Code
         AND col_som_resultattrsom_config = v_configid;
    ELSE

      BEGIN
        SELECT sa.col_som_attrfom_attr, sa.col_name, so.col_id, so.col_code, so.col_type
          INTO v_fomattributeid, v_name, v_SOMObjectId, v_SOMObjectCode, v_SOMObjectType
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
          v_SOMObjectId := null;
          v_SOMObjectCode := null;
      END;     

      IF(v_SOMObjectCode = 'CASE') THEN
         BEGIN
           SELECT fp.col_id into v_pathtoparentid
              FROM tbl_fom_relationship fr
              LEFT JOIN tbl_fom_path fp
              ON fp.COL_FOM_PATHFOM_RELATIONSHIP = fr.col_id
              LEFT JOIN tbl_fom_object parentObject
              ON parentObject.col_id = fr.COL_PARENTFOM_RELFOM_OBJECT
              LEFT JOIN tbl_fom_object childObject
              ON childObject.col_id       = fr.COL_CHILDFOM_RELFOM_OBJECT
              WHERE parentObject.col_code = 'CASE'
              AND childObject.col_id = (select so.col_som_objectfom_object
                                                    from tbl_som_object so
                                                    where so.col_som_objectsom_model = (SELECT sm.col_id
                                                                                      FROM tbl_som_config sc
                                                                                      INNER JOIN tbl_som_model sm ON sm.col_id = sc.col_som_configsom_model
                                                                                      WHERE sc.col_id = v_configid)
                                                         and so.col_isroot = 1);
            exception
              when NO_DATA_FOUND then
                v_pathtoparentid := null;
        END;
      ELSIF (v_SOMObjectType = 'referenceObject') THEN
         BEGIN
              -- if(cur.RenderObjectId is not null) then
              --   select d.col_dom_object_pathtoprntext into v_pathtoparentid
              --   from tbl_som_attribute sa
              --   inner join tbl_som_object so on so.col_id = sa.col_som_attributesom_object
              --   inner join tbl_som_model sm on sm.col_id = so.col_som_objectsom_model
              --   inner join tbl_dom_model dm on dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
              --   inner join tbl_dom_object d on d.col_dom_objectdom_model = dm.col_id and so.col_code = d.col_code
              --   inner join tbl_som_config sm on  sc.col_som_configsom_model = sm.col_id
              --   where sa.col_code = cur.Code
              --         and sc.col_id = v_configid;
              --   /*SELECT fp.col_id INTO v_pathtoparentid
              --   FROM tbl_fom_relationship fr
              --   LEFT JOIN tbl_fom_path fp
              --   ON fp.COL_FOM_PATHFOM_RELATIONSHIP = fr.col_id
              --   LEFT JOIN tbl_fom_object parentObject
              --   ON parentObject.col_id = fr.COL_PARENTFOM_RELFOM_OBJECT
              --   LEFT JOIN tbl_fom_object childObject
              --   ON childObject.col_id  = fr.COL_CHILDFOM_RELFOM_OBJECT
              --   WHERE childObject.col_id = (select col_som_configfom_object
              --                                             from tbl_som_config
              --                                             where col_id = v_configid)
              --   AND parentObject.col_id = (select col_renderobjectfom_object from tbl_dom_renderobject where col_id = cur.RenderObjectId);*/
              -- else 
              --   SELECT d.col_dom_object_pathtoprntext INTO v_pathtoparentid
              --   FROM tbl_som_config sc
              --   INNER JOIN tbl_som_model sm
              --   ON sm.col_id = sc.col_som_configsom_model
              --   INNER JOIN tbl_dom_model dm
              --   ON dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
              --   INNER JOIN tbl_dom_object d
              --   ON d.col_dom_objectdom_model = dm.col_id
              --   INNER JOIN tbl_dom_attribute da
              --   ON da.col_dom_attributedom_object = d.col_id
              --   WHERE sc.col_id = v_configid
              --         AND UPPER(da.col_code) = cur.Code;
              -- end if;

              select d.col_dom_object_pathtoprntext into v_pathtoparentid
              from tbl_som_attribute sa
              inner join tbl_som_object so on so.col_id = sa.col_som_attributesom_object
              inner join tbl_som_model sm on sm.col_id = so.col_som_objectsom_model
              inner join tbl_dom_model dm on dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
              inner join tbl_dom_object d on d.col_dom_objectdom_model = dm.col_id and so.col_code = d.col_code
              inner join tbl_som_config sc on sc.col_som_configsom_model = sm.col_id
              where sa.col_code = cur.Code
                    and sc.col_id = v_configid;
              
            exception
              when NO_DATA_FOUND then
                v_pathtoparentid := null;
        END;
      ELSE 
        BEGIN
            SELECT d.col_dom_object_pathtoprntext  INTO v_pathtoparentid
            FROM tbl_som_config sc
            INNER JOIN tbl_som_model sm
              ON sm.col_id = sc.col_som_configsom_model
            INNER JOIN tbl_dom_model dm
              ON dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
            INNER JOIN tbl_dom_object d
              ON d.col_dom_objectdom_model = dm.col_id and sc.col_som_configfom_object = d.col_dom_objectfom_object
            WHERE sc.col_id = v_configid;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_pathtoparentid := NULL;
        END;
      END IF;

      -- insert result attribute     
      IF(cur.RenderObjectId IS NOT NULL) THEN         
        INSERT INTO tbl_som_resultattr
        (
           col_code,
           col_name,
           col_som_resultattrfom_path,
           col_som_resultattrsom_config,
           col_sorder,
           col_jsondata,
           col_isdeleted,
           col_isrender, 
           col_som_resattrrenderobject, 
           col_som_resultattrrenderctrl
        )
        VALUES
        (  
           cur.Code, 
           v_name, 
           v_pathtoparentid, 
           v_configid, 
           cur.SOrder, 
           cur.JsonData, 
           0, 
           1, 
           cur.RenderObjectId, 
           v_renderControlId
        );
        
        select gen_tbl_som_resultattr.currval into v_groupResultAttrId from dual;
                  
        insert into tbl_som_resultattr(
              col_code,  
              col_name,
              col_som_resultattrfom_attr, 
              col_som_resultattrfom_path, 
              col_som_resultattrsom_config, 
              col_som_resattrrenderobject,
              col_resultattrresultattrgroup, 
              col_som_resultattrrenderattr, 
              col_isrender, 
              col_processorcode)
        select 
              substr(ra.col_code, 0, 15) || '_' || substr(to_char(v_groupResultAttrId) || '_' || to_char(ra.col_id), 0, 10),               
              ra.col_name, 
              (CASE WHEN ra.col_renderattrfom_attribute IS NULL THEN(select fa.col_id
                                                                    from tbl_som_attribute sa 
                                                                    inner join tbl_fom_attribute fa on fa.col_id = sa.COL_SOM_ATTRFOM_ATTR
                                                                    where  sa.COL_SOM_ATTRIBUTESOM_OBJECT = v_SOMObjectId 
                                                                           and fa.COL_FOM_ATTRIBUTEDATATYPE = ro.COL_DOM_RENDEROBJECTDATATYPE)
              ELSE ra.col_renderattrfom_attribute END),  
              v_pathtoparentid, 
              v_configid, 
              ro.col_id,
              v_groupResultAttrId,  
              ra.col_id,
              1,
              (select col_processorcode from tbl_dict_datatype where col_id = ro.col_dom_renderobjectdatatype)                    
        from tbl_dom_renderobject ro
        left join tbl_dom_renderattr ra on ra.col_renderattrrenderobject = ro.col_id
        where ro.col_id = cur.RenderObjectId;

       ELSE
                    
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
       END IF;
   
    END IF;
  END LOOP;

  -- update search attributes
  FOR cur IN (SELECT UPPER(extractvalue(VALUE(d), ' FIELD/CODE')) AS Code,
                     extractvalue(VALUE(d), ' FIELD/SORDER') AS SOrder,
                     extractvalue(VALUE(d), ' FIELD/JSONDATA') AS JsonData,
                     extractvalue(VALUE(d), ' FIELD/CASEINSENSITIVE') AS CaseInSensitive,
                     extractvalue(VALUE(d), ' FIELD/RENDEROBJECTID') AS RenderObjectId,
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
         SET col_sorder = cur.SOrder, col_jsondata = cur.JsonData, col_isdeleted = 0
       WHERE UPPER(col_code) = cur.Code
         AND col_som_searchattrsom_config = v_configid;
    ELSE
      -- insert search attribute

      BEGIN
        SELECT sa.col_som_attrfom_attr, sa.col_name, so.col_id, so.col_code, so.col_type
          INTO v_fomattributeid, v_name, v_SOMObjectId, v_SOMObjectCode, v_SOMObjectType
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
          v_SOMObjectId := null;
          v_SOMObjectCode := null;
      END;     

      IF(v_SOMObjectCode = 'CASE') THEN
         BEGIN
           SELECT fp.col_id into v_pathtoparentid
              FROM tbl_fom_relationship fr
              LEFT JOIN tbl_fom_path fp
              ON fp.COL_FOM_PATHFOM_RELATIONSHIP = fr.col_id
              LEFT JOIN tbl_fom_object parentObject
              ON parentObject.col_id = fr.COL_PARENTFOM_RELFOM_OBJECT
              LEFT JOIN tbl_fom_object childObject
              ON childObject.col_id       = fr.COL_CHILDFOM_RELFOM_OBJECT
              WHERE parentObject.col_code = 'CASE'
              AND childObject.col_id = (select so.col_som_objectfom_object
                                                    from tbl_som_object so
                                                    where so.col_som_objectsom_model = (SELECT sm.col_id
                                                                                      FROM tbl_som_config sc
                                                                                      INNER JOIN tbl_som_model sm ON sm.col_id = sc.col_som_configsom_model
                                                                                      WHERE sc.col_id = v_configid)
                                                         and so.col_isroot = 1);
            exception
              when NO_DATA_FOUND then
                v_pathtoparentid := null;
        END;
      ELSIF (v_SOMObjectType = 'referenceObject') THEN
          BEGIN
              -- if(cur.RenderObjectId is not null) then
              --   SELECT fp.col_id INTO v_pathtoparentid
              --   FROM tbl_fom_relationship fr
              --   LEFT JOIN tbl_fom_path fp
              --   ON fp.COL_FOM_PATHFOM_RELATIONSHIP = fr.col_id
              --   LEFT JOIN tbl_fom_object parentObject
              --   ON parentObject.col_id = fr.COL_PARENTFOM_RELFOM_OBJECT
              --   LEFT JOIN tbl_fom_object childObject
              --   ON childObject.col_id  = fr.COL_CHILDFOM_RELFOM_OBJECT
              --   WHERE childObject.col_id = (select col_som_configfom_object
              --                                             from tbl_som_config
              --                                             where col_id = v_configid)
              --   AND parentObject.col_id = (select col_renderobjectfom_object from tbl_dom_renderobject where col_id = cur.RenderObjectId);
              -- else 
              --   SELECT d.col_dom_object_pathtoprntext INTO v_pathtoparentid
              --   FROM tbl_som_config sc
              --   INNER JOIN tbl_som_model sm
              --   ON sm.col_id = sc.col_som_configsom_model
              --   INNER JOIN tbl_dom_model dm
              --   ON dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
              --   INNER JOIN tbl_dom_object d
              --   ON d.col_dom_objectdom_model = dm.col_id
              --   INNER JOIN tbl_dom_attribute da
              --   ON da.col_dom_attributedom_object = d.col_id
              --   WHERE sc.col_id = v_configid
              --         AND UPPER(da.col_code) = cur.Code;
              -- end if;

              select d.col_dom_object_pathtoprntext into v_pathtoparentid
              from tbl_som_attribute sa
              inner join tbl_som_object so on so.col_id = sa.col_som_attributesom_object
              inner join tbl_som_model sm on sm.col_id = so.col_som_objectsom_model
              inner join tbl_dom_model dm on dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
              inner join tbl_dom_object d on d.col_dom_objectdom_model = dm.col_id and so.col_code = d.col_code
              inner join tbl_som_config sc on sc.col_som_configsom_model = sm.col_id
              where sa.col_code = cur.Code
                    and sc.col_id = v_configid;
              
              
            exception
              when NO_DATA_FOUND then
                v_pathtoparentid := null;
        END;
      ELSE 
        BEGIN
            SELECT d.col_dom_object_pathtoprntext  INTO v_pathtoparentid
            FROM tbl_som_config sc
            INNER JOIN tbl_som_model sm
              ON sm.col_id = sc.col_som_configsom_model
            INNER JOIN tbl_dom_model dm
              ON dm.col_dom_modelmdm_model = sm.col_som_modelmdm_model
            INNER JOIN tbl_dom_object d
              ON d.col_dom_objectdom_model = dm.col_id and sc.col_som_configfom_object = d.col_dom_objectfom_object
            WHERE sc.col_id = v_configid;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_pathtoparentid := NULL;
        END;
      END IF;

      IF(cur.RenderObjectId IS NOT NULL) THEN 
        INSERT INTO tbl_som_searchattr
        (
           col_code,
           col_name,
           col_som_searchattrfom_path,
           col_som_searchattrsom_config,
           col_sorder,
           col_jsondata,
           col_isdeleted,
           col_isrender, 
           COL_SOM_SRCHATTRRENDEROBJECT
        )
        VALUES
        (  
           cur.Code, 
           v_name, 
           v_pathtoparentid, 
           v_configid, 
           cur.SOrder, 
           cur.JsonData, 
           0, 
           1, 
           cur.RenderObjectId
        );
        
        select gen_tbl_som_searchattr.currval into v_groupResultAttrId from dual;
                  
        insert into tbl_som_searchattr(
              col_code,  
              col_name,
              col_som_searchattrfom_attr, 
              col_som_searchattrfom_path, 
              col_som_searchattrsom_config, 
              COL_SOM_SRCHATTRRENDEROBJECT,
              COL_SEARCHATTRSEARCHATTRGROUP, 
              col_som_searchattrrenderattr, 
              col_isrender, 
              col_processorcode)
        select 
              substr(ra.col_code, 0, 15) || '_' ||  substr(to_char(v_groupResultAttrId) || '_' || to_char(ra.col_id), 0, 10),                 
              ra.col_name, 
              (CASE WHEN ra.col_renderattrfom_attribute IS NULL THEN(select fa.col_id
                                                                    from tbl_som_attribute sa 
                                                                    inner join tbl_fom_attribute fa on fa.col_id = sa.COL_SOM_ATTRFOM_ATTR
                                                                    where  sa.COL_SOM_ATTRIBUTESOM_OBJECT = v_SOMObjectId 
                                                                           and fa.COL_FOM_ATTRIBUTEDATATYPE = ro.COL_DOM_RENDEROBJECTDATATYPE)
              ELSE ra.col_renderattrfom_attribute END),  
              v_pathtoparentid, 
              v_configid, 
              ro.col_id,
              v_groupResultAttrId,  
              ra.col_id,
              1,
              (select col_processorcode from tbl_dict_datatype where col_id = ro.col_dom_renderobjectdatatype)                    
        from tbl_dom_renderobject ro
        left join tbl_dom_renderattr ra on ra.col_renderattrrenderobject = ro.col_id
        where ro.col_id = cur.RenderObjectId;

       ELSE
            INSERT INTO tbl_som_searchattr
              (col_code,
               col_name,
               col_som_searchattrfom_attr,
               col_som_searchattrfom_path,
               col_som_searchattrsom_config,
               col_sorder,
               col_iscaseincensitive,
               col_islike,
               col_jsondata,
               col_isdeleted)
            VALUES
              (cur.Code, v_name, v_fomattributeid, v_pathtoparentid, v_configid, cur.SOrder, cur.CaseInSensitive, cur.IsLike, cur.JsonData, 0);
       END IF;
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