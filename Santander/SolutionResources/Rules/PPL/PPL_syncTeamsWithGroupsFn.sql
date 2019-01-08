DECLARE
	v_asid	                    INTEGER;
	v_cwId	                    INTEGER;
	v_personalworkbaskettype_id INTEGER;
	v_errorCode                 NUMBER;
	v_errorMessage              nvarchar2(255);
BEGIN
	v_errorCode     := 0;
	v_errorMessage  := '';
	:ErrorCode      := v_errorCode;
	:ErrorMessage   := v_errorMessage;
	-- Unlink deleted groups
	FOR rec IN (
      SELECT 
          t.COL_ID AS ID, 
          t.COL_NAME AS NAME, 
          t.COL_CODE AS CODE, 
          t.COL_GROUPID AS GROUPID
      FROM TBL_PPL_TEAM t
      LEFT JOIN VW_PPL_APPBASEGROUP g ON (t.COL_GROUPID=g.ID)
      WHERE t.COL_GROUPID IS NOT NULL
        AND g.ID IS NULL)
	LOOP
      DELETE FROM TBL_CASEWORKERTEAM WHERE COL_TBL_PPL_TEAM = rec.ID;
      UPDATE TBL_PPL_TEAM
      SET COL_GROUPID = NULL
      WHERE COL_ID = rec.ID;
	END LOOP;

	-- Link new users
	v_personalworkbaskettype_id := f_util_getidbycode(code => 'personal', tablename => 'tbl_dict_workbaskettype') ;
	IF  v_personalworkbaskettype_id IS NULL THEN
		v_personalworkbaskettype_id := -1;
	END IF;
	
	FOR trec IN (
      SELECT 
          t.COL_ID AS TEAMID, 
          g.ID AS GROUPID
      FROM VW_PPL_APPBASEGROUP g
      INNER JOIN TBL_PPL_TEAM t ON (t.COL_GROUPID=g.ID))
	LOOP
		FOR rec IN (
          SELECT 
              u.USERID AS USERID, 
              cw.COL_ID AS CWID, 
              cw.COL_USERID AS CWUSERID, 
              cw.COL_ISDELETED AS ISDELETED, 
              u.Name as NAME, 
              t.COL_ID AS TEAMID
		  FROM VW_USERS u
          INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.ASF_USERGROUP ug ON (u.USERID=ug.USERID)
          INNER JOIN VW_PPL_APPBASEGROUP g ON (g.ID=ug.GROUPID)
          INNER JOIN TBL_PPL_TEAM t ON (t.COL_GROUPID=g.ID)
          LEFT JOIN TBL_PPL_CASEWORKER cw ON (cw.COL_USERID=u.userid)
          WHERE t.COL_ID=trec.TEAMID AND (cw.COL_ID IS NULL OR cw.COL_ID NOT IN (
              SELECT cw1.COL_ID
              FROM TBL_PPL_CASEWORKER cw1
              INNER JOIN TBL_CASEWORKERTEAM tcw ON (cw1.col_id = tcw.COL_TM_PPL_CASEWORKER)
              WHERE tcw.COL_TBL_PPL_TEAM = t.col_id)))
		LOOP
            IF (rec.CWUSERID IS NULL) THEN
                v_cwId := F_ppl_createmodifycwfn(UserId => rec.USERID, ExternalId => NULL, ErrorCode => v_errorCode, ErrorMessage => v_errorMessage);
                IF (v_errorCode <> 0 or v_cwId IS NULL or v_cwId <= 0) THEN
                  rollback;
                  GOTO cleanup;
                END IF;
            ELSE
            	v_cwId := rec.CWID;
            END IF;
            
            INSERT INTO TBL_CASEWORKERTEAM(
            	COL_TBL_PPL_TEAM, COL_TM_PPL_CASEWORKER
            )VALUES(
            	rec.TEAMID, v_cwId
            );
		END LOOP;
	END LOOP;

	-- Unlink deleted users
	FOR rec IN (
      SELECT 
          cw.COL_ID AS CWID, 
          cw.COL_USERID AS CWUSERID, 
          t.COL_ID as TEAMID
      FROM TBL_PPL_CASEWORKER cw
      INNER JOIN TBL_CASEWORKERTEAM tcw ON (cw.COL_ID = tcw.COL_TM_PPL_CASEWORKER)
      INNER JOIN TBL_PPL_TEAM t ON (tcw.COL_TBL_PPL_TEAM = t.COL_ID)
      INNER JOIN VW_PPL_APPBASEGROUP g ON (t.COL_GROUPID=g.ID)
      WHERE cw.COL_USERID NOT IN (
					SELECT u.USERID
					FROM VW_USERS u
					INNER JOIN @TOKEN_SYSTEMDOMAINUSER@.ASF_USERGROUP ug ON (u.USERID=ug.USERID)
					WHERE ug.GROUPID = t.COL_GROUPID))
	LOOP
      DELETE FROM TBL_CASEWORKERTEAM
      WHERE COL_TBL_PPL_TEAM = rec.TEAMID
        AND COL_TM_PPL_CASEWORKER = rec.CWID;
	END LOOP;
<<cleanup>>
:ErrorCode := v_errorCode;
:ErrorMessage := v_errorMessage;
--dbms_output.put_line(v_errorMessage);
END;