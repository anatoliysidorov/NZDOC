SELECT v.*, v.TARGET_RAWTYPE || '-' || v.TARGET_ELEMENTID AS TARGET_CALCID
  FROM (SELECT ap.col_id AS ID,
               ap.col_id AS COL_ID,
               ap.col_isdeleted AS IsDeleted,
               ap.col_order AS ShowOrder,
               ap.col_title AS Title,
               ap.col_description AS Description,
               ap.col_pageparams AS PageParams,
               ap.col_assocpagedict_doctype AS DocType,
               ap.col_createdby AS CreatedBy,
               ap.col_createddate AS CreatedDate,
               ap.col_modifiedby AS ModifiedBy,
               ap.col_modifieddate AS ModifiedDate,
               --page reference
               CASE
                  WHEN NVL(ap.col_assocpageform, 0) > 0 THEN FORM.col_name
                  WHEN NVL(ap.COL_ASSOCPAGECODEDPAGE, 0) > 0 THEN CODEDPAGE.col_name
                  WHEN NVL(ap.COL_ASSOCPAGEPAGE, 0) > 0 THEN PAGE.col_name
                  WHEN ap.col_pagecode IS NOT NULL THEN dp.NAME
               END
                  AS TARGET_NAME,
               CASE
                  WHEN NVL(ap.col_assocpageform, 0) > 0 THEN FORM.col_code
                  WHEN NVL(ap.COL_ASSOCPAGECODEDPAGE, 0) > 0 THEN CODEDPAGE.col_code
                  WHEN NVL(ap.COL_ASSOCPAGEPAGE, 0) > 0 THEN PAGE.col_code
                  WHEN ap.col_pagecode IS NOT NULL THEN dp.NAME
               END
                  AS TARGET_CODE,
               CASE
                  WHEN NVL(ap.col_assocpageform, 0) > 0 THEN 'FORM'
                  WHEN NVL(ap.COL_ASSOCPAGECODEDPAGE, 0) > 0 THEN 'CODED_PAGE'
                  WHEN NVL(ap.COL_ASSOCPAGEPAGE, 0) > 0 THEN 'PAGE'
                  WHEN ap.col_pagecode IS NOT NULL THEN 'APPBASE_PAGE'
               END
                  AS TARGET_RAWTYPE,
               CASE
                  WHEN NVL(ap.col_assocpageform, 0) > 0 THEN CAST(ap.col_assocpageform AS VARCHAR2(255))
                  WHEN NVL(ap.COL_ASSOCPAGECODEDPAGE, 0) > 0 THEN CAST(ap.COL_ASSOCPAGECODEDPAGE AS VARCHAR2(255))
                  WHEN NVL(ap.COL_ASSOCPAGEPAGE, 0) > 0 THEN CAST(ap.COL_ASSOCPAGEPAGE AS VARCHAR2(255))
                  WHEN ap.col_pagecode IS NOT NULL THEN CAST(ap.col_pagecode AS VARCHAR2(255))
               END
                  AS TARGET_ELEMENTID,
               CASE
                  WHEN NVL(ap.col_assocpageform, 0) > 0 THEN dbms_xmlgen.CONVERT(FORM.COL_FORMMARKUP)
                  WHEN NVL(ap.COL_ASSOCPAGECODEDPAGE, 0) > 0 THEN dbms_xmlgen.CONVERT(CODEDPAGE.COL_PAGEMARKUP)
               END
                  AS TARGET_BODY,
               --assoc page type
               apt.col_id AS PAGETYPE,
               NVL(apt.col_name, 'Unknown Page Type') AS PAGETYPE_NAME,
               NVL(apt.col_code, '_UNKNOWN_') AS PAGETYPE_CODE,
               --associated with
               ap.col_assocpagedict_casesystype AS CASESYSTYPE,
               ap.col_assocpagedict_tasksystype AS TASKSYSTYPE,
               ap.col_assocpagetasktemplate AS TASKTEMPLATE,
               ap.col_partytypeassocpage AS PARTYTYPE,
               ap.COL_ASSOCPAGEMDM_FORM AS MDM_FORM,
               ap.COL_DICT_WATYPEASSOCPAGE AS WORKACTIVITYTYPE
          FROM tbl_assocpage ap
               LEFT JOIN tbl_dict_assocpagetype apt
                  ON ap.col_assocpageassocpagetype = apt.col_id
               LEFT JOIN tbl_fom_form FORM
                  ON ap.col_assocpageform = FORM.col_id
               LEFT JOIN tbl_fom_page PAGE
                  ON ap.col_assocpagepage = PAGE.col_id
               LEFT JOIN tbl_fom_codedpage CODEDPAGE
                  ON ap.COL_ASSOCPAGECODEDPAGE = CODEDPAGE.col_id
               LEFT JOIN vw_util_deployedpage dp
                  ON dp.code = ap.col_pagecode) v