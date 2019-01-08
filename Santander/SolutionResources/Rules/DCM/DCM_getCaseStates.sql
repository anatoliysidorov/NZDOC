SELECT csst.col_id ID,
  csst.col_name NAME,
  csst.col_code CODE,
  Csst.Col_Activity ACTIVITY,
  NVL(Csst.COL_ISDEFAULTONCREATE,0) ISCREATE,
  NVL(Csst.COL_ISSTART,0) ISSTART,
  NVL(Csst.COL_ISASSIGN,0) ISASSIGN,
  NVL(Csst.COL_ISDEFAULTONCREATE2,0) ISINPROCESS,
  NVL(Csst.COL_ISRESOLVE,0) ISRESOLVE,
  NVL(Csst.COL_ISFINISH,0) ISFINISH,
  Csst.Col_Stateconfigcasestate STATECONFIG
FROM tbl_case cs
LEFT JOIN tbl_dict_casesystype cst
ON cst.col_id = cs.COL_CASEDICT_CASESYSTYPE
LEFT JOIN tbl_dict_casestate csst
ON NVL(cst.Col_Stateconfigcasesystype,0) = NVL(Csst.Col_Stateconfigcasestate,0)
WHERE cs.col_id                          = :CaseId