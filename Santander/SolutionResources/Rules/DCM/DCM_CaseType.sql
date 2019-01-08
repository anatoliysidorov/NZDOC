SELECT ct.col_id AS id,
       ct.col_id AS col_id,
       ct.col_code AS code,
       ct.col_colorcode AS colorcode,
       ct.col_description AS description,
       ct.col_name AS NAME,
       ct.col_isdeleted AS isdeleted,
       ct.col_isdraftmodeavail AS isdraftmodeavail,
       ct.col_showinportal AS showinportal,
       NVL (ct.col_iconcode, 'folder') iconcode,
       ct.col_casesystypeprocedure AS procedure_id,
       --PRIORITY
       DECODE (NVL (ct.col_casetypepriority, 0), 0, prty_def.priority_id, ct.col_casetypepriority) AS priority_id,
       -- Data Model
       ct.col_casesystypemodel AS model_id,
       ct.col_usedatamodel AS usedatamodel,
       r.objectid AS rootobjectid,
       r.objectcode AS rootobjectcode,
       ap.mdm_form AS createformid
  FROM tbl_dict_casesystype ct
       LEFT JOIN tbl_stp_priority prty
          ON ct.col_casetypepriority = prty.col_id
       LEFT JOIN (SELECT col_id AS priority_id
                    FROM tbl_stp_priority
                   WHERE NVL (col_isdefault, 0) = 1 AND NVL (col_isdeleted, 0) = 0) prty_def
          ON 1 = 1
       LEFT JOIN (SELECT md.col_id AS casesystypemodel, do.col_id AS objectid, do.col_code AS objectcode
                    FROM tbl_mdm_model md
                         INNER JOIN tbl_dom_model dm
                            ON dm.col_dom_modelmdm_model = md.col_id
                         INNER JOIN tbl_dom_object do
                            ON dm.col_id = do.col_dom_objectdom_model
                   WHERE UPPER (do.col_type) = 'ROOTBUSINESSOBJECT') r
          ON r.casesystypemodel = ct.col_casesystypemodel
       LEFT JOIN vw_dcm_assocpage ap
          ON ap.casesystype = ct.col_id AND UPPER (ap.pagetype_code) = 'MDM_CREATE_FORM'