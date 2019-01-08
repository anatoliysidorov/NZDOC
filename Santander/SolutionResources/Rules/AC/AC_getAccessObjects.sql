SELECT ao.COL_ID        AS ID,
    ao.COL_NAME        AS NAME,
    ao.COL_CODE        AS CODE,
    aot.col_id        AS AccessObjectType_Id,
    aot.col_name        AS AccessObjectType_Name,
    aot.col_code        AS AccessObjectType_Code,
    
    ct.col_id as CaseTransition_Id,
    ct.col_name as CaseTransition_Name,    
    cs.col_id as CaseState_Id,
    cs.col_name as CaseState_Name,    
    cst.col_id as CaseSysType_Id,
    cst.col_name as CaseSysType_Name,    
    tst.col_id as TaskSysType_Id,
    tst.col_name as TaskSysType_Name,    
    ui.col_id as UIElement_Id,
    ui.col_name as UIElement_Name,
    -----------------------------------------------------
    CASE
      WHEN lower(aot.col_code)='case_state' THEN cs.col_name || ' (' || NVL(sc.col_name, 'Default State Machine') || ')'
      WHEN lower(aot.col_code)='case_transition' THEN ct.col_name
      WHEN lower(aot.col_code)='case_type' THEN cst.col_name
      WHEN lower(aot.col_code)='case_type_case_state' THEN cs.col_name || ' (' || sc.col_name || ')' || ' for Case Type ' || cst.col_name 
      WHEN lower(aot.col_code)='task_type' THEN tst.col_name
      WHEN lower(aot.col_code)='ui_element' THEN ui.col_name
      ELSE ao.COL_NAME
    END AS CALCULATEDNAME,
    -----------------------------------------------------
    f_getNameFromAccessSubject(ao.col_createdBy) AS CreatedBy_Name,
    f_UTIL_getDrtnFrmNow(ao.col_createdDate) AS CreatedDuration,
    f_getNameFromAccessSubject(ao.col_modifiedBy) AS ModifiedBy_Name,
    f_UTIL_getDrtnFrmNow(ao.col_modifiedDate) AS ModifiedDuration
    
FROM TBL_AC_ACCESSOBJECT ao
LEFT JOIN tbl_AC_AccessObjectType aot ON (aot.col_id = ao.COL_ACCESSOBJACCESSOBJTYPE)
LEFT JOIN tbl_DICT_CaseTransition ct ON (ct.col_id = ao.COL_ACCESSOBJCASETRANSITION)
LEFT JOIN tbl_DICT_CaseState cs ON (cs.col_id = ao.COL_ACCESSOBJECTCASESTATE)
LEFT JOIN tbl_DICT_STATECONFIG sc ON (sc.col_id = cs.COL_STATECONFIGCASESTATE)
LEFT JOIN tbl_DICT_CaseSysType cst ON (cst.col_id = ao.COL_ACCESSOBJECTCASESYSTYPE)
LEFT JOIN tbl_DICT_TaskSysType tst ON (tst.col_id = ao.COL_ACCESSOBJECTTASKSYSTYPE)
LEFT JOIN tbl_FOM_UIELEMENT ui ON (ui.col_id = ao.COL_ACCESSOBJECTUIELEMENT)
WHERE
    (:TypeId IS NULL OR  ao.COL_ACCESSOBJACCESSOBJTYPE = :TypeId) AND
    (:AccessObjectType_Id IS NULL OR  ao.COL_ACCESSOBJACCESSOBJTYPE = :AccessObjectType_Id) AND
    (:ID IS NULL OR  ao.COL_ID = :ID)
<%=Sort("@SORT@","@DIR@")%>