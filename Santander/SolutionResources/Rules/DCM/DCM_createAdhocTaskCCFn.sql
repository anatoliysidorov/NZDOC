DECLARE
    /*--INPUT*/
    v_caseid INTEGER;
    v_name NVARCHAR2(255) ;
    v_description NCLOB;
    v_sourceid INTEGER;
    v_position NVARCHAR2(255) ;
    v_input NCLOB;
    v_casepartyid   INTEGER;
    v_workbasketid  INTEGER;
    v_tasksystypeid INTEGER;
    v_tasksystypecode NVARCHAR2(255) ;

    /*--SYSTEM*/
    v_msg NCLOB;
    v_result      INTEGER;
    v_errorcode   INTEGER;
    v_temperrcode INTEGER;
    v_temperrmsg NCLOB;
    v_tempsucces NCLOB;
    v_temptitle NVARCHAR2(255) ;
    v_action NVARCHAR2(20) ;

    /*--CALCULATED*/
    v_taskid   INTEGER;
    v_parentid INTEGER;
    v_ttcode NVARCHAR2(255) ;
    v_ttname NVARCHAR2(255) ;
    v_ttexectype    INTEGER ;
    v_ttstateconfig INTEGER;
    v_ttcustomdataproc NVARCHAR2(255) ;
    v_depth     INTEGER;
    v_taskorder INTEGER;
    v_tokendomain NVARCHAR2(255) ;
    v_workflow NVARCHAR2(255) ;
    v_activitycode NVARCHAR2(255) ;
    
    v_errormessage CLOB;
    v_validationresult NUMBER;
    v_historymsg       NCLOB;
    v_Attributes       NVARCHAR2(4000);
    v_outData CLOB;
    
    
