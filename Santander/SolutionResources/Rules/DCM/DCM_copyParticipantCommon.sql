DECLARE

    v_insertedCasePartyId NUMBER; 
    v_Id                  NUMBER; 
    v_CaseId              NUMBER; 
    v_CaseSysTypeId       NUMBER;
    v_caseCreator         NUMBER;
    v_creatorsSupervisor  NUMBER; 
    v_ProcedureId         NUMBER;
    v_MilestoneId         NUMBER;
    resultimmediate       NUMBER;
    sqlimmediate          VARCHAR2(255);
    
BEGIN
  --input
  v_Id            := :Id;  
  v_caseid        := :CaseId;
  v_CaseSysTypeId := :CaseSysTypeId;
  v_ProcedureId   := :ProcedureId; 
  v_MilestoneId   := :MilestoneId;

  --output
  :ErrorCode := 0;
  :ErrorMessage := null;

  BEGIN
      SELECT f_UTIL_getCWfromAcode(col_createdBy) ,F_PPL_GETSUPERVISOR2(CW=> f_UTIL_getCWfromAcode(col_createdBy))
      INTO   v_caseCreator, v_creatorsSupervisor
      FROM   TBL_CASE
      WHERE  COL_ID = v_caseid;
  EXCEPTION
      when NO_DATA_FOUND then
        :ErrorCode := 100;
        :ErrorMessage := 'DCM_copyParticipantCommon: Case not found';
        --return -1;
  END;


  BEGIN
    FOR rec IN
    (
      SELECT ptcp.COL_NAME,              
              --new part for DCM-2080 task--
              CASE
                WHEN nvl(ptcp.COL_ISCREATOR,0) = 1 THEN v_caseCreator
                WHEN nvl(ptcp.COL_ISSUPERVISOR,0) = 1 THEN v_creatorsSupervisor
                ELSE
              --end new part for DCM-2080 task--
                ptcp.COL_PARTICIPANTPPL_CASEWORKER
              END AS CW,
              ptcp.COL_ID,
              ptcp.COL_PARTICIPANTEXTERNALPARTY,
              ptcp.COL_PARTICIPANTBUSINESSROLE,
              ptcp.COL_PARTICIPANTPPL_SKILL,
              ptcp.COL_PARTICIPANTTEAM,
              ptcp.COL_PARTICIPANTDICT_UNITTYPE,
              ptcp.COL_PARTICIPANTTASKSYSTYPE,
              ptcp.COL_GETPROCESSORCODE,
              ptcp.COL_CUSTOMCONFIG              
       FROM   TBL_PARTICIPANT ptcp
       LEFT JOIN TBL_DICT_CASESYSTYPE ct ON ct.COL_ID = ptcp.COL_PARTICIPANTCASESYSTYPE
       WHERE   (v_Id IS NULL OR ptcp.COL_ID = v_Id)
           AND (v_CaseSysTypeId IS NULL OR ptcp.COL_PARTICIPANTCASESYSTYPE = v_CaseSysTypeId)
           AND (v_ProcedureId IS NULL OR PTCP.COL_PARTICIPANTPROCEDURE = v_ProcedureId)
           AND (v_MilestoneId IS NULL OR (ct.COL_ID =
                                    (SELECT sc.COL_CASESYSTYPESTATECONFIG
                                     FROM TBL_DICT_STATECONFIG SC 
                                     WHERE SC.COL_ID = v_MilestoneId)))
           --exclude existing caseworker(s)
/*
           AND ptcp.COL_PARTICIPANTPPL_CASEWORKER NOT IN
              (SELECT COL_CASEPARTYPPL_CASEWORKER
               FROM TBL_CASEPARTY cp1
               WHERE COL_CASEPARTYCASE=v_caseid)*/
  
      )
      --main loop
      LOOP
      INSERT INTO TBL_CASEPARTY
                  (COL_NAME,
                   COL_CASEPARTYCASE,
                   COL_CASEPARTYPPL_CASEWORKER,
                   COL_CASEPARTYPARTICIPANT,
                   COL_CASEPARTYEXTERNALPARTY,
                   COL_CASEPARTYPPL_BUSINESSROLE,
                   COL_CASEPARTYPPL_SKILL,
                   COL_CASEPARTYPPL_TEAM,
                   COL_CASEPARTYDICT_UNITTYPE,
                   COL_CASEPARTYTASKSYSTYPE,
                   COL_GETPROCESSORCODE,
                   COL_CUSTOMCONFIG,
                   COL_ALLOWDELETE)
      VALUES
      (
        rec.COL_NAME,
        v_caseid,
        rec.CW,
        rec.COL_ID,
        rec.COL_PARTICIPANTEXTERNALPARTY,
        rec.COL_PARTICIPANTBUSINESSROLE,
        rec.COL_PARTICIPANTPPL_SKILL,
        rec.COL_PARTICIPANTTEAM,
        rec.COL_PARTICIPANTDICT_UNITTYPE,
        rec.COL_PARTICIPANTTASKSYSTYPE,
        rec.COL_GETPROCESSORCODE,
        rec.COL_CUSTOMCONFIG,
        0
      ) RETURNING COL_ID INTO v_insertedCasePartyId;
     

      --new part for DCM-2080 task--
      for loopIteration in (select
                          cseparty.col_id as id,
                          dict.col_code as code,
                          ptcp.col_getprocessorcode2 as processorcode,
                          ptcp.col_issupervisor as issupervisor,
                          ptcp.col_iscreator as iscreator,
                          ptcp.col_participantppl_caseworker as defaultCaseWorker
                          from tbl_caseparty cseparty
                          left join  tbl_participant ptcp on cseparty.col_casepartyparticipant = ptcp.col_id
                          left join  tbl_dict_participantunittype dict on dict.col_id = ptcp.col_participantdict_unittype
                          where  cseparty.col_id=v_insertedCasePartyId) 
      loop 

          --execute finction--             
          begin
              sqlimmediate :='select '||REPLACE(loopIteration.processorcode,'root_','f_')||'(CasePartyId=> '||loopIteration.id||', CaseId =>'||v_caseid||') from dual';
              EXECUTE IMMEDIATE sqlimmediate into resultimmediate;

          exception  when OTHERS then
              resultimmediate := 0;
              sqlimmediate:=null;
          end;

          sqlimmediate:= null;

          --update tbl_caseparty--
          begin
              if (loopIteration.code = 'CASEWORKER' and nvl(loopIteration.issupervisor,0) = 0 and nvl(loopIteration.iscreator,0) = 0 and nvl(resultimmediate,0) != 0) then
                  sqlimmediate :='update tbl_caseparty set col_casepartyppl_caseworker ='||resultimmediate||' where col_id ='||loopIteration.id;
              ELSIF loopIteration.code = 'BUSINESSROLE' and nvl(resultimmediate,0) != 0 THEN
                  sqlimmediate :='update tbl_caseparty set col_casepartyppl_businessrole ='||resultimmediate||' where col_id ='||loopIteration.id;
              ELSIF loopIteration.code = 'EXTERNAL_PARTY' and nvl(resultimmediate,0) != 0 THEN
                  sqlimmediate :='update tbl_caseparty set col_casepartyexternalparty ='||resultimmediate||' where col_id ='||loopIteration.id;
              ELSIF loopIteration.code = 'SKILL' and nvl(resultimmediate,0) != 0 THEN
                  sqlimmediate :='update tbl_caseparty set col_casepartyppl_skill ='||resultimmediate||' where col_id ='||loopIteration.id;
              ELSIF loopIteration.code = 'TEAM'  and nvl(resultimmediate,0) != 0 THEN
                  sqlimmediate :='update tbl_caseparty set col_casepartyppl_team ='||resultimmediate||' where col_id ='||loopIteration.id;     
              end if;

              if sqlimmediate is not null then   
                  EXECUTE IMMEDIATE sqlimmediate;
              end if;


          exception  when OTHERS then
              resultimmediate := 0;
              sqlimmediate:= null;
              
          end;
          resultimmediate := 0;
          sqlimmediate:= null;

      end loop;
      --end new part for DCM-2080 task--

    --main loop
   END LOOP;

    EXCEPTION
        when DUP_VAL_ON_INDEX then
         :ErrorCode := 100;
         :ErrorMessage := 'DCM_copyParticipantCommon: ' || SUBSTR(SQLERRM, 1, 200);
         --return -1;
        when OTHERS then
         :ErrorCode := 100;
         :ErrorMessage := 'DCM_copyParticipantCommon: ' || SUBSTR(SQLERRM, 1, 200);
         --return -1;
    END;
END;