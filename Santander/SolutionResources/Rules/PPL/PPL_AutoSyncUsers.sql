DECLARE
  v_res          NUMBER;
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
  v_result       NUMBER;
  v_message      NCLOB;
  v_name         NVARCHAR2(255);
  v_text         NVARCHAR2(500);
  v_sep          NVARCHAR2(10);
BEGIN
  v_errorCode    := 0;
  v_errorMessage := '';
  v_message      := 'Syncing users';
  :ErrorCode     := v_errorCode;
  :ErrorMessage  := v_errorMessage;
  v_sep          := ' &#9670; ';

  --CREATE CASE WORKER RECORDS FOR USERS WHO ARE NOT YET CASE WORKERS IN THE SYSTEM BUT HAVE THE ROOT_CASEWORKER ROLE
  FOR rec IN (SELECT usr.USERID AS USERID,
                     usr.NAME AS NAME,
                     usr.SOURCE AS SOURCE,
                     usr.LOGIN AS LOGIN,
                     CASE usr.SOURCE
                       WHEN 1 THEN
                        'Active Directory'
                       ELSE
                        'Database'
                     END AS SOURCETEXT
                FROM (SELECT USERID AS USERID FROM vw_PPL_UsersWithProperRoles MINUS SELECT COL_USERID AS USERID FROM tbl_ppl_caseworker cw) m
                LEFT JOIN vw_users usr
                  ON usr.userid = m.userid)
  
   LOOP
    -- create new caseworker record for each unmatched pair of AppBase user
    v_res := F_ppl_createmodifycwfn(userid => rec.userid, ExternalId => NULL, ErrorCode => v_errorCode, ErrorMessage => v_errorMessage);
  
    v_text := 'CREATE CASE WORKER' || v_sep || rec.NAME || v_sep || rec. LOGIN || v_sep || rec.SOURCETEXT;
  
    IF (v_errorCode > 0) THEN
      :ErrorCode    := v_errorCode;
      :ErrorMessage := v_errorMessage;
      v_text        := '<b>ERROR</b> ' || v_text;
    END IF;
  
    v_message := F_util_addtomessage(originalmsg => v_message, newmsg => v_text);
  END LOOP;

  --DISABLE CASE WORKERS WHO ARE NO LONGER USERS IN APPBASE
  FOR rec IN (SELECT cw.col_userID AS ORIGINAL_USERID,
                     cw.col_name   AS ORIGINAL_NAME
                FROM TBL_PPL_CASEWORKER cw
                LEFT JOIN VW_USERS usr
                  ON cw.col_userid = usr.userid
               WHERE usr.userID IS NULL
                 AND NVL(COL_ISDELETED, 0) = 0)
  
   LOOP
    UPDATE tbl_ppl_caseworker SET col_isdeleted = 1 WHERE col_userid = rec.ORIGINAL_USERID;
  
    v_text    := 'DISABLE CASE WORKER BECAUSE REMOVED USER' || v_sep || rec.ORIGINAL_NAME || v_sep || 'Original User ID ' ||
                 TO_CHAR(rec.ORIGINAL_USERID);
    v_message := F_util_addtomessage(originalmsg => v_message, newmsg => v_text);
  END LOOP;

  --DISABLE CASE WORKERS WHO DON'T HAVE THE ROOT_CASEWORKER ROLE ANYMORE
  FOR rec IN (SELECT usr.USERID AS USERID,
                     usr.NAME AS NAME,
                     usr.SOURCE AS SOURCE,
                     usr.LOGIN AS LOGIN,
                     CASE usr.SOURCE
                       WHEN 1 THEN
                        'Active Directory'
                       ELSE
                        'Database'
                     END AS SOURCETEXT
                FROM (SELECT COL_USERID AS USERID
                        FROM tbl_ppl_caseworker cw
                       WHERE NVL(COL_ISDELETED, 0) = 0
                      MINUS
                      SELECT USERID AS USERID
                        FROM vw_PPL_UsersWithProperRoles) m
                LEFT JOIN vw_users usr
                  ON usr.userid = m.userid)
  
   LOOP
    UPDATE tbl_ppl_caseworker SET col_isdeleted = 1 WHERE col_userid = rec.USERID;
  
    v_text    := 'DISABLE CASE WORKER BECAUSE MISSING ROOT_CASEWORKER ROLE' || v_sep || rec.NAME || v_sep || rec. LOGIN || v_sep || rec.SOURCETEXT;
    v_message := F_util_addtomessage(originalmsg => v_message, newmsg => v_text);
  END LOOP;

  --ENABLE CASE WORKERS WHO NOW HAVE THE CASE WORKER ROLE
  FOR rec IN (SELECT usr.USERID AS USERID,
                     usr.NAME AS NAME,
                     usr.SOURCE AS SOURCE,
                     usr.LOGIN AS LOGIN,
                     CASE usr.SOURCE
                       WHEN 1 THEN
                        'Active Directory'
                       ELSE
                        'Database'
                     END AS SOURCETEXT
                FROM vw_PPL_UsersWithProperRoles usrR
               INNER JOIN tbl_ppl_caseworker cw
                  ON cw.col_userid = usrR.userid
                LEFT JOIN vw_users usr
                  ON usr.userid = usrR.userid
               WHERE cw.col_isdeleted = 1)
  
   LOOP
    UPDATE tbl_ppl_caseworker SET col_isdeleted = 0 WHERE col_userid = rec.USERID;
  
    v_text    := 'ENABLED CASE WORKER BECAUSE HAS ROOT_CASEWORKER ROLE' || v_sep || rec.NAME || v_sep || rec. LOGIN || v_sep || rec.SOURCETEXT;
    v_message := F_util_addtomessage(originalmsg => v_message, newmsg => v_text);
  END LOOP;

  --SYNC APPBASE GROUPS WITH DCM TEAMS
  v_result := F_PPL_syncTeamsWithGroupsFn(ErrorCode => v_errorCode, ErrorMessage => v_errorMessage);

  --RESET SECURITY CACHE
  v_result := f_DCM_createCTAccessCache();

  --WRITE LOG AND RETURN INFO
  v_result      := f_UTIL_createSysLogFn(MESSAGE => v_message);
  :ErrorCode    := 0;
  :ErrorMessage := NULL;

EXCEPTION
  WHEN OTHERS THEN
    :ErrorCode    := 103;
    :ErrorMessage := DBMS_UTILITY.FORMAT_ERROR_STACK;
END;