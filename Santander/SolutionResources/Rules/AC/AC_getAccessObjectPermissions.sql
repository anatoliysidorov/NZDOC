DECLARE
  v_permissions NVARCHAR2(1000);
  v_sql         VARCHAR2(2000);

  v_typeId       NVARCHAR2(250);
  v_Id           NVARCHAR2(250);
  v_ObjectTypeId INTEGER;

  v_UIElementCode NVARCHAR2(255);
  v_UIElementId  INTEGER;
BEGIN

  v_sql := 'SELECT * ';

  --determinating builder
  IF (:PageConfigId IS NOT NULL) THEN
    v_UIElementId := :PageConfigId;
    v_UIElementCode := 'PAGE_ELEMENT';
  ELSIF (:DashboardConfigId IS NOT NULL) THEN
    v_UIElementId := :DashboardConfigId;
    v_UIElementCode := 'DASHBOARD_ELEMENT';
  END IF;  

  IF (v_UIElementId IS NULL) THEN
    v_typeId := NULL;
    IF (:TypeId IS NOT NULL) THEN
      v_typeId := ' AND ao.COL_ACCESSOBJACCESSOBJTYPE = ' || :TypeId;
    END IF;
  
    v_Id := NULL;
    IF (:ID IS NOT NULL) THEN
      v_Id := ' AND ao.COL_ID = ' || :ID;
    END IF;
  
    v_sql := v_sql || 'FROM (SELECT ao.COL_ID AS ID,ao.col_name AS NAME,acl.col_type AS TYPE, p.COL_CODE AS PCODE
      FROM TBL_AC_ACCESSOBJECT ao
      INNER JOIN TBL_AC_PERMISSION p on (p.COL_PERMISSIONACCESSOBJTYPE=ao.COL_ACCESSOBJACCESSOBJTYPE)
      LEFT JOIN TBL_AC_ACL acl on (acl.COL_ACLACCESSOBJECT = ao.COL_ID AND acl.COL_ACLACCESSSUBJECT = ' || :AccessSubjectId || ' AND acl.COL_ACLPERMISSION = p.COL_ID)
      WHERE 1=1
        ' || v_typeId || '
        ' || v_Id || ')';

    v_ObjectTypeId := :TypeId;
  ELSE
    v_sql := v_sql || 'FROM (select acs.col_id AS ID,acs.col_name AS NAME,acl.col_type AS TYPE,p.COL_CODE AS PCODE
      FROM TBL_AC_ACCESSSUBJECT acs
      INNER JOIN TBL_AC_PERMISSION p on (p.COL_PERMISSIONACCESSOBJTYPE IN (SELECT col_id from TBL_AC_ACCESSOBJECTTYPE aot where col_code=''' || v_UIElementCode || '''))
      LEFT JOIN TBL_AC_ACCESSOBJECT aco on (aco.COL_ACCESSOBJECTUIELEMENT = ' || to_char(v_UIElementId) || ')
      LEFT JOIN TBL_AC_ACL acl on (acl.COL_ACLACCESSOBJECT = aco.COL_ID AND acl.COL_ACLACCESSSUBJECT = acs.col_id AND acl.COL_ACLPERMISSION = p.COL_ID)
      WHERE acs.col_type = ''' || :ASType || ''')';

    SELECT col_id INTO v_ObjectTypeId FROM TBL_AC_ACCESSOBJECTTYPE WHERE col_code = v_UIElementCode;
  END IF;

  -- get Permissions
  v_permissions := NULL;
  IF (v_ObjectTypeId IS NOT NULL) THEN
    FOR v IN (SELECT COL_ID, COL_CODE, COL_NAME FROM TBL_AC_PERMISSION WHERE COL_PERMISSIONACCESSOBJTYPE = v_ObjectTypeId ORDER BY col_code) LOOP
      IF (v_permissions IS NOT NULL) THEN
        v_permissions := v_permissions || ',';
      END IF;
      v_permissions := v_permissions || '''' || v.COL_CODE || ''' AS "' || v.COL_CODE || '"';
    END LOOP;
  END IF;

  v_sql := v_sql || 'PIVOT
(
  MAX(TYPE)
  FOR PCODE IN (' || v_permissions || ')
)
ORDER BY NAME';

  OPEN :ITEMS FOR v_sql;
END;