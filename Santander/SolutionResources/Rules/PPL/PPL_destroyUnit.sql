DECLARE
  v_objecttype      NVARCHAR2(255);
  v_objectid        INTEGER;
  v_count_case      INTEGER;
  v_count_task      INTEGER;
  v_count_extparty  INTEGER;
  v_count_caseparty INTEGER;
  v_errorCode       NUMBER;
  v_errorMessage    NCLOB;
  v_count_temp      INTEGER;
  v_UnitCode        NVARCHAR2(255);
  v_DeletedRows     PLS_INTEGER;
  v_result          NUMBER;

  CURSOR Participant IS
    SELECT COL_CUSTOMCONFIG AS CustomConfig
      FROM TBL_PARTICIPANT
     WHERE DBMS_LOB.GETLENGTH(COL_CUSTOMCONFIG) != 0
       AND DBMS_LOB.GETLENGTH(COL_CUSTOMCONFIG) IS NOT NULL;

  CURSOR CaseParty IS
    SELECT COL_CUSTOMCONFIG AS CustomConfig
      FROM TBL_CASEPARTY
     WHERE DBMS_LOB.GETLENGTH(COL_CUSTOMCONFIG) != 0
       AND DBMS_LOB.GETLENGTH(COL_CUSTOMCONFIG) IS NOT NULL;

  PROCEDURE getCountInXML(xPath IN NVARCHAR2, XML IN NCLOB, UnitCode IN NVARCHAR2, counter OUT INTEGER) AS
  BEGIN
    SELECT COUNT(*) INTO counter FROM XMLTABLE(xPath PASSING xmlType(XML) COLUMNS unit NVARCHAR2(255) PATH 'text()') WHERE unit = UnitCode;
  END;

BEGIN
  BEGIN
    v_errorMessage := '';
    v_errorCode    := 0;
    :affectedRows  := 0;
    v_count_temp   := 0;
    :SuccessResponse := EMPTY_CLOB();
  
    v_objecttype := UPPER(:OBJECTTYPE);
    v_objectid   := :ID;
  
    -- validation for input parameters
    IF (v_objecttype = '' OR v_objecttype IS NULL) THEN
      v_errorMessage := 'ObjectType could not be empty';
      v_errorCode := 1;
      GOTO cleanup;
    END IF;
  
    IF (v_objectid = '' OR v_objectid IS NULL) THEN
      v_errorMessage := 'ObjectId could not be empty';
      v_errorCode    := 2;
      GOTO cleanup;
    END IF;
  
    CASE v_objecttype
      WHEN 'TEAM' THEN
        BEGIN
          -- relationships validation for case party
          SELECT COUNT(*)
            INTO v_count_caseparty
            FROM tbl_caseparty
           WHERE col_casepartyppl_team = v_objectid
             AND ROWNUM = 1;
        
          IF (v_count_caseparty > 0) THEN
            v_errorMessage := 'There is Team in Case Party. Please delete them first from Case Party and then try deleting again';
            v_errorCode    := 5;
            GOTO cleanup;
          END IF;
        
          SELECT col_code INTO v_UnitCode FROM tbl_ppl_team WHERE col_id = v_objectid;
        
          v_count_temp := 0;
          FOR rec IN CaseParty LOOP
            getCountInXML('/CustomData/Attributes/FILTER_TEAM', rec.CustomConfig, v_UnitCode, v_count_temp);
            IF v_count_temp != 0 THEN
              EXIT;
            END IF;
          
            getCountInXML('/CustomData/Attributes/FILTER_ParentTeam', rec.CustomConfig, v_UnitCode, v_count_temp);
            IF v_count_temp != 0 THEN
              EXIT;
            END IF;
          END LOOP;
        
          IF (v_count_temp > 0) THEN
            v_errorMessage := 'There is Team in Case Party. Please delete them first from Case Party and then try deleting again';
            v_errorCode    := 5;
            GOTO cleanup;
          END IF;
        
          -- relationships validation for Workbasket
          SELECT COUNT(*)
            INTO v_count_case
            FROM tbl_case
           WHERE col_caseppl_workbasket = (SELECT col_map_wb_tm_workbasket FROM tbl_map_workbasketteam WHERE col_map_wb_tm_team = v_objectid)
             AND ROWNUM = 1;
        
          IF (v_count_case > 0) THEN
            v_errorMessage := 'There is Team in the Case. Please unassign first from the Case and then try deleting again';
            v_errorCode    := 8;
            GOTO cleanup;
          END IF;
        
          SELECT COUNT(*)
            INTO v_count_task
            FROM tbl_task
           WHERE col_taskppl_workbasket = (SELECT col_map_wb_tm_workbasket FROM tbl_map_workbasketteam WHERE col_map_wb_tm_team = v_objectid)
             AND ROWNUM = 1;
        
          IF (v_count_task > 0) THEN
            v_errorMessage := 'There is Team in the Task. Please unassign first from the Task and then try deleting again';
            v_errorCode    := 9;
            GOTO cleanup;
          END IF;
        
          -- relationships validation for External Party
          SELECT COUNT(*)
            INTO v_count_extparty
            FROM tbl_externalparty
           WHERE col_externalpartyworkbasket = (SELECT col_map_wb_tm_workbasket FROM tbl_map_workbasketteam WHERE col_map_wb_tm_team = v_objectid)
             AND ROWNUM = 1;
        
          IF (v_count_extparty > 0) THEN
            v_errorMessage := 'There is Team in the External Party. Please unassign first from the External Party and then try deleting again';
            v_errorCode    := 10;
            GOTO cleanup;
          END IF;
        
          -- relationships validation for Participant
          v_count_temp := 0;
          SELECT COUNT(*)
            INTO v_count_temp
            FROM TBL_PARTICIPANT
           WHERE COL_PARTICIPANTTEAM = v_objectid
             AND ROWNUM = 1;
        
          IF (v_count_temp > 0) THEN
            v_errorMessage := 'There is Team in the Participant. Please unassign first from the Participant and then try deleting again';
            v_errorCode    := 14;
            GOTO cleanup;
          END IF;
        
          v_count_temp := 0;
          FOR rec IN Participant LOOP
            getCountInXML('/CustomData/Attributes/FILTER_TEAM', rec.CustomConfig, v_UnitCode, v_count_temp);
            IF v_count_temp != 0 THEN
              EXIT;
            END IF;
          
            getCountInXML('/CustomData/Attributes/FILTER_ParentTeam', rec.CustomConfig, v_UnitCode, v_count_temp);
            IF v_count_temp != 0 THEN
              EXIT;
            END IF;
          END LOOP;
        
          IF (v_count_temp > 0) THEN
            v_errorMessage := 'There is Team in the Participant. Please unassign first from the Participant and then try deleting again';
            v_errorCode    := 14;
            GOTO cleanup;
          END IF;
        
          -- delete
          DELETE FROM tbl_ppl_workbasket WHERE col_workbasketteam = v_objectid;
        
          DELETE FROM tbl_ac_acl
           WHERE col_aclaccesssubject IN
                 (SELECT col_id FROM tbl_ac_accesssubject WHERE col_id = (SELECT col_teamaccesssubject FROM tbl_ppl_team WHERE col_id = v_objectid));
        
          DELETE FROM tbl_ac_accesssubject WHERE col_id = (SELECT col_teamaccesssubject FROM tbl_ppl_team WHERE col_id = v_objectid);
        
          -- delete Documents
          v_count_temp := f_doc_destroydocumentfn(case_id                 => NULL,
                                                  casetype_id             => NULL,
                                                  caseworker_id           => NULL,
                                                  errorcode               => v_errorCode,
                                                  errormessage            => v_errorMessage,
                                                  extparty_id             => NULL,
                                                  ids                     => NULL,
                                                  task_id                 => NULL,
                                                  team_id                 => v_objectid,
                                                  token_domain            => '@TOKEN_DOMAIN@',
                                                  token_useraccesssubject => '@TOKEN_USERACCESSSUBJECT@');
        
          DELETE FROM tbl_ppl_team WHERE col_id = v_objectid;
          v_DeletedRows := SQL%ROWCOUNT;
        END;
      
      WHEN 'BUSINESSROLE' THEN
      
        BEGIN
          -- relationships validation for case party
          SELECT COUNT(*)
            INTO v_count_caseparty
            FROM tbl_caseparty
           WHERE col_casepartyppl_businessrole = v_objectid
             AND ROWNUM = 1;
        
          IF (v_count_caseparty > 0) THEN
            v_errorMessage := 'There is Business Role in Case Party. Please delete them first from Case Party and then try deleting again';
            v_errorCode := 6;
            GOTO cleanup;
          END IF;
        
          SELECT col_code INTO v_UnitCode FROM TBL_PPL_BUSINESSROLE WHERE col_id = v_objectid;
        
          v_count_temp := 0;
          FOR rec IN CaseParty LOOP
            getCountInXML('/CustomData/Attributes/FILTER_BUSINESSROLE', rec.CustomConfig, v_UnitCode, v_count_temp);
            IF v_count_temp != 0 THEN
              EXIT;
            END IF;
          END LOOP;
        
          IF (v_count_temp > 0) THEN
            v_errorMessage := 'There is Business Role in Case Party. Please delete them first from Case Party and then try deleting again';
            v_errorCode := 6;
            GOTO cleanup;
          END IF;
        
          -- relationships validation for Workbasket
          SELECT COUNT(*)
            INTO v_count_case
            FROM tbl_case
           WHERE col_caseppl_workbasket =
                 (SELECT col_map_wb_br_workbasket FROM tbl_map_workbasketbusnessrole WHERE col_map_wb_wr_businessrole = v_objectid)
             AND ROWNUM = 1;
        
          IF (v_count_case > 0) THEN
            v_errorMessage := 'There is Business Role in the Case. Please unassign first from the Case and then try deleting again';
            v_errorCode := 11;
            GOTO cleanup;
          END IF;
        
          SELECT COUNT(*)
            INTO v_count_task
            FROM tbl_task
           WHERE col_taskppl_workbasket =
                 (SELECT col_map_wb_br_workbasket FROM tbl_map_workbasketbusnessrole WHERE col_map_wb_wr_businessrole = v_objectid)
             AND ROWNUM = 1;
        
          IF (v_count_task > 0) THEN
            v_errorMessage := 'There is Business Role in the Task. Please unassign first from the Task and then try deleting again';
            v_errorCode    := 12;
            GOTO cleanup;
          END IF;
        
          -- relationships validation for External Party
          SELECT COUNT(*)
            INTO v_count_extparty
            FROM tbl_externalparty
           WHERE col_externalpartyworkbasket =
                 (SELECT col_map_wb_br_workbasket FROM tbl_map_workbasketbusnessrole WHERE col_map_wb_wr_businessrole = v_objectid)
             AND ROWNUM = 1;
        
          IF (v_count_extparty > 0) THEN
            v_errorMessage := 'There is Business Role in the External Party. Please unassign first from the External Party and then try deleting again';
            v_errorCode    := 13;
            GOTO cleanup;
          END IF;
        
          -- relationships validation for Participant
          v_count_temp := 0;
          SELECT COUNT(*)
            INTO v_count_temp
            FROM TBL_PARTICIPANT
           WHERE COL_PARTICIPANTBUSINESSROLE = v_objectid
             AND ROWNUM = 1;
        
          IF (v_count_temp > 0) THEN
            v_errorMessage := 'There is Business Role in the Participant. Please unassign first from the Participant and then try deleting again';
            v_errorCode    := 15;
            GOTO cleanup;
          END IF;
        
          v_count_temp := 0;
          FOR rec IN Participant LOOP
            getCountInXML('/CustomData/Attributes/FILTER_BUSINESSROLE', rec.CustomConfig, v_UnitCode, v_count_temp);
            IF v_count_temp != 0 THEN
              EXIT;
            END IF;
          END LOOP;
        
          IF (v_count_temp > 0) THEN
            v_errorMessage := 'There is Business Role in the Participant. Please unassign first from the Participant and then try deleting again';
            v_errorCode    := 15;
            GOTO cleanup;
          END IF;
        
          -- delete
          DELETE FROM tbl_ppl_workbasket WHERE col_workbasketbusinessrole = v_objectid;
        
          DELETE FROM tbl_ac_acl
           WHERE col_aclaccesssubject IN
                 (SELECT col_id
                    FROM tbl_ac_accesssubject
                   WHERE col_id = (SELECT col_businessroleaccesssubject FROM tbl_ppl_businessrole WHERE col_id = v_objectid));
        
          DELETE FROM tbl_ac_accesssubject WHERE col_id = (SELECT col_businessroleaccesssubject FROM tbl_ppl_businessrole WHERE col_id = v_objectid);
        
          DELETE FROM tbl_ppl_businessrole WHERE col_id = v_objectid;
          v_DeletedRows := SQL%ROWCOUNT;
        END;
      
      WHEN 'SKILL' THEN
        BEGIN
          -- relationships validation for case party
          SELECT COUNT(*)
            INTO v_count_caseparty
            FROM tbl_caseparty
           WHERE col_casepartyppl_skill = v_objectid
             AND ROWNUM = 1;
        
          IF (v_count_caseparty > 0) THEN
            v_errorMessage := 'There is Skill in Case Party. Please delete them first from Case Party and then try deleting again';
            v_errorCode    := 7;
            GOTO cleanup;
          END IF;
        
          SELECT col_code INTO v_UnitCode FROM TBL_PPL_SKILL WHERE col_id = v_objectid;
        
          v_count_temp := 0;
          FOR rec IN CaseParty LOOP
            getCountInXML('/CustomData/Attributes/FILTER_SKILL', rec.CustomConfig, v_UnitCode, v_count_temp);
            IF v_count_temp != 0 THEN
              EXIT;
            END IF;
          END LOOP;
        
          IF (v_count_temp > 0) THEN
            v_errorMessage := 'There is Skill in Case Party. Please delete them first from Case Party and then try deleting again';
            v_errorCode    := 7;
            GOTO cleanup;
          END IF;
        
          -- relationships validation for Participant
          v_count_temp := 0;
          SELECT COUNT(*)
            INTO v_count_temp
            FROM TBL_PARTICIPANT
           WHERE COL_PARTICIPANTPPL_SKILL = v_objectid
             AND ROWNUM = 1;
        
          IF (v_count_temp > 0) THEN
            v_errorMessage := 'There is Skill in the Participant. Please unassign first from the Participant and then try deleting again';
            v_errorCode    := 16;
            GOTO cleanup;
          END IF;
        
          v_count_temp := 0;
          FOR rec IN Participant LOOP
            getCountInXML('/CustomData/Attributes/FILTER_SKILL', rec.CustomConfig, v_UnitCode, v_count_temp);
            IF v_count_temp != 0 THEN
              EXIT;
            END IF;
          END LOOP;
        
          IF (v_count_temp > 0) THEN
            v_errorMessage := 'There is Skill in the Participant. Please unassign first from the Participant and then try deleting again';
            v_errorCode    := 16;
            GOTO cleanup;
          END IF;
        
          -- delete
          DELETE FROM tbl_ppl_workbasket WHERE col_workbasketskill = v_objectid;
          DELETE FROM tbl_ac_acl
           WHERE col_aclaccesssubject IN
                 (SELECT col_id FROM tbl_ac_accesssubject WHERE col_id = (SELECT col_skillaccesssubject FROM tbl_ppl_skill WHERE col_id = v_objectid));
        
          DELETE FROM tbl_ac_accesssubject WHERE col_id = (SELECT col_skillaccesssubject FROM tbl_ppl_skill WHERE col_id = v_objectid);
        
          DELETE FROM tbl_ppl_skill WHERE col_id = v_objectid;
          v_DeletedRows := SQL%ROWCOUNT;
        END;
      
      WHEN 'WORKBASKET' THEN
        BEGIN
          SELECT COUNT(*)
            INTO v_count_case
            FROM tbl_case
           WHERE col_caseppl_workbasket = v_objectid
             AND ROWNUM = 1;
        
          SELECT COUNT(*)
            INTO v_count_task
            FROM tbl_task
           WHERE col_taskppl_workbasket = v_objectid
             AND ROWNUM = 1;
        
          SELECT COUNT(*)
            INTO v_count_extparty
            FROM tbl_externalparty
           WHERE col_externalpartyworkbasket = v_objectid
             AND ROWNUM = 1;
        
          IF (v_count_case > 0 OR v_count_task > 0 OR v_count_extparty > 0) THEN
            BEGIN
              v_errorMessage := 'There are Tasks or Cases or External Party in this Work Basket. Please re-assign them first and then try deleting again';
              v_errorCode    := 3;
              GOTO cleanup;
            END;
          ELSE
            BEGIN
              DELETE FROM tbl_ppl_workbasket WHERE col_id = v_objectid;
              v_DeletedRows := SQL%ROWCOUNT;
            END;
          END IF;
        END;
      ELSE
        v_errorMessage := 'Unknown object type';
        v_errorCode := 4;
    END CASE;
  EXCEPTION
    WHEN OTHERS THEN
      v_errorMessage := SQLERRM;
      v_errorCode    := SQLCODE;
      :affectedRows  := -1;
  END;
  
  v_result := LOC_I18N(
    MessageText => 'Deleted {{MESS_COUNT}} items',
    MessageResult => :SuccessResponse,
    MessageParams => NES_TABLE(Key_Value('MESS_COUNT', v_DeletedRows))
  );

  <<cleanup>>
  :errorMessage := v_errorMessage;
  :errorCode    := v_errorCode;
  :affectedRows := v_DeletedRows;
EXCEPTION 
  WHEN OTHERS THEN
    :errorMessage := SQLERRM();
    :errorCode    := SQLCODE();
END;