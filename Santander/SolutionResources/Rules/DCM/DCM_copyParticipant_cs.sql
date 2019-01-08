declare
    v_caseid      INTEGER; 
    v_casesystype INTEGER;
    v_caseCreator INTEGER;
    v_creatorsSupervisor INTEGER; 
    v_procedure INTEGER;
    sqlimmediate varchar2(255);
    resultimmediate NUMBER;
    
begin
    v_caseid := :CaseId;
    :ErrorCode := 0;
    :ErrorMessage := null;

    begin
        SELECT col_casedict_casesystype, COL_PROCEDURECASE, f_UTIL_getCWfromAcode(col_createdBy) ,F_PPL_GETSUPERVISOR2(CW=> f_UTIL_getCWfromAcode(col_createdBy))
        INTO   v_casesystype, v_procedure, v_caseCreator, v_creatorsSupervisor
        FROM   tbl_case
        WHERE  col_id = v_caseid;
    exception
        when NO_DATA_FOUND then
          v_casesystype := NULL;
		  v_procedure := NULL;
          :ErrorCode := 100;
          :ErrorMessage := 'DCM_copyParticipant: Case not found';
    end;

    if :ErrorCode != 100 then
      begin
          INSERT INTO tbl_caseparty
                      (col_name,
                       col_casepartycase,
                       col_casepartyppl_caseworker,
                       col_casepartyparticipant,
                       col_casepartyexternalparty,
                       col_casepartyppl_businessrole,
                       col_casepartyppl_skill,
                       col_casepartyppl_team,
                       col_casepartydict_unittype,
                       col_casepartytasksystype,
                       col_getprocessorcode,
                       col_customconfig,
                       col_allowDelete)
          (SELECT ptcp.col_name,
                  v_caseid,
                  --new part for DCM-2080 task--
                  case
                  when nvl(ptcp.col_isCreator,0) = 1 then
                  v_caseCreator
                  when nvl(ptcp.col_isSupervisor,0) = 1 then
                  v_creatorsSupervisor
                  else
                  --end new part for DCM-2080 task--
                  ptcp.col_participantppl_caseworker
                  end,
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
                              where  cseparty.col_casepartycase = v_caseid) 
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
  
      exception
          when DUP_VAL_ON_INDEX then
           :ErrorCode := 100;
           :ErrorMessage := 'DCM_copyParticipant: ' || SUBSTR(SQLERRM, 1, 200);
          when OTHERS then
           :ErrorCode := 100;
           :ErrorMessage := 'DCM_copyParticipant: ' || SUBSTR(SQLERRM, 1, 200);
      end;
    end if;
end;