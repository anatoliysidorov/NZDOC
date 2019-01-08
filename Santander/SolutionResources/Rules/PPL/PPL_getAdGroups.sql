DECLARE
    v_grantAdGroups   NCLOB;
    v_UserID          NUMBER;
BEGIN
    v_UserID := :USERID;
    :errorCode := 0;
    :errorMessage := '';
    v_grantAdGroups := null;

    --Grand AD Groups if exists
    BEGIN
        SELECT list_collect(cast(collect(to_char(t_group.Code) order by to_char(usr_group.userid)) as split_tbl),'|||',1) as GroupList
               --LISTAGG (TO_CHAR (t_group.Code), '|||') WITHIN GROUP (ORDER BY usr_group.userid) AS GroupList
               INTO v_grantAdGroups
        FROM vw_UserGroup  usr_group
        LEFT JOIN vw_Groups t_group ON t_group.GROUPID = usr_group.GROUPID
        WHERE usr_group.userid = v_UserID AND t_group.SOURCE = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_grantAdGroups := NULL; 
    END;

    :GRANTLIST := v_grantAdGroups;
EXCEPTION
    WHEN OTHERS THEN
        :errorCode := 121;
        :errorMessage := 'Exception error in the rule ''PPL_getAdGroups'' ';
END;