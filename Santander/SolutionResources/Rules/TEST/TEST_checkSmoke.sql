DECLARE 
    v_errorcode       NUMBER; 
    v_errormessage    NCLOB; 
    v_successresponse NCLOB; 
    v_finalreport     NCLOB; 
    v_count           NUMBER; 
    v_res             NUMBER; 
BEGIN 
    v_errorcode := 0; 
    v_errormessage := ''; 
    v_successresponse := '';
    v_finalreport := ''; 
    :ErrorCode := v_errorcode; 
    :ErrorMessage := v_errormessage; 
    :SuccessResponse := v_successresponse; 
    v_successresponse := 'Smoke check passed!'; 
    v_res := F_test_checkcasestateconfig(errorcode => v_errorcode, errormessage => v_errormessage); 

	IF v_errorcode <> 0 THEN 
      v_successresponse := ''; 
      v_finalreport := '<br><b>Milestone diagrams (case and task state machine):</b>' ||v_errormessage; 
    END IF; 

    v_res := F_test_checkcaseworkers(errorcode => v_errorcode, errormessage => v_errormessage ); 

    IF v_errorcode <> 0 THEN  
      v_successresponse := ''; 

      v_finalreport := v_finalreport ||'<br><b>Case workers:</b>' ||v_errormessage; 
    END IF; 

    v_res := F_test_checkexternalparties(errorcode => v_errorcode, errormessage => v_errormessage); 

	IF v_errorcode <> 0 THEN 
      v_successresponse := ''; 

      v_finalreport := v_finalreport ||'<br><b>External parties:</b>' ||v_errormessage; 
    END IF; 
	v_res := F_test_checkTeams(errorcode => v_errorcode, errormessage => v_errormessage); 

	IF v_errorcode <> 0 THEN 
      v_successresponse := ''; 

      v_finalreport := v_finalreport ||'<br><b>Teams:</b>' ||v_errormessage; 
    END IF; 
	v_res := F_test_checkSkills(errorcode => v_errorcode, errormessage => v_errormessage); 

	IF v_errorcode <> 0 THEN 
      v_successresponse := ''; 

      v_finalreport := v_finalreport ||'<br><b>Skills:</b>' ||v_errormessage; 
    END IF; 
	v_res := F_test_checkBRoles(errorcode => v_errorcode, errormessage => v_errormessage); 

	IF v_errorcode <> 0 THEN 
      v_successresponse := ''; 

      v_finalreport := v_finalreport ||'<br><b>Business Roles:</b>' ||v_errormessage; 
    END IF; 
    v_res := F_test_checkassocpages(errorcode => v_errorcode, errormessage => v_errormessage); 
    
    IF v_errorcode <> 0 THEN  
      v_successresponse := ''; 

      v_finalreport := v_finalreport ||'<br><b>Pages and forms:</b>' ||v_errormessage; 
    END IF; 
 	v_res := F_test_checkproccodes(errorcode => v_errorcode, errormessage => v_errormessage); 

    IF v_errorcode <> 0 THEN 
      v_successresponse := ''; 

      v_finalreport := v_finalreport ||'<br><b>Rules and functions:</b>' ||v_errormessage; 
    END IF; 
    v_res := F_test_checkperformance(errorcode => v_errorcode, errormessage => v_errormessage); 

    IF v_errorcode <> 0 THEN 
      v_successresponse := ''; 
      v_finalreport := v_finalreport|| '<br><b>Performance:</b>'||v_errormessage;  
    END IF; 
     v_res := F_test_checkdicts(errorcode => v_errorcode, errormessage => v_errormessage); 
 
    IF v_errorcode <> 0 THEN 
      v_successresponse := ''; 
      v_finalreport := v_finalreport|| '<br><b>Dictionaries:</b>'||v_errormessage; 
    END IF; 
    v_res := F_TEST_checkUnusedItems(errorcode => v_errorcode, errormessage => v_errormessage); 
 
    IF v_errorcode <> 0 THEN 
      v_successresponse := ''; 
      v_finalreport := v_finalreport|| '<br><b>Unused Items:</b>'||v_errormessage; 
    END IF; 

    <<cleanup>>  
    :ErrorMessage := ''; 
	:Report := NVL(v_finalreport, 'No problems found'); 
    :SuccessResponse := v_successresponse; 
    --dbms_output.Put_line (v_errormessage); 
END; 