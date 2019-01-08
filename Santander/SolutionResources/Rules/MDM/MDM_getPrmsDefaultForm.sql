SELECT dom.col_id AS DOM_ID,
       dom.col_name AS DOM_NAME,
       (SELECT som.col_id
          FROM tbl_som_config som
         WHERE som.col_som_configfom_object = fom.col_id
           AND rownum = 1) AS SOM_ID,
       dom.COL_ISROOT AS ISROOT,
       (SELECT list_collect(CAST(COLLECT(To_char(ct.col_id) ORDER BY to_char(ct.col_id)) AS split_tbl), ', ', 1) AS ids FROM tbl_dict_casesystype ct WHERE ct.COL_CASESYSTYPEMODEL = mdm_model.col_id) CaseTypeIds
  FROM tbl_fom_object fom
 INNER JOIN tbl_dom_object dom
    ON fom.col_id = dom.col_dom_objectfom_object
 INNER JOIN tbl_dom_model dom_model
    ON dom_model.col_id = dom.COL_DOM_OBJECTDOM_MODEL
 INNER JOIN tbl_mdm_model mdm_model
    ON mdm_model.col_id = dom_model.COL_DOM_MODELMDM_MODEL
 WHERE col_apicode IN
       (SELECT to_char(regexp_substr(:BOS_APIS, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS apicode FROM dual CONNECT BY dbms_lob.getlength(regexp_substr(:BOS_APIS, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0)
