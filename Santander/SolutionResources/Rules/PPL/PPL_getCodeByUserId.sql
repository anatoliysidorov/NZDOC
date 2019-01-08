DECLARE
  v_userCode  NVARCHAR2(255);
  v_userLogin NVARCHAR2(255);
  v_userRoles NCLOB;
  v_Result    NUMBER;
BEGIN
  v_userCode    := '';
  v_userLogin   := '';
  :UCode        := '';
  :ULOGIN       := '';
  :errorCode    := 0;
  :errorMessage := '';
  IF :UserId IS NULL THEN
    :errorCode    := 120;
    :errorMessage := 'Validation: ''User id'' is required field';
  ELSE
    BEGIN
      SELECT usr.CODE,
             usr.LOGIN,
             t2.list_roles
        INTO v_userCode,
             v_userLogin,
             v_userRoles
        FROM VW_USERS usr
        LEFT JOIN (SELECT t1.userid,
                          list_collect(cast(collect(to_char(t1.Code) order by to_char(t1.userid)) as split_tbl),'|||',1) as list_roles
                          --LISTAGG(TO_CHAR(t1.Code), '|||') WITHIN GROUP(ORDER BY t1.userid) AS list_roles
                     FROM (SELECT usr_roles.USERID AS userid,
                                  role.Code        AS Code
                             FROM @TOKEN_SYSTEMDOMAINUSER@.asf_userrole usr_roles
                             LEFT JOIN @TOKEN_SYSTEMDOMAINUSER@.asf_role role
                               ON usr_roles.roleid = role.roleid
                            WHERE usr_roles.roleid IN (SELECT rl.roleid
                                                         FROM @TOKEN_SYSTEMDOMAINUSER@.asf_role rl
                                                       --WHERE  rl.domainid = '@TOKEN_SYSTEMDOMAIN@' 
                                                       --AND rl.envid != '@TOKEN_DOMAIN@'
                                                       )) t1
                    GROUP BY t1.userid) t2
          ON t2.userid = usr.UserId
       WHERE usr.UserId = :UserId;
    
      :UCode  := v_userCode;
      :ULOGIN := v_userLogin;
      :UROLES := v_userRoles;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        :errorCode := 121;
        v_Result   := LOC_i18n(MessageText   => 'AppBase User with  UserId# {{MESS_USERID}} was not found',
                               MessageResult => :errorMessage,
                               MessageParams => NES_TABLE(KEY_VALUE('MESS_USERID', :UserId)));
    END;
  END IF;
END;
