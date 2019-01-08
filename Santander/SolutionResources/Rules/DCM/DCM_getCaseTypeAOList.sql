SELECT ao.col_id AS Id,
    ao.col_id AS AccessObjectId,
    ao.col_code AS AccessObjectCode,
    cst.col_id AS CaseTypeId,
    cst.col_code AS CaseTypeCode,
    aot.col_id AS AccessObjectTypeId,
    aot.col_code AS AccessObjectTypeCode
FROM tbl_ac_accessobject ao
    INNER JOIN tbl_dict_casesystype cst    ON ao.col_accessobjectcasesystype = cst.col_id
    INNER JOIN tbl_ac_accessobjecttype aot ON ao.col_accessobjaccessobjtype = aot.col_id
WHERE lower(aot.col_code) = 'case_type'
ORDER BY
    ao.col_id