SELECT
    --case link template
    CLT.COL_ID                                      AS ID,
    CLT.COL_CODE                                    AS CODE,
    CLT.COL_NAME                                    AS NAME,
    NVL(CLT.COL_CANCREATECHILDFROMPARENT,0)         AS CANCREATECHILDFROMPARENT,
    NVL(CLT.COL_CANCREATEPARENTFROMCHILD,0)         AS CANCREATEPARENTFROMCHILD,
    NVL(CLT.COL_CANLINKCHILDTOPARENT,0)             AS CANLINKCHILDTOPARENT,
    NVL(CLT.COL_CANLINKPARENTTOCHILD,0)             AS CANLINKPARENTTOCHILD,
    F_GETNAMEFROMACCESSSUBJECT (CLT.COL_CREATEDBY)  AS CREATEDBY_NAME,
    F_UTIL_GETDRTNFRMNOW (CLT.COL_CREATEDDATE)      AS CREATEDDURATION,
    F_GETNAMEFROMACCESSSUBJECT (CLT.COL_MODIFIEDBY) AS MODIFIEDBY_NAME,
    F_UTIL_GETDRTNFRMNOW (CLT.COL_MODIFIEDDATE)     AS MODIFIEDDURATION,
    --child case type
    CST_CHILD.COL_ID    AS CHILD_ID,
    CST_CHILD.COL_NAME  AS CHILD_NAME,
    CST_CHILD.COL_CODE  AS CHILD_CODE,
    CST_CHILD.COL_USEDATAMODEL AS USEDATAMODEL,
    DO.COL_CODE AS ROOTOBJECTCODE,
    AP.MDM_FORM AS CREATEFORMID,
    CST_CHILD.COL_CASETYPEPRIORITY AS PRIORITY_ID,
    CASE
      WHEN NVL (CST_CHILD.COL_CASETYPEPRIORITY, 0) = 0
        THEN
          (SELECT COL_ID
            FROM TBL_STP_PRIORITY
            WHERE COL_ISDEFAULT = 1)
        ELSE
          CST_CHILD.COL_CASETYPEPRIORITY
      END
    AS DEFAULT_PRIORITY_ID,
    --parent case type
    CST_PARENT.COL_ID   AS PARENT_ID,
    CST_PARENT.COL_NAME AS PARENT_NAME,
    CST_PARENT.COL_CODE AS PARENT_CODE,
    --link type
    LT.COL_ID   AS LT_ID,
    LT.COL_NAME AS LT_NAME,
    LT.COL_CODE AS LT_CODE,
    --link direction
    LD.COL_ID   AS LD_ID,
    LD.COL_NAME AS LD_NAME,
    LD.COL_CODE AS LD_CODE,
    --detail action
    case
    when NVL(:CHILD_OR_PARENT_ID,0) = CST_PARENT.COL_ID then CST_CHILD.COL_ID
    when NVL(:CHILD_OR_PARENT_ID,0) = CST_CHILD.COL_ID then CST_PARENT.COL_ID
    else (null) end as DETAIL_ID,
    case
    when NVL(:CHILD_OR_PARENT_ID,0) = CST_PARENT.COL_ID then CST_CHILD.COL_NAME
    when NVL(:CHILD_OR_PARENT_ID,0) = CST_CHILD.COL_ID then CST_PARENT.COL_NAME
    else (null) end as DETAIL_NAME

FROM TBL_CASELINKTMPL CLT
    LEFT JOIN TBL_DICT_CASESYSTYPE CST_CHILD
        ON CLT.COL_CASELINKTMPLCHILDCASETYPE = CST_CHILD.COL_ID
    LEFT JOIN TBL_MDM_MODEL MM
        ON CST_CHILD.COL_CASESYSTYPEMODEL = MM.COL_ID
    LEFT JOIN TBL_DOM_MODEL DM
        ON MM.COL_ID = DM.COL_DOM_MODELMDM_MODEL
    LEFT JOIN TBL_DOM_OBJECT DO
        ON DM.COL_ID = DO.COL_DOM_OBJECTDOM_MODEL AND UPPER(DO.COL_TYPE) = 'ROOTBUSINESSOBJECT'
    LEFT JOIN VW_DCM_ASSOCPAGE AP
        ON AP.CASESYSTYPE = CST_CHILD.COL_ID AND AP.PAGETYPE_CODE = 'MDM_CREATE_FORM'
    LEFT JOIN TBL_DICT_CASESYSTYPE CST_PARENT
        ON CLT.COL_CASELINKTMPLPRNTCASETYPE = CST_PARENT.COL_ID
    LEFT JOIN TBL_DICT_LINKTYPE LT
        ON CLT.COL_CASELINKTMPLLINKTYPE = LT.COL_ID
    LEFT JOIN TBL_DICT_LINKDIRECTION LD
        ON CLT.COL_CASELINKTMPLLINKDIRECTION = LD.COL_ID

 WHERE (:ID IS NULL OR CLT.COL_ID = :ID)
   AND (:CHILD_ID IS NULL OR CST_CHILD.COL_ID = :CHILD_ID)
   AND (:PARENT_ID IS NULL OR CST_PARENT.COL_ID = :PARENT_ID)
   AND (:CHILD_OR_PARENT_ID IS NULL OR (CST_PARENT.COL_ID = :CHILD_OR_PARENT_ID OR CST_CHILD.COL_ID = :CHILD_OR_PARENT_ID))
   AND NVL(CST_CHILD.COL_ISDELETED, 0) = 0
   AND (:PERMISSIONCODE IS NULL OR
       (f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = CST_CHILD.COL_ID),
                                permissioncode => :PERMISSIONCODE) = 1) AND
       (f_dcm_iscasetypeaccess(accessobjectid => (SELECT Id FROM TABLE(f_dcm_getcasetypeaolist()) WHERE CaseTypeId = CST_PARENT.COL_ID),
                                permissioncode => :PERMISSIONCODE) = 1))
<%=IfNotNull("@SORT@", " order by @SORT@ @DIR@, 1")%>