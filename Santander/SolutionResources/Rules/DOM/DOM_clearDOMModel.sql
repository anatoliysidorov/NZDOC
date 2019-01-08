DECLARE
  v_modelid   INTEGER;
  v_deleteFOM INTEGER;
BEGIN
  v_modelid   := :ModelId;
  v_deleteFOM := :DeleteFOM;
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------------------------------------------------------------------------------------------
  IF v_deleteFOM = 1 THEN

    FOR rec IN (SELECT fo.col_id AS id
                  FROM tbl_fom_object fo
                  LEFT JOIN tbl_dom_object do
                    ON do.col_dom_objectfom_object = fo.col_id
                  LEFT JOIN tbl_dom_model dm
                    ON dm.col_id = do.col_dom_objectdom_model
                  LEFT JOIN tbl_mdm_model mm
                    ON mm.col_id = dm.col_dom_modelmdm_model
                 WHERE mm.col_id = v_modelid
                   AND lower(do.col_type) != 'parentbusinessobject'
                   AND lower(do.col_type) != 'referenceobject') LOOP

      DELETE FROM tbl_fom_attribute WHERE col_fom_attributefom_object = rec.id;

      DELETE FROM tbl_fom_path
       WHERE col_fom_pathfom_relationship IN (SELECT col_id FROM tbl_fom_relationship WHERE col_childfom_relfom_object = rec.id);

      DELETE FROM tbl_fom_relationship WHERE col_childfom_relfom_object = rec.id;

      DELETE FROM tbl_fom_object WHERE col_id = rec.id;

    END LOOP;
  END IF;

  DELETE FROM tbl_uielement_dom_attribute
   WHERE col_fom_uielement_id IN (SELECT uie.col_id
                                    FROM tbl_fom_uielement uie
                                   INNER JOIN tbl_mdm_form f
                                      ON uie.col_uielementform = f.col_id
                                   INNER JOIN tbl_dom_object o
                                      ON f.col_mdm_formdom_object = o.col_id
                                   INNER JOIN tbl_dom_model m
                                      ON o.col_dom_objectdom_model = m.col_id
                                   INNER JOIN tbl_mdm_model mm
                                      ON m.col_dom_modelmdm_model = mm.col_id
                                   WHERE mm.col_id = v_modelid);

  DELETE FROM tbl_fom_uielement
   WHERE col_uielementform IN (SELECT f.col_id
                                 FROM tbl_mdm_form f
                                INNER JOIN tbl_dom_object o
                                   ON f.col_mdm_formdom_object = o.col_id
                                INNER JOIN tbl_dom_model m
                                   ON o.col_dom_objectdom_model = m.col_id
                                INNER JOIN tbl_mdm_model mm
                                   ON m.col_dom_modelmdm_model = mm.col_id
                                WHERE mm.col_id = v_modelid);

  -- delete assoc pages (selected forms on the Custom Pages in the Case Type)
  DELETE FROM tbl_assocpage
   WHERE COL_ASSOCPAGEMDM_FORM IN (SELECT mf.col_id
                                     FROM tbl_mdm_form mf
                                     LEFT JOIN tbl_dom_object o
                                       ON mf.col_mdm_formdom_object = o.col_id
                                    INNER JOIN tbl_dom_model m
                                       ON o.col_dom_objectdom_model = m.col_id
                                    INNER JOIN tbl_mdm_model mm
                                       ON m.col_dom_modelmdm_model = mm.col_id
                                    WHERE mm.col_id = v_modelid);

  -- delete MDMs form
  DELETE FROM tbl_mdm_form
   WHERE col_mdm_formdom_object IN (SELECT o.col_id
                                      FROM tbl_dom_object o
                                     INNER JOIN tbl_dom_model m
                                        ON o.col_dom_objectdom_model = m.col_id
                                     INNER JOIN tbl_mdm_model mm
                                        ON m.col_dom_modelmdm_model = mm.col_id
                                     WHERE mm.col_id = v_modelid);

  DELETE FROM tbl_dom_relationship
   WHERE col_childdom_reldom_object IN
         (SELECT col_id
            FROM tbl_dom_object
           WHERE col_dom_objectdom_model IN (SELECT col_id FROM tbl_dom_model WHERE col_dom_modelmdm_model = v_modelid));

  DELETE FROM tbl_som_relationship
   WHERE col_childsom_relsom_object IN
         (SELECT col_id
            FROM tbl_som_object
           WHERE col_som_objectsom_model IN (SELECT col_id FROM tbl_som_model WHERE col_som_modelmdm_model = v_modelid));

  DELETE FROM tbl_dom_attribute
   WHERE col_dom_attributedom_object IN
         (SELECT col_id
            FROM tbl_dom_object
           WHERE col_dom_objectdom_model IN (SELECT col_id FROM tbl_dom_model WHERE col_dom_modelmdm_model = v_modelid));

  DELETE FROM tbl_som_attribute
   WHERE col_som_attributesom_object IN
         (SELECT col_id
            FROM tbl_som_object
           WHERE col_som_objectsom_model IN (SELECT col_id FROM tbl_som_model WHERE col_som_modelmdm_model = v_modelid));

  DELETE FROM tbl_som_object WHERE col_som_objectsom_model IN (SELECT col_id FROM tbl_som_model WHERE col_som_modelmdm_model = v_modelid);

  DELETE FROM tbl_dom_object WHERE col_dom_objectdom_model IN (SELECT col_id FROM tbl_dom_model WHERE col_dom_modelmdm_model = v_modelid);

  DELETE FROM tbl_dom_insertattr
   WHERE col_dom_insertattrdom_config IN
         (SELECT col_id
            FROM tbl_dom_config
           WHERE col_dom_configdom_model IN (SELECT col_id FROM tbl_dom_model WHERE col_dom_modelmdm_model = v_modelid));

  DELETE FROM tbl_dom_updateattr
   WHERE col_dom_updateattrdom_config IN
         (SELECT col_id
            FROM tbl_dom_config
           WHERE col_dom_configdom_model IN (SELECT col_id FROM tbl_dom_model WHERE col_dom_modelmdm_model = v_modelid));

  DELETE FROM tbl_som_resultattr
   WHERE col_som_resultattrsom_config IN
         (SELECT col_id
            FROM tbl_som_config
           WHERE col_som_configsom_model IN (SELECT col_id FROM tbl_som_model WHERE col_som_modelmdm_model = v_modelid));

  DELETE FROM tbl_som_searchattr
   WHERE col_som_searchattrsom_config IN
         (SELECT col_id
            FROM tbl_som_config
           WHERE col_som_configsom_model IN (SELECT col_id FROM tbl_som_model WHERE col_som_modelmdm_model = v_modelid));

  DELETE FROM tbl_mdm_searchpage
   WHERE col_searchpagesom_config IN
         (SELECT col_id
            FROM tbl_som_config
           WHERE col_som_configsom_model IN (SELECT col_id FROM tbl_som_model WHERE col_som_modelmdm_model = v_modelid));

  DELETE FROM tbl_dom_config WHERE col_dom_configdom_model IN (SELECT col_id FROM tbl_dom_model WHERE col_dom_modelmdm_model = v_modelid);

  DELETE FROM tbl_som_config WHERE col_som_configsom_model IN (SELECT col_id FROM tbl_som_model WHERE col_som_modelmdm_model = v_modelid);

  DELETE FROM tbl_dom_model WHERE col_dom_modelmdm_model = v_modelid;

  DELETE FROM tbl_som_model WHERE col_som_modelmdm_model = v_modelid;

  RETURN NULL;

END;