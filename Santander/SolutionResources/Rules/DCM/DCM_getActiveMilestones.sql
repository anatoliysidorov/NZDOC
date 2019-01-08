SELECT 1 AS StateConfigVersion,
       subQ.Name,
       subQ.CommonCode,
       subQ.StateConfigName,
       --CASE TYPE
       subQ.CaseSysType_Id,
       ct2.COL_NAME AS CaseSysType_Name,
       ct2.COL_CODE AS CaseSysType_Code,
       ct2.COL_ICONCODE AS CaseSysType_IconCode,
       ct2.COL_COLORCODE AS CaseSysType_ColorCode,
       ct2.COL_NAME || ' - ' || subQ.Name AS CalcName,
       (SELECT Listagg(TO_CHAR(s2.col_id), ',') WITHIN GROUP(ORDER BY s2.COL_ID)
          FROM TBL_DICT_STATE s2
          LEFT OUTER JOIN TBL_DICT_STATECONFIG sc2
            ON s2.COL_STATESTATECONFIG = sc2.COL_ID
         WHERE s2.COL_COMMONCODE = subQ.CommonCode
           AND sc2.COL_CASESYSTYPESTATECONFIG = subQ.CaseSysType_Id) AS IDs
  FROM --core query begin
        (SELECT DISTINCT sc.COL_NAME                   AS StateConfigName,
                         s.COL_COMMONCODE              AS CommonCode,
                         s.COL_NAME                    AS NAME,
                         sc.COL_CASESYSTYPESTATECONFIG AS CaseSysType_Id
           FROM TBL_DICT_STATECONFIG sc
           LEFT OUTER JOIN TBL_DICT_STATE s
             ON s.COL_STATESTATECONFIG = sc.COL_ID
           LEFT OUTER JOIN TBL_DICT_CASESYSTYPE ct
             ON sc.COL_CASESYSTYPESTATECONFIG = ct.COL_ID
          WHERE NVL(sc.COL_ISDEFAULT, 0) = 0
            AND NVL(sc.COL_CASESYSTYPESTATECONFIG, 0) <> 0
            AND (NVL(:isPortal, 0) <> 1 OR (NVL(:isPortal, 0) = 1 AND NVL(ct.COL_SHOWINPORTAL, 0) = 1))
            AND (:CaseSysTypeIds IS NULL OR ct.COL_ID IN (SELECT to_number(regexp_substr(:CaseSysTypeIds, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS id
                                                            FROM dual
                                                          CONNECT BY dbms_lob.getlength(regexp_substr(:CaseSysTypeIds, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0))
            AND (:PSEARCH IS NULL OR (LOWER(ct.COL_NAME) LIKE '%' || LOWER(:PSEARCH) || '%' OR LOWER(s.COL_NAME) LIKE LOWER('%' || lower(:PSEARCH) || '%')))) subQ
--core query end
  LEFT OUTER JOIN TBL_DICT_CASESYSTYPE ct2
    ON subQ.CaseSysType_Id = ct2.COL_ID
 ORDER BY ct2.COL_NAME || ' - ' || subQ.Name