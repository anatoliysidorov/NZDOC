SELECT cc.CatId,
       cc.CatCode,
       cc.CatName,
       cc.PriorCatId,
       cc.PriorCatCode,
       cc.PriorCatName,
       cc.RootLevel,
       cc.Path,
       cc.CatRoot,
       cw.col_id        AS ID,
       cw.col_code      AS CODE,
       cw.col_name      AS NAME,
       cw.col_isDeleted AS ISDELETED
  FROM (WITH QSTR AS (SELECT :CategoryPath AS STR FROM DUAL), CL AS (SELECT TRIM(regexp_substr((SELECT STR FROM QSTR), '[^/]+', 1, LEVEL)) AS CAT
                                                                       FROM dual
                                                                     CONNECT BY LEVEL <= length((SELECT STR FROM QSTR)) - length(REPLACE((SELECT STR FROM QSTR), '/', '')) + 1)
         SELECT cc.col_id AS CatId,
                cc.col_code AS CatCode,
                cc.col_name AS CatName,
                PRIOR cc.col_id AS PriorCatId,
                PRIOR cc.col_code AS PriorCatCode,
                PRIOR cc.col_name AS PriorCatName,
                SYS_CONNECT_BY_PATH(cc.col_code, '/') AS Path,
                CONNECT_BY_ROOT cc.col_code AS CatRoot,
                LEVEL AS RootLevel
           FROM tbl_dict_customcategory cc
          START WITH cc.col_code IN (SELECT CAT FROM CL)
         CONNECT BY PRIOR cc.col_id = cc.col_categorycategory) cc
          INNER JOIN tbl_dict_customword cw
             ON cw.col_wordcategory = cc.CatId
<%=IFNOTNULL("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>