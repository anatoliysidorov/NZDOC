BEGIN 
    DECLARE 
        v_errorcode         NUMBER; 
        v_errormessage      NVARCHAR2(255); 
		v_name      		NVARCHAR2(255); 
        v_rowcount          INTEGER; 
        v_case_id           INTEGER; 
        v_partytype_id      INTEGER; 
        v_participant_id    INTEGER; 
        v_externalparty_ids NVARCHAR2(255); 
        v_caseworker_ids    NVARCHAR2(255); 
        v_participant_code  NVARCHAR2(255); 
    BEGIN 
        BEGIN 
            v_errorcode := 0; 
            v_errormessage := '';
			v_name := :Name;
            :affectedRows := 0; 
            v_case_id := :Case_Id; 
            v_partytype_id := :PartyType_Id; 
            v_participant_id := :Participant_Id; 			
            v_externalparty_ids := :ExternalParty_Ids; 
            v_caseworker_ids := :CaseWorker_Ids; 
            v_rowcount := 0; 

            -- check if case is exists   
            SELECT Count(col_id) 
            INTO   v_rowcount 
            FROM   tbl_case 
            WHERE  col_id = v_case_id; 

            IF( v_rowcount = 0 ) THEN 
              v_errormessage := 'Case not found'; 
              v_errorcode := 1; 
              GOTO cleanup; 
            END IF; 

            -- check if party type is exists   
            SELECT Count(col_id) 
            INTO   v_rowcount 
            FROM   tbl_dict_partytype 
            WHERE  col_id = v_partytype_id; 

            IF( v_rowcount = 0 ) THEN 
              v_errormessage := 'Party type not found'; 
              v_errorcode := 2; 
              GOTO cleanup; 
            END IF; 

            -- check if participant is exists   
            SELECT Count(col_id) 
            INTO   v_rowcount 
            FROM   tbl_participant 
            WHERE  col_id = v_participant_id; 

            IF( v_rowcount = 0 ) THEN 
              v_errormessage := 'Participant not found'; 
              v_errorcode := 3; 
              GOTO cleanup; 
            END IF; 

            -- get participant type by partytype   
            BEGIN 
                SELECT participt.col_code 
                INTO   v_participant_code 
                FROM   tbl_dict_partytype pt 
                       inner join tbl_dict_participanttype participt 
                               ON participt.col_id = 
                                  pt.col_partytypeparticiptype 
                WHERE  pt.col_id = v_partytype_id; 
            EXCEPTION 
                WHEN no_data_found THEN 
                  v_errormessage := 'Participant type for party type not found'; 
                  v_errorcode := 4; 
                  GOTO cleanup; 
            END; 
			
			--DELETE OLD RECORDS ASSOCIATED WITH THIS CASE AND PARTICIPANT
			DELETE FROM TBL_caseparty
			WHERE col_casepartycase = v_case_id
			AND col_AllowDelete = 1
            AND col_casepartyparticipant = v_participant_id;			

            IF( v_participant_code = 'INTERNAL' ) THEN 
              FOR rec IN (SELECT column_value AS CaseWorkerId 
                          FROM   TABLE(Asf_splitclob(v_caseworker_ids, '|||'))) 
              LOOP 
                  INSERT INTO tbl_caseparty 
                              (col_casepartycase, 
							  col_name,
                               col_casepartydict_partytype, 
                               col_casepartyparticipant, 
                               col_casepartyppl_caseworker, 
                               col_allowdelete) 
                  VALUES      ( v_case_id, 
								v_name,
                               v_partytype_id, 
                               v_participant_id, 
                               rec.caseworkerid, 
                               1 ); 

                  :affectedRows := :affectedRows + 1; 
              END LOOP; 
            END IF; 

            IF( v_participant_code = 'EXTERNAL' ) THEN 
              FOR rec IN (SELECT column_value AS ExternalPartyId 
                          FROM   TABLE(Asf_splitclob(v_externalparty_ids, '|||'))) 
              LOOP 
                  INSERT INTO tbl_caseparty 
                              (col_casepartycase, 
							  col_name, 
                               col_casepartydict_partytype, 
                               col_casepartyparticipant, 
                               col_casepartyexternalparty, 
                               col_allowdelete) 
                  VALUES      ( v_case_id, 
							   v_name,
                               v_partytype_id, 
                               v_participant_id, 
                               rec.externalpartyid, 
                               1 ); 

                  :affectedRows := :affectedRows + 1; 
              END LOOP; 
            END IF; 
        EXCEPTION 
            WHEN no_data_found THEN 
              :affectedRows := 0; 
            WHEN dup_val_on_index THEN 
              :affectedRows := 0; 
            WHEN OTHERS THEN 
              v_errorcode := 100; 
              v_errormessage := Substr(SQLERRM, 1, 200); 
        END; 

        <<cleanup>> 
        :ErrorMessage := v_errormessage; 

        :ErrorCode := v_errorcode; 
    END; 
END; 