BEGIN
    BEGIN
        /*--INPUT*/
        v_caseid := :CASEID;
        v_sourceid := :SOURCEID;
        v_name := :NAME;
        v_description := :DESCRIPTION;
        v_workbasketid := :WORKBASKETID;
        v_position := :POSITION;
        v_input := NVL(Trim(:INPUT),'<CustomData><Attributes></Attributes></CustomData>') ;
        v_tasksystypeid := :TASKSYSTYPEID;
        v_tasksystypecode := :TASKSYSTYPECODE;
        v_casepartyid := :CASEPARTYID;
        
        --get ActivityCode from custom data //DCMS-327
        v_activitycode :=F_form_getparambyname(v_input, 'ActivityCode');         

        /*--SYSTEM*/
        v_msg := '';
        v_validationresult := NULL;
        v_historymsg       := NULL;
        v_outData      := NULL;

        /*-- BASIC ERROR CHECKS*/
        IF NVL(v_caseid,0) = 0 AND NVL(v_sourceid,0) = 0 THEN
            v_errorcode := 102;
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'ERROR: both Source ID or Case ID are empty') ;
            GOTO cleanup;
        END IF;

        /*--GET BASIC TASK TYPE INFO*/
        v_tasksystypeid := NVL(v_tasksystypeid,0) ;
        v_tasksystypecode := Trim(v_tasksystypecode) ;
        IF v_tasksystypeid = 0 THEN
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'INFO: Using Task Type Code ' || NVL(v_tasksystypecode,'==missing==') || ' to find Task Type ID') ;
            v_tasksystypeid := F_util_getidbycode(tablename => 'tbl_dict_tasksystype',
                                                  code => v_tasksystypecode) ;
        END IF;
        BEGIN
            SELECT col_name,
                   col_code,
                   col_stateconfigtasksystype,
                   col_customdataprocessor,
                   COL_TASKSYSTYPEEXECMETHOD
            INTO   v_ttname,
                   v_ttcode,
                   v_ttstateconfig,
                   v_ttcustomdataproc,
                   v_ttexectype
            FROM   tbl_dict_tasksystype
            WHERE  col_id = v_tasksystypeid ;
            
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'INFO: Found Task Type with ID ' || TO_CHAR(v_tasksystypeid)) ;
        EXCEPTION
        WHEN no_data_found THEN
            v_errorcode := 101;
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'ERROR: Task Type with ID ' || NVL(TO_CHAR(v_tasksystypeid),'==missing==') || ' is missing') ;
            GOTO cleanup;
        END;
        /*--GET BASIC SOURCE TASK INFO*/
        IF NVL(v_sourceid,0) = 0 AND v_caseid > 0 THEN
            v_sourceid := NVL(F_dcm_getcaseccrootfn(v_caseid),0) ;
            IF NVL(v_sourceid,0) = 0 THEN
                v_errorcode := 104;
                v_msg := F_util_addtomessage(originalmsg => v_msg,
                                             newmsg => 'ERROR: Case did not return a root Task to insert the new task into') ;
                GOTO cleanup;
            ELSE
                /*--default to append*/
                v_position := 'append';
            END IF;
        END IF;
        v_msg := F_util_addtomessage(originalmsg => v_msg,
                                     newmsg => 'INFO: Attempting to work with Source Task with ID ' || NVL(TO_CHAR(v_sourceid),'==missing==')) ;

        /*--GET CASE INFO*/
        IF NVL(v_caseid,0) = 0 AND v_sourceid > 0 THEN
            v_caseid := F_dcm_getcaseidbytaskid(v_sourceid) ;
        END IF;
        
    /*--COPY RECORDS FROM DESIGNTIME BO INTO RUNTIME BO*/
    v_result := F_dcm_copycommonevents(caseid      => v_caseid,
                                       casetypeid  => NULL,
                                       code        => NULL,
                                       procedureid => NULL,
                                       tasktypeid  => v_tasksystypeid,
                                       taskid      => NULL);



  v_Attributes := '<SourceTaskId>' || TO_CHAR(v_sourceid) || '</SourceTaskId>' || 
                  '<Position>' || TO_CHAR(v_position) || '</Position>' ||                   
                  '<TasksystypeId>' || TO_CHAR(v_tasksystypeid) || '</TasksystypeId>';


  /*--
     CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_TASK- 
     AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_validationresult := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,  
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'CREATE_ADHOC_TASK',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'VALIDATION',
                                       historymessage   => v_historymsg,
                                       procedureid      => NULL,
                                       taskid           => NULL,
                                       tasktypeid       => v_tasksystypeid,
                                       validationresult => v_validationresult);

  IF NVL(v_validationresult, 0) <> 1 THEN
    v_ErrorCode    := 199;
    v_ErrorMessage := 'Validation failed. Error: ' || v_ErrorMessage;
    v_msg := F_util_addtomessage(originalmsg => v_msg, newmsg => v_ErrorMessage) ;
    /*--UPDATE RECORDS INSIDE RUNTIME BO (link to created task)*/
    UPDATE tbl_commonevent
       SET col_commoneventtask = 0
     WHERE col_commoneventcase = v_caseid
       AND col_commoneventtasktype = v_tasksystypeid
       AND col_commoneventtask IS NULL;
    GOTO cleanup;
  END IF;

  /*--
     CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_TASK- 
     AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_validationresult := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => NULL,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'CREATE_ADHOC_TASK',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => NULL,
                                       taskid           => NULL,
                                       tasktypeid       => v_tasksystypeid,
                                       validationresult => v_validationresult);        
        

        /*--GET PROPER INFORMATION ABOUT THE PARENT and SET ORDER*/
        v_position := Lower(NVL(Trim(v_position),'append')) ;
        v_msg := F_util_addtomessage(originalmsg => v_msg,
                                     newmsg => 'INFO: Attempting action - ' || v_position) ;
        IF v_position = 'append' THEN
            v_parentid := v_sourceid;
            SELECT MAX(col_taskorder) +1
            INTO   v_taskorder
            FROM   tbl_taskcc
            WHERE  col_parentidcc = v_sourceid
                   AND
                   col_casecctaskcc = v_caseid ;
            
            IF NVL(v_taskorder,0) = 0 THEN
                v_taskorder := 1;
            END IF;
            SELECT NVL(col_depth,0) +1
            INTO   v_depth
            FROM   tbl_taskcc
            WHERE  col_id = v_sourceid ;
        
        ELSIF v_position = 'insert_before' THEN
            SELECT col_parentidcc,
                   col_taskorder,
                   col_depth
            INTO   v_parentid,
                   v_taskorder,
                   v_depth
            FROM   tbl_taskcc
            WHERE  col_id = v_sourceid
                   AND
                   col_casecctaskcc = v_caseid ;
            
            UPDATE tbl_taskcc
            SET    col_taskorder = col_taskorder+1
            WHERE  col_parentidcc =(
                   SELECT col_parentidcc
                   FROM   tbl_taskcc
                   WHERE  col_id = v_sourceid
                   )
                   AND
                   col_taskorder >= v_taskorder ;
        
        ELSIF v_position = 'insert_after' THEN
            SELECT col_parentidcc,
                   col_taskorder+1,
                   col_depth
            INTO   v_parentid,
                   v_taskorder,
                   v_depth
            FROM   tbl_taskcc
            WHERE  col_id = v_sourceid
                   AND
                   col_casecctaskcc = v_caseid ;
            
            UPDATE tbl_taskcc
            SET    col_taskorder = col_taskorder+1
            WHERE  col_parentidcc =(
                   SELECT col_parentidcc
                   FROM   tbl_taskcc
                   WHERE  col_id = v_sourceid
                   )
                   AND
                   col_taskorder >= v_taskorder ;
        
        ELSE
            v_errorcode := 103;
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'ERROR: The position can not be ' || TO_CHAR(v_position)) ;
            GOTO cleanup;
        END IF;

        v_name :=NVL(v_name, v_ttname);
        /*--CREATE NEW TASK*/
        v_msg := F_util_addtomessage(originalmsg => v_msg,
                                     newmsg => 'INFO: Inserting task with depth ' || TO_CHAR(v_depth) || ' and order ' || TO_CHAR(v_taskorder)) ;
        INSERT INTO tbl_taskcc
                  (col_parentidcc,
                            col_description,
                            col_name,
                            col_depth,
                            col_leaf,
                            col_taskorder,
                            col_casecctaskcc,
                            col_enabled,
                            col_taskccdict_tasksystype,
                            col_taskccdict_executionmtd,
                            col_customdata,
							col_isadhoc
                  )
                  VALUES
                  (v_parentid,
                            v_description,
                            v_name,
                            v_depth,
                            1,
                            v_taskorder,
                            v_caseid,
                            1,
                            v_tasksystypeid,
                            v_ttexectype,
                            Xmltype(v_input),
							1
                  )
        RETURNING col_id
        INTO      v_taskid ;
        
      /*--UPDATE RECORDS INSIDE RUNTIME BO (link to created task)*/
      UPDATE tbl_commonevent
         SET col_commoneventtask = v_taskid
       WHERE col_commoneventcase = v_caseid
         AND col_commoneventtasktype = v_tasksystypeid
         AND col_commoneventtask IS NULL;        
        
        
        INSERT INTO tbl_taskextcc
               (col_taskextcctaskcc
               )
               VALUES
               (v_taskid
               ) ;
        
        v_msg := F_util_addtomessage(originalmsg => v_msg,
                                     newmsg => 'INFO: created new Task with ID ' || TO_CHAR(v_taskid)) ;

        /*--SET ADDITIONAL TASK INFORMATION*/
        v_result := F_dcm_generatetaskccid(errorcode => v_temperrcode,
                                           errormessage => v_temperrmsg,
                                           taskid => v_taskid,
                                           tasktitle => v_temptitle) ;
        UPDATE tbl_taskcc
        SET    col_id2 = v_taskid
        WHERE  col_id = v_taskid ;

        /*--CREATE WORKITEM FOR TASK*/
        IF(v_workbasketid IS NOT NULL) THEN
            v_activitycode := F_dcm_gettaskassignedstate2(v_ttstateconfig) ;
        ELSE
            --v_activitycode := F_dcm_gettaskstartedstate2(v_ttstateconfig) ;//DCMS-324
            IF v_activitycode IS NULL THEN
              v_activitycode := f_DCM_getTaskNewState2(v_ttstateconfig);
            END IF;
        END IF;
        
        v_tokendomain := f_UTIL_getDomainFn();
        v_workflow := f_DCM_getTaskWorkflowCodeFn() ;

        v_result := F_tskw_createworkitem2cc(activitycode => v_activitycode,
                                             errorcode => v_temperrcode,
                                             errormessage => v_temperrmsg,
                                             taskid => v_taskid,
                                             workflowcode => v_tokendomain || '_' || v_workflow) ;

