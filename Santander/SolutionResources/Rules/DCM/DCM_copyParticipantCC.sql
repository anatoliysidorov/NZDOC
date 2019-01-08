declare
    v_caseid      INTEGER; 
    v_casesystype INTEGER; 
	v_procedure INTEGER; 
begin
    v_caseid := :CaseId;
    :ErrorCode := 0;
    :ErrorMessage := null;

    begin
        SELECT col_caseccdict_casesystype, col_procedurecasecc
        INTO   v_casesystype, v_procedure
        FROM   tbl_casecc
        WHERE  col_id = v_caseid;
    exception
        when NO_DATA_FOUND then
          v_casesystype := NULL;
		  v_procedure := NULL;
          :ErrorCode := 100;
          :ErrorMessage := 'DCM_copyParticipantCC: Case not found';
          return -1;
    end;

    begin
        INSERT INTO tbl_casepartycc
                    (col_name,
                     col_casepartycccasecc,
                     col_casepartyccppl_caseworker,
                     col_casepartyccparticipant,
                     col_casepartyccexternalparty,
                     col_casepartycc_businessrole,
                     col_casepartyccppl_skill,
                     col_casepartyccppl_team,
                     col_casepartyccdict_unittype,
                     col_casepartycctasksystype,
                     col_getprocessorcode,
                     col_customconfig,
                     col_allowDelete)
        (SELECT ptcp.col_name,
                v_caseid,
                ptcp.col_participantppl_caseworker,
                ptcp.col_id,
                ptcp.col_participantexternalparty,
                ptcp.col_participantbusinessrole,
                ptcp.col_participantppl_skill,
                ptcp.col_participantteam,
                ptcp.col_participantdict_unittype,
                ptcp.col_participanttasksystype,
                col_getprocessorcode,
                col_customconfig,
                0
         FROM   tbl_participant ptcp
         WHERE  col_participantcasesystype = v_casesystype OR
        col_participantprocedure = v_procedure
         );
    exception
        when DUP_VAL_ON_INDEX then
         :ErrorCode := 100;
         :ErrorMessage := 'DCM_copyParticipantCC: ' || SUBSTR(SQLERRM, 1, 200);
          return -1;
        when OTHERS then
         :ErrorCode := 100;
         :ErrorMessage := 'DCM_copyParticipantCC: ' || SUBSTR(SQLERRM, 1, 200);
         return -1;
    end;
end;