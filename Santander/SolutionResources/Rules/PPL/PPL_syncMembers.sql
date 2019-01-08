DECLARE
  v_ObjectId       NUMBER;
  v_ObjectType     VARCHAR2(255);
  v_MembersList    CLOB;
  v_NotMembersList CLOB;
  v_MembersType    VARCHAR2(255);
  v_count          NUMBER;
  v_TableName      VARCHAR2(255);
  v_isId           NUMBER;
  v_result         NUMBER;

  --standard
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
BEGIN

  v_ObjectId       := :ObjectId;
  v_ObjectType     := UPPER(:ObjectType);
  v_MembersType    := UPPER(:MemberType);
  v_MembersList    := :MemberIds;
  v_NotMembersList := :NotMemberIds;

  --standard
  v_errorcode    := 0;
  v_errormessage := '';

  -- validation on Id is Exist
  IF (v_ObjectType = 'TEAM') THEN
    v_TableName := 'TBL_PPL_TEAM';
  ELSE
    IF (v_ObjectType = 'SKILL') THEN
      v_TableName := 'TBL_PPL_SKILL';
    ELSE
      IF (v_ObjectType = 'BUSINESSROLE') THEN
        v_TableName := 'TBL_PPL_BUSINESSROLE';
      ELSE
        IF (v_ObjectType = 'WORKBASKET') THEN
          v_TableName := 'TBL_PPL_WORKBASKET';
        END IF;
      END IF;
    END IF;
  END IF;
  v_isId := f_UTIL_getId(errorcode => v_errorcode, errormessage => v_errormessage, id => v_ObjectId, tablename => v_TableName);
  IF v_errorcode > 0 THEN
    GOTO cleanup;
  END IF;

  --CASEWORKERS - TEAM
  IF (v_ObjectType = 'TEAM' AND v_MembersType = 'CASEWORKERS') THEN
  
    --add members
    IF (v_MembersList = 'ALL') THEN
      INSERT INTO tbl_caseworkerteam
        (col_tm_ppl_caseworker, col_tbl_ppl_team)
        SELECT cw.id,
               v_ObjectId
          FROM vw_ppl_activecaseworkersusers cw
         WHERE cw.id NOT IN (SELECT cw1.id FROM vw_ppl_activecaseworkersusers cw1 INNER JOIN tbl_caseworkerteam tc1 ON cw1.id = tc1.col_tm_ppl_caseworker WHERE tc1.col_tbl_ppl_team = v_ObjectId);
    ELSE
      FOR newObj IN (SELECT cw.col_id AS cwid
                       FROM tbl_ppl_caseworker cw
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS userid
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (cw.col_id = ul.userid)
                       LEFT JOIN tbl_caseworkerteam tc
                         ON cw.col_id = tc.col_tm_ppl_caseworker
                     /*WHERE NVL(cw.COL_ISDELETED, 0) = 0*/
                     ) LOOP
        SELECT COUNT(cwt.col_tm_ppl_caseworker)
          INTO v_count
          FROM tbl_caseworkerteam cwt
         WHERE cwt.col_tm_ppl_caseworker = newObj.cwid
           AND cwt.col_tbl_ppl_team = v_ObjectId;
      
        IF (v_count = 0) THEN
          INSERT INTO tbl_caseworkerteam (col_tm_ppl_caseworker, col_tbl_ppl_team) VALUES (newObj.cwid, v_ObjectId);
        END IF;
      END LOOP;
    END IF;
  
    --delete members
    IF (v_NotMembersList = 'ALL') THEN
      DELETE FROM tbl_caseworkerteam tc WHERE tc.col_tbl_ppl_team = v_ObjectId;
    ELSE
      FOR delObj IN (SELECT cw.col_id AS cwid
                       FROM tbl_ppl_caseworker cw
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS userid
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (cw.col_id = ul.userid)
                       LEFT JOIN tbl_caseworkerteam tc
                         ON cw.col_id = tc.col_tm_ppl_caseworker
                      WHERE /*NVL(cw.COL_ISDELETED, 0) = 0 AND */
                      tc.col_tbl_ppl_team = v_ObjectId) LOOP
        IF (delObj.cwid IS NOT NULL) THEN
          DELETE FROM tbl_caseworkerteam tc
           WHERE tc.col_tm_ppl_caseworker = delObj.cwid
             AND tc.col_tbl_ppl_team = v_ObjectId;
        END IF;
      END LOOP;
    END IF;
  END IF;

  --CASEWORKERS - SKILL
  IF (v_ObjectType = 'SKILL' AND v_MembersType = 'CASEWORKERS') THEN
  
    --add members
    IF (v_MembersList = 'ALL') THEN
      INSERT INTO tbl_caseworkerskill
        (col_sk_ppl_caseworker, col_tbl_ppl_skill)
        SELECT cw.id,
               v_ObjectId
          FROM vw_ppl_activecaseworkersusers cw
         WHERE cw.id NOT IN (SELECT cw1.id FROM vw_ppl_activecaseworkersusers cw1 INNER JOIN tbl_caseworkerskill cws1 ON cw1.id = cws1.col_sk_ppl_caseworker WHERE cws1.col_tbl_ppl_skill = v_ObjectId);
    ELSE
      FOR newObj IN (SELECT cw.col_id AS cwid
                       FROM tbl_ppl_caseworker cw
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS userid
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (cw.col_id = ul.userid)
                       LEFT JOIN tbl_caseworkerskill cws
                         ON cw.col_id = cws.col_sk_ppl_caseworker
                     /*WHERE NVL(cw.COL_ISDELETED, 0) = 0*/
                     ) LOOP
        SELECT COUNT(cws.col_sk_ppl_caseworker)
          INTO v_count
          FROM tbl_caseworkerskill cws
         WHERE cws.col_sk_ppl_caseworker = newObj.cwid
           AND cws.col_tbl_ppl_skill = v_ObjectId;
      
        IF (v_count = 0) THEN
          INSERT INTO tbl_caseworkerskill (col_sk_ppl_caseworker, col_tbl_ppl_skill) VALUES (newObj.cwid, v_ObjectId);
        END IF;
      END LOOP;
    END IF;
  
    --delete members
    IF (v_NotMembersList = 'ALL') THEN
      DELETE FROM tbl_caseworkerskill WHERE col_tbl_ppl_skill = v_ObjectId;
    ELSE
      FOR delObj IN (SELECT cw.col_id AS cwid
                       FROM tbl_ppl_caseworker cw
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS userid
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (cw.col_id = ul.userid)
                       LEFT JOIN tbl_caseworkerskill cws
                         ON cw.col_id = cws.col_sk_ppl_caseworker
                      WHERE /*NVL(cw.COL_ISDELETED, 0) = 0 AND */
                      cws.col_tbl_ppl_skill = v_ObjectId) LOOP
        IF (delObj.cwid IS NOT NULL) THEN
          DELETE FROM tbl_caseworkerskill tc
           WHERE tc.col_sk_ppl_caseworker = delObj.cwid
             AND tc.col_tbl_ppl_skill = v_ObjectId;
        END IF;
      END LOOP;
    END IF;
  END IF;

  --CASEWORKERS - BROLE
  IF (v_ObjectType = 'BUSINESSROLE' AND v_MembersType = 'CASEWORKERS') THEN
    --add members
    IF (v_MembersList = 'ALL') THEN
      INSERT INTO tbl_caseworkerbusinessrole
        (col_br_ppl_caseworker, col_tbl_ppl_businessrole)
        SELECT cw.id,
               v_ObjectId
          FROM vw_ppl_activecaseworkersusers cw
         WHERE cw.id NOT IN
               (SELECT cw1.id FROM vw_ppl_activecaseworkersusers cw1 INNER JOIN tbl_caseworkerbusinessrole tc1 ON cw1.id = tc1.col_br_ppl_caseworker WHERE tc1.col_tbl_ppl_businessrole = v_ObjectId);
    ELSE
      FOR newObj IN (SELECT cw.col_id AS cwid
                       FROM tbl_ppl_caseworker cw
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS userid
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (cw.col_id = ul.userid)
                       LEFT JOIN tbl_caseworkerbusinessrole tc
                         ON cw.col_id = tc.col_br_ppl_caseworker
                     /*WHERE NVL(cw.COL_ISDELETED, 0) = 0*/
                     ) LOOP
        SELECT COUNT(tc.col_br_ppl_caseworker)
          INTO v_count
          FROM tbl_caseworkerbusinessrole tc
         WHERE tc.col_br_ppl_caseworker = newObj.cwid
           AND tc.col_tbl_ppl_businessrole = v_ObjectId;
      
        IF (v_count = 0) THEN
          INSERT INTO tbl_caseworkerbusinessrole (col_br_ppl_caseworker, col_tbl_ppl_businessrole) VALUES (newObj.cwid, v_ObjectId);
        END IF;
      END LOOP;
    END IF;
  
    --delete members
    IF (v_NotMembersList = 'ALL') THEN
      DELETE FROM tbl_caseworkerbusinessrole WHERE col_tbl_ppl_businessrole = v_ObjectId;
    ELSE
      FOR delObj IN (SELECT cw.col_id AS cwid
                       FROM tbl_ppl_caseworker cw
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS userid
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (cw.col_id = ul.userid)
                       LEFT JOIN tbl_caseworkerbusinessrole tc
                         ON cw.col_id = tc.col_br_ppl_caseworker
                      WHERE /*NVL(cw.COL_ISDELETED, 0) = 0  AND */
                      tc.col_tbl_ppl_businessrole = v_ObjectId) LOOP
        IF (delObj.cwid IS NOT NULL) THEN
          DELETE FROM tbl_caseworkerbusinessrole tc
           WHERE tc.col_br_ppl_caseworker = delObj.cwid
             AND tc.col_tbl_ppl_businessrole = v_ObjectId;
        END IF;
      END LOOP;
    END IF;
  END IF;

  --WORKBASKET - TEAMS
  IF (v_ObjectType = 'WORKBASKET' AND v_MembersType = 'TEAMS') THEN
    --add members
    IF (v_MembersList = 'ALL') THEN
      INSERT INTO tbl_map_workbasketteam
        (col_map_wb_tm_team, col_map_wb_tm_workbasket)
        SELECT tpt.col_id,
               v_ObjectId
          FROM tbl_ppl_team tpt
         WHERE tpt.col_id NOT IN
               (SELECT tpt1.col_id FROM tbl_ppl_team tpt1 INNER JOIN tbl_map_workbasketteam tmw1 ON tpt1.col_id = tmw1.col_map_wb_tm_team WHERE tmw1.col_map_wb_tm_workbasket = v_ObjectId);
    ELSE
      FOR newObj IN (SELECT tpt.col_id AS WBTEAM
                       FROM tbl_ppl_team tpt
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS wbt
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (tpt.col_id = ul.wbt)) LOOP
        SELECT COUNT(tmw.col_map_wb_tm_team)
          INTO v_count
          FROM tbl_map_workbasketteam tmw
         WHERE tmw.col_map_wb_tm_team = newObj.wbteam
           AND tmw.col_map_wb_tm_workbasket = v_ObjectId;
      
        IF (v_count = 0) THEN
          INSERT INTO tbl_map_workbasketteam (col_map_wb_tm_team, col_map_wb_tm_workbasket) VALUES (newObj.wbteam, v_ObjectId);
        END IF;
      END LOOP;
    END IF;
  
    --delete members
    IF (v_NotMembersList = 'ALL') THEN
      DELETE FROM tbl_map_workbasketteam WHERE col_map_wb_tm_workbasket = v_ObjectId;
    ELSE
      FOR delObj IN (SELECT tpt.col_id AS wbteam
                       FROM tbl_ppl_team tpt
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS wbt
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (tpt.col_id = ul.wbt)
                       LEFT JOIN tbl_map_workbasketteam tmw
                         ON tpt.col_id = tmw.col_map_wb_tm_team
                      WHERE tmw.col_map_wb_tm_workbasket = v_ObjectId) LOOP
        IF (delObj.wbteam IS NOT NULL) THEN
          DELETE FROM tbl_map_workbasketteam tmw
           WHERE tmw.col_map_wb_tm_team = delObj.wbteam
             AND tmw.col_map_wb_tm_workbasket = v_ObjectId;
        END IF;
      END LOOP;
    END IF;
  END IF;

  --WORKBASKET - SKILLS
  IF (v_ObjectType = 'WORKBASKET' AND v_MembersType = 'SKILLS') THEN
    -- add members
    IF (v_MembersList = 'ALL') THEN
      INSERT INTO tbl_map_workbasketskill
        (col_map_ws_skill, col_map_ws_workbasket)
        SELECT ps.col_id,
               v_ObjectId
          FROM tbl_ppl_skill ps
         WHERE ps.col_id NOT IN (SELECT ps1.col_id FROM tbl_ppl_skill ps1 INNER JOIN tbl_map_workbasketskill tmw1 ON ps1.col_id = tmw1.col_map_ws_skill WHERE tmw1.col_map_ws_workbasket = v_ObjectId);
    ELSE
      FOR newObj IN (SELECT ps.col_id AS skillid
                       FROM tbl_ppl_skill ps
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS wbt
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (ps.col_id = ul.wbt)) LOOP
        SELECT COUNT(tmw.col_map_ws_skill)
          INTO v_count
          FROM tbl_map_workbasketskill tmw
         WHERE tmw.col_map_ws_skill = newObj.skillid
           AND tmw.col_map_ws_workbasket = v_ObjectId;
      
        IF (v_count = 0) THEN
          INSERT INTO tbl_map_workbasketskill (col_map_ws_skill, col_map_ws_workbasket) VALUES (newObj.skillid, v_ObjectId);
        END IF;
      END LOOP;
    END IF;
  
    --delete members
    IF (v_NotMembersList = 'ALL') THEN
      DELETE FROM tbl_map_workbasketskill WHERE col_map_ws_workbasket = v_ObjectId;
    ELSE
      FOR delObj IN (SELECT tpt.col_id AS skillid
                       FROM tbl_ppl_skill tpt
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS wbt
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (tpt.col_id = ul.wbt)
                       LEFT JOIN tbl_map_workbasketskill tmw
                         ON tpt.col_id = tmw.col_map_ws_skill
                      WHERE tmw.col_map_ws_workbasket = v_ObjectId) LOOP
        IF (delObj.skillid IS NOT NULL) THEN
          DELETE FROM tbl_map_workbasketskill tmw
           WHERE tmw.col_map_ws_skill = delObj.skillid
             AND tmw.col_map_ws_workbasket = v_ObjectId;
        END IF;
      END LOOP;
    END IF;
  END IF;

  --WORKBASKET - BROLE
  IF (v_ObjectType = 'WORKBASKET' AND v_MembersType = 'BUSINESSROLES') THEN
    -- add members
    IF (v_MembersList = 'ALL') THEN
      INSERT INTO tbl_map_workbasketbusnessrole
        (col_map_wb_wr_businessrole, col_map_wb_br_workbasket)
        SELECT tpb.col_id,
               v_ObjectId
          FROM tbl_ppl_businessrole tpb
         WHERE tpb.col_id NOT IN
               (SELECT tpb1.col_id FROM tbl_ppl_businessrole tpb1 INNER JOIN tbl_map_workbasketskill tmw1 ON tpb1.col_id = tmw1.col_map_ws_skill WHERE tmw1.col_map_ws_workbasket = v_ObjectId);
    ELSE
      FOR newObj IN (SELECT tpb.col_id AS wbrole
                       FROM tbl_ppl_businessrole tpb
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS wbr
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (tpb.col_id = ul.wbr)) LOOP
        SELECT COUNT(tmw.col_map_wb_br_workbasket)
          INTO v_count
          FROM tbl_map_workbasketbusnessrole tmw
         WHERE tmw.col_map_wb_wr_businessrole = newObj.wbrole
           AND tmw.col_map_wb_br_workbasket = v_ObjectId;
      
        IF (v_count = 0) THEN
          INSERT INTO tbl_map_workbasketbusnessrole (col_map_wb_br_workbasket, col_map_wb_wr_businessrole) VALUES (v_ObjectId, newObj.wbrole);
        END IF;
      END LOOP;
    END IF;
  
    --delete members
    IF (v_NotMembersList = 'ALL') THEN
      DELETE FROM tbl_map_workbasketbusnessrole WHERE col_map_wb_br_workbasket = v_ObjectId;
    ELSE
      FOR delObj IN (SELECT tpb.col_id AS wbrole
                       FROM tbl_ppl_businessrole tpb
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS wbr
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (tpb.col_id = ul.wbr)
                       LEFT JOIN tbl_map_workbasketbusnessrole tmw
                         ON tpb.col_id = tmw.col_map_wb_wr_businessrole
                      WHERE tmw.col_map_wb_br_workbasket = v_ObjectId) LOOP
        IF (delObj.wbrole IS NOT NULL) THEN
          DELETE FROM tbl_map_workbasketbusnessrole tmw
           WHERE tmw.col_map_wb_br_workbasket = v_ObjectId
             AND tmw.col_map_wb_wr_businessrole = delObj.wbrole;
        END IF;
      END LOOP;
    END IF;
  END IF;

  --WORKBASKET - CASEWORKERS
  IF (v_ObjectType = 'WORKBASKET' AND v_MembersType = 'CASEWORKERS') THEN
    -- add members
    IF (v_MembersList = 'ALL') THEN
      INSERT INTO tbl_map_workbasketcaseworker
        (col_map_wb_cw_caseworker, col_map_wb_cw_workbasket)
        SELECT tpc.id,
               v_ObjectId
          FROM vw_ppl_activecaseworkersusers tpc
         WHERE tpc.id NOT IN (SELECT tpc1.id
                                FROM vw_ppl_activecaseworkersusers tpc1
                               INNER JOIN tbl_map_workbasketcaseworker tmw1
                                  ON tpc1.id = tmw1.col_map_wb_cw_caseworker
                               WHERE tmw1.col_map_wb_cw_workbasket = v_ObjectId);
    ELSE
      FOR newObj IN (SELECT tpc.col_id AS cwid
                       FROM tbl_ppl_caseworker tpc
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS wbw
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_MembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (tpc.col_id = ul.wbw)) LOOP
        SELECT COUNT(tmw.col_map_wb_cw_caseworker)
          INTO v_count
          FROM tbl_map_workbasketcaseworker tmw
         WHERE tmw.col_map_wb_cw_caseworker = newObj.cwid
           AND tmw.col_map_wb_cw_workbasket = v_ObjectId;
      
        IF (v_count = 0) THEN
          INSERT INTO tbl_map_workbasketcaseworker (col_map_wb_cw_caseworker, col_map_wb_cw_workbasket) VALUES (newObj.cwid, v_ObjectId);
        END IF;
      END LOOP;
    END IF;
  
    --delete members
    IF (v_NotMembersList = 'ALL') THEN
      DELETE FROM tbl_map_workbasketcaseworker WHERE col_map_wb_cw_workbasket = v_ObjectId;
    ELSE
      FOR delObj IN (SELECT tpc.col_id AS cwid
                       FROM tbl_ppl_caseworker tpc
                      INNER JOIN (SELECT TO_NUMBER(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) AS wbw
                                   FROM dual
                                 CONNECT BY dbms_lob.getlength(regexp_substr(v_NotMembersList, '[[:' || 'alnum:]_]+', 1, LEVEL)) > 0) ul
                         ON (tpc.col_id = ul.wbw)
                       LEFT JOIN tbl_map_workbasketcaseworker tmw
                         ON tpc.col_id = tmw.col_map_wb_cw_caseworker
                      WHERE tmw.col_map_wb_cw_workbasket = v_ObjectId) LOOP
        IF (delObj.cwid IS NOT NULL) THEN
          DELETE FROM tbl_map_workbasketcaseworker tmw
           WHERE tmw.col_map_wb_cw_caseworker = delObj.cwid
             AND tmw.col_map_wb_cw_workbasket = v_ObjectId;
        END IF;
      END LOOP;
    END IF;
  END IF;

  --GENERATE SECURITY CACHE FOR ALL CASE TYPES
  --  v_result := f_DCM_createCTAccessCache();  -- a long time for a response

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;