/*--ADD EVENTS AND DO FINAL STEPS*/
        v_result := F_dcm_addtaskdateeventcclist(taskid => v_taskid,state => v_activitycode) ;
        v_result := F_dcm_copytaskstateinittaskcc(owner => NULL,taskid => v_taskid) ;
        v_result := F_dcm_copytaskeventadhoctskcc(taskid => v_taskid) ;
        v_result := F_dcm_copyruleparametertaskcc(taskid => v_taskid) ;
		v_Result := f_DCM_createTaskDateEventCC(Name => 'DATE_TASK_CREATED',TaskId => v_TaskId) ;
		v_Result := f_DCM_createTaskDateEventCC(Name => 'DATE_TASK_MODIFIED',TaskId => v_TaskId) ;

/*--SET CUSTOM DATA OR EXECUTE PROCESSOR*/
        IF Trim(v_ttcustomdataproc) IS NOT NULL THEN
            v_result := F_dcm_invokecustomdataproc(
                                                  input => v_input,
                                                   processorname => v_ttcustomdataproc,
                                                   taskid => v_taskid) ;
        END IF;

/*--SET HISTORY THAT TASK WAS INJECTED*/
        v_result := F_hist_createhistoryfn(additionalinfo => v_msg,
                                           issystem => 0,
                                           MESSAGE => NULL,
                                           messagecode => 'TaskInjected',
                                           targetid => v_taskid,
                                           targettype => 'TASK') ;

/*--ASSIGN TASK IF NEEDED*/
        v_workbasketid := NVL(v_workbasketid,0) ;
        v_casepartyid := NVL(v_casepartyid,0) ;
        IF v_workbasketid > 0 THEN
            v_action := 'ASSIGN';
        ELSIF v_casepartyid > 0 THEN
            v_action := 'ASSIGN_TO_PARTY';
        END IF;
        IF v_workbasketid > 0 OR v_casepartyid > 0 THEN
            v_result := F_dcm_assigntaskfn(action => v_action,
                                           caseparty_id => v_casepartyid,
                                           note => NULL,
                                           task_id => v_taskid,
                                           workbasket_id => v_workbasketid,
                                           errorcode => v_temperrcode,
                                           errormessage => v_temperrmsg,
                                           successresponse => v_tempsucces) ;
        END IF;

  /*--
     CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_TASK- 
     AND EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_validationresult := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => NULL,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'CREATE_ADHOC_TASK',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'AFTER',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => NULL,
                                       taskid           => v_taskid,
                                       tasktypeid       => v_tasksystypeid,
                                       validationresult => v_validationresult);
        
        
        
/*--RETURN TASK ID*/
        RETURN v_taskid;

        /*--ERROR BLOCK*/
        <<cleanup>> v_result := F_hist_createhistoryfn(additionalinfo => v_msg,
                                                       issystem => 0,
                                                       MESSAGE => 'ERROR BLOCK',
                                                       messagecode => NULL,
                                                       targetid => v_caseid,
                                                       targettype => 'CASE') ;
        RETURN 0;
    END;
END;