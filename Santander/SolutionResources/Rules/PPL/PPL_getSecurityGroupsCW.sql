DECLARE
  v_groups       NCLOB;
  v_grantGroups  NCLOB;
  v_revokeGroups NCLOB;
  v_UserID       NUMBER;
BEGIN
  v_groups      := :GROUPS;
  v_UserID      := :USERID;
  :errorCode    := 0;
  :errorMessage := '';

  BEGIN
    SELECT list_collect(cast(collect(to_char(t_group.Code) order by to_char(t_group.Code)) as split_tbl),'|||',1) as GroupList
         --LISTAGG(TO_CHAR(t_group.Code), '|||') WITHIN GROUP(ORDER BY usr_group.userid) AS GroupList
      INTO v_revokeGroups
      FROM vw_UserGroup usr_group
      LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.ASF_GROUP t_group
        ON (t_group.GROUPID = usr_group.GROUPID AND nvl(usr_group.SOURCE, 0) = 0)
     WHERE --t_group.domainid = '@TOKEN_SYSTEMDOMAIN@'
    --AND 
     usr_group.userid = v_UserID
     AND t_group.Code NOT IN (SELECT COLUMN_VALUE FROM TABLE(ASF_SPLIT(v_groups, '|||')))
     GROUP BY usr_group.userid;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_revokeGroups := NULL;
  END;

  BEGIN
    SELECT list_collect(cast(collect(to_char(COLUMN_VALUE) order by to_char(COLUMN_VALUE)) as split_tbl),'|||',1) as GroupList
          --LISTAGG(TO_CHAR(COLUMN_VALUE), '|||') WITHIN GROUP(ORDER BY '1') AS GroupList
      INTO v_grantGroups
      FROM TABLE(ASF_SPLIT(v_groups, '|||'))
     WHERE COLUMN_VALUE NOT IN (SELECT t_group.Code
                                  FROM vw_UserGroup usr_group
                                  LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.ASF_GROUP t_group
                                    ON (t_group.GROUPID = usr_group.GROUPID AND nvl(usr_group.SOURCE, 0) = 0)
                                 WHERE --t_group.domainid = '@TOKEN_SYSTEMDOMAIN@' 
                                --AND 
                                 usr_group.userid = v_UserID);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_grantGroups := NULL;
  END;
  :GRANTLIST  := v_grantGroups;
  :REVOKELIST := v_revokeGroups;
EXCEPTION
  WHEN OTHERS THEN
    :errorCode    := 121;
    :errorMessage := 'Exception error in the rule ''PPL_getSecurityGroupsCW'' ';
END;
