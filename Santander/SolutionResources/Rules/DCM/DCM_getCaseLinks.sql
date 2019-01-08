SELECT
    --CASE LINK
    CL.COL_ID                                      AS ID,
    CL.COL_CODE                                    AS CODE,
    CL.COL_NAME                                    AS NAME,
    CL.COL_DESCRIPTION                             AS DESCRIPTION,
    F_GETNAMEFROMACCESSSUBJECT (CL.COL_CREATEDBY)  AS CREATEDBY_NAME,
    F_UTIL_GETDRTNFRMNOW (CL.COL_CREATEDDATE)      AS CREATEDDURATION,
    F_GETNAMEFROMACCESSSUBJECT (CL.COL_MODIFIEDBY) AS MODIFIEDBY_NAME,
    F_UTIL_GETDRTNFRMNOW (CL.COL_MODIFIEDDATE)     AS MODIFIEDDURATION,
    --CHILD CASE
    CS_CHILD.ID                   AS C_ID,
    CS_CHILD.CASEID               AS C_CASEID,
    CS_CHILD.CASESTATE_ISSTART    AS C_CASESTATE_ISSTART,
    CS_CHILD.CASESTATE_ISFINISH   AS C_CASESTATE_ISFINISH,
    CS_CHILD.CASESTATE_NAME       AS C_CASESTATE_NAME,
    CS_CHILD.RESOLUTIONCODE_NAME  AS C_RESOLUTIONCODE_NAME,
    CS_CHILD.RESOLUTIONCODE_THEME AS C_RESOLUTIONCODE_THEME,
    CS_CHILD.RESOLUTIONCODE_ICON  AS C_RESOLUTIONCODE_ICON,
    CS_CHILD.WORKBASKET_NAME      AS C_WORKBASKET_NAME,
    CS_CHILD.WORKBASKET_TYPE_CODE AS C_WORKBASKET_TYPE_CODE,
    --PARENT CASE 
    CS_PARENT.ID                   AS P_ID,
    CS_PARENT.CASEID               AS P_CASEID,
    CS_PARENT.CASESTATE_ISSTART    AS P_CASESTATE_ISSTART,
    CS_PARENT.CASESTATE_ISFINISH   AS P_CASESTATE_ISFINISH,
    CS_PARENT.CASESTATE_NAME       AS P_CASESTATE_NAME,
    CS_PARENT.RESOLUTIONCODE_NAME  AS P_RESOLUTIONCODE_NAME,
    CS_PARENT.RESOLUTIONCODE_THEME AS P_RESOLUTIONCODE_THEME,
    CS_PARENT.RESOLUTIONCODE_ICON  AS P_RESOLUTIONCODE_ICON,
    CS_PARENT.WORKBASKET_NAME      AS P_WORKBASKET_NAME,
    CS_PARENT.WORKBASKET_TYPE_CODE AS P_WORKBASKET_TYPE_CODE,
    --LINK TYPE
    LT.COL_ID   AS LT_ID,
    LT.COL_NAME AS LT_NAME,
    LT.COL_CODE AS LT_CODE,
    --LINK DIRECTION
    LD.COL_ID   AS LD_ID,
    LD.COL_NAME AS LD_NAME,
    LD.COL_CODE AS LD_CODE,
    --DETAIL ACTION
    CASE 
    WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_PARENT.COL_ID THEN CS_CHILD.COL_ID
    WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_CHILD.COL_ID THEN CS_PARENT.COL_ID
    ELSE (NULL) END AS DETAIL_ID,
    CASE 
    WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_PARENT.COL_ID THEN CS_CHILD.CASEID
    WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_CHILD.COL_ID THEN CS_PARENT.CASEID
    ELSE (NULL) END AS DETAIL_NAME,

    CASE
    WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_PARENT.COL_ID THEN CS_CHILD.CaseSysType_Name
    WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_CHILD.COL_ID THEN CS_PARENT.CaseSysType_Name
    ELSE (NULL) END AS CaseSysType_Name,

    CASE
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_PARENT.COL_ID THEN CS_CHILD.MS_StateName
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_CHILD.COL_ID THEN CS_PARENT.MS_StateName
      ELSE (NULL) END AS MS_StateName,
    CASE
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_PARENT.COL_ID THEN CS_CHILD.CASESTATE_ISSTART
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_CHILD.COL_ID THEN CS_PARENT.CASESTATE_ISSTART
      ELSE (NULL) END AS CASESTATE_ISSTART,
    CASE
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_PARENT.COL_ID THEN CS_CHILD.CASESTATE_ISFINISH
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_CHILD.COL_ID THEN CS_PARENT.CASESTATE_ISFINISH
      ELSE (NULL) END AS CASESTATE_ISFINISH,
	-- SLA
    CASE
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_PARENT.COL_ID THEN F_util_getdrtnfrmnow(CS_CHILD.GoalSlaDateTime)
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_CHILD.COL_ID THEN F_util_getdrtnfrmnow(CS_PARENT.GoalSlaDateTime)
      ELSE (NULL) END AS GoalSlaDuration,
    CASE
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_PARENT.COL_ID THEN F_util_getdrtnfrmnow(CS_CHILD.DLineSlaDateTime)
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_CHILD.COL_ID THEN F_util_getdrtnfrmnow(CS_PARENT.DLineSlaDateTime)
      ELSE (NULL) END AS DLineSlaDuration,
    -- Permission 'Detail'
    CASE
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_PARENT.COL_ID THEN f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = CS_CHILD.CASESYSTYPE_ID), permissioncode => 'DETAIL')
      WHEN NVL(:CHILD_OR_PARENT_ID,0) = CS_CHILD.COL_ID THEN f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = CS_PARENT.CASESYSTYPE_ID), permissioncode => 'DETAIL')
      ELSE 0 END AS PERM_CASETYPE_DETAIL      


FROM TBL_CASELINK CL
    LEFT JOIN VW_DCM_SIMPLECASE CS_CHILD 
        ON CL.COL_CASELINKCHILDCASE = CS_CHILD.COL_ID
    LEFT JOIN VW_DCM_SIMPLECASE CS_PARENT 
        ON CL.COL_CASELINKPARENTCASE = CS_PARENT.COL_ID
    LEFT JOIN TBL_DICT_LINKTYPE LT 
        ON CL.COL_CASELINKDICT_LINKTYPE = LT.COL_ID
    LEFT JOIN TBL_DICT_LINKDIRECTION LD 
        ON CL.COL_CASELINKLINKDIRECTION = LD.COL_ID
    
WHERE 
    (:ID IS NULL OR CL.COL_ID = :ID)
    AND (:CHILD_ID IS NULL OR CS_CHILD.COL_ID = :CHILD_ID)
    AND (:PARENT_ID IS NULL OR CS_PARENT.COL_ID = :PARENT_ID)
    AND (:CHILD_OR_PARENT_ID IS NULL 
        OR (
        CS_PARENT.COL_ID = :CHILD_OR_PARENT_ID OR CS_CHILD.COL_ID = :CHILD_OR_PARENT_ID
        )
    )
    AND (f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = CS_CHILD.CASESYSTYPE_ID), permissioncode => 'VIEW') = 1)
    AND (f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = CS_PARENT.CASESYSTYPE_ID), permissioncode => 'VIEW') = 1)
<%=IFNOTNULL("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>