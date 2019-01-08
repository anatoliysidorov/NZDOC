DECLARE
  v_caseid              INTEGER; 
  v_casesystype         INTEGER;
  v_caseCreator         INTEGER;
  v_creatorsSupervisor  INTEGER; 
  v_procedure           INTEGER;
  sqlimmediate          VARCHAR2(2000);
  resultimmediate       NUMBER; 
  v_CSisInCache         INTEGER;
  v_userAxs             VARCHAR2(255);
  v_cpId                NUMBER;

BEGIN

  --IN
  v_caseid := :CaseId;

 --OUT 
  :ErrorCode := 0;
  :ErrorMessage := NULL;

  --INIT
  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache

  --case not in cache
  IF v_CSisInCache=0 THEN

    BEGIN
      SELECT COL_CASEDICT_CASESYSTYPE, COL_PROCEDURECASE, 
             f_UTIL_getCWfromAcode(col_createdBy), 
             F_PPL_GETSUPERVISOR2(CW=> f_UTIL_getCWfromAcode(col_createdBy))
      INTO   v_casesystype, v_procedure, v_caseCreator, v_creatorsSupervisor
      FROM   tbl_case
      WHERE  col_id = v_caseid;
    EXCEPTION
        when NO_DATA_FOUND then
          v_casesystype := NULL;
		      v_procedure := NULL;
          
          :ErrorCode := 100;
          :ErrorMessage := 'DCM_copyParticipant: Case not found';
          RETURN -1;
    end;

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
          RETURN -1;
        when OTHERS then
         :ErrorCode := 100;
         :ErrorMessage := 'DCM_copyParticipant: ' || SUBSTR(SQLERRM, 1, 200);
         RETURN -1;
    end;
  END IF;



  --case in cache
  IF v_CSisInCache=1 THEN

	  SELECT SYS_CONTEXT ('CLIENTCONTEXT', 'AccessSubject') INTO v_userAxs FROM dual;

    BEGIN
      SELECT COL_CASEDICT_CASESYSTYPE, COL_PROCEDURECASE, 
             f_UTIL_getCWfromAcode(v_userAxs), 
             F_PPL_GETSUPERVISOR2(CW=> f_UTIL_getCWfromAcode(v_userAxs))
      INTO   v_casesystype, v_procedure, v_caseCreator, v_creatorsSupervisor
      FROM   TBL_CSCASE
      WHERE  COL_ID = v_caseid;
    EXCEPTION
        when NO_DATA_FOUND then
          v_casesystype := NULL;
		      v_procedure := NULL;

          :ErrorCode := 100;
          :ErrorMessage := 'DCM_copyParticipant: Case not found';
          RETURN -1;
    END;

    BEGIN

      FOR rec IN
      (
        SELECT ptcp.col_name, 
                --new part for DCM-2080 task--
                CASE
                  WHEN NVL(ptcp.col_isCreator,0) = 1 THEN v_caseCreator
                  WHEN nvl(ptcp.col_isSupervisor,0) = 1 THEN v_creatorsSupervisor
                ELSE
                --end new part for DCM-2080 task--
                  ptcp.col_participantppl_caseworker
                END AS CaseWorker,
                ptcp.col_id, ptcp.col_participantexternalparty, ptcp.col_participantbusinessrole,
                ptcp.col_participantppl_skill, ptcp.col_participantteam, ptcp.col_participantdict_unittype,
                ptcp.col_participanttasksystype, ptcp.col_getprocessorcode, ptcp.col_getprocessorcode2, 
                ptcp.col_customconfig, 0, dict.col_code as code,
                ptcp.col_issupervisor as issupervisor,
                ptcp.col_iscreator as iscreator
         FROM TBL_PARTICIPANT ptcp
         LEFT JOIN  TBL_DICT_PARTICIPANTUNITTYPE dict on dict.col_id = ptcp.col_participantdict_unittype
         WHERE  col_participantcasesystype = v_casesystype OR col_participantprocedure = v_procedure
         )
      LOOP

        SELECT gen_tbl_CaseParty.nextval INTO v_cpId FROM dual;

        --customize
        resultimmediate := 0;
        sqlimmediate:=null;

        IF rec.col_getprocessorcode2 IS NOT NULL THEN
          --execute function--             
          BEGIN
              sqlimmediate :='select '||REPLACE(rec.col_getprocessorcode2,'root_','f_')||'(CasePartyId=> '||v_cpId||', CaseId =>'||v_caseid||') from dual';
              EXECUTE IMMEDIATE sqlimmediate into resultimmediate;
    
          EXCEPTION  WHEN OTHERS THEN
              resultimmediate := 0;
              sqlimmediate:=null;
          END;                 
        END IF;

        IF NVL(resultimmediate, 0)<>0 THEN
          IF (rec.code = 'CASEWORKER' and NVL(rec.issupervisor,0) = 0 and 
                                          NVL(rec.iscreator,0) = 0) THEN rec.CaseWorker:= resultimmediate;
          ELSIF rec.code = 'BUSINESSROLE'  THEN rec.col_participantbusinessrole:=resultimmediate;
          ELSIF rec.code = 'EXTERNAL_PARTY'  THEN rec.col_participantexternalparty := resultimmediate;
          ELSIF rec.code = 'SKILL'  THEN rec.col_participantppl_skill := resultimmediate;
          ELSIF rec.code = 'TEAM'   THEN rec.col_participantteam := resultimmediate;     
          END IF;                
        END IF;

        INSERT INTO TBL_CSCASEPARTY (COL_ID,  COL_NAME, COL_CASEPARTYCASE, COL_CASEPARTYPPL_CASEWORKER,
                                     COL_CASEPARTYPARTICIPANT, COL_CASEPARTYEXTERNALPARTY,
                                     COL_CASEPARTYPPL_BUSINESSROLE, COL_CASEPARTYPPL_SKILL,
                                     COL_CASEPARTYPPL_TEAM, COL_CASEPARTYDICT_UNITTYPE,
                                     COL_CASEPARTYTASKSYSTYPE, COL_GETPROCESSORCODE,
                                     COL_CUSTOMCONFIG, COL_ALLOWDELETE)
        VALUES(v_cpId, rec.col_name, v_caseid, rec.CaseWorker,       
               rec.col_id,  rec.col_participantexternalparty, rec.col_participantbusinessrole,
               rec.col_participantppl_skill, rec.col_participantteam, rec.col_participantdict_unittype,
               rec.col_participanttasksystype, rec.col_getprocessorcode,  rec.col_customconfig, 0);
      END LOOP;  
    END;       
  END IF;
END;