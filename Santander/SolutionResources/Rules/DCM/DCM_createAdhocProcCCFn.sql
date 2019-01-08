DECLARE
    /*--INPUT*/
    v_caseid INTEGER;
    v_name NVARCHAR2(255) ;
    v_description NCLOB;
    v_sourceid INTEGER;
    v_position NVARCHAR2(255) ;
    v_input NCLOB;
    v_input2 NCLOB;
    v_casepartyid  INTEGER;
    v_workbasketid INTEGER;
    v_procedureid  INTEGER;
    v_procedurecode NVARCHAR2(255) ;

    /*--SYSTEM*/
    v_msg NCLOB;
    v_result    INTEGER;
    v_errorcode INTEGER;
    v_temperrcd INTEGER;
    v_temperrmsg NCLOB;
    v_tempsucces NCLOB;
    v_temptitle NVARCHAR2(255) ;
    v_action NVARCHAR2(20) ;

    /*--CALCULATED*/
    v_taskid            INTEGER;
    v_injectNewParentId INTEGER;
    v_prcode NVARCHAR2(255) ;
    v_prname NVARCHAR2(255) ;
    v_prexectype    INTEGER ;
    v_prstateconfig INTEGER;
    v_prcustomdataproc NVARCHAR2(255) ;
    v_tokendomain NVARCHAR2(255) ;
    v_workflow NVARCHAR2(255) ;
    v_activitycode NVARCHAR2(255) ;
    
    v_isdebug       INTEGER;
    v_parentdepth   INTEGER;
    v_transactionId INTEGER;
    v_tempTaskIdTitle NVARCHAR2(255) ;
    v_tempParentID INTEGER;
    
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
        v_procedureid := :PROCEDUREID;
        v_procedurecode := :PROCEDURECODE;
        v_casepartyid := :CASEPARTYID;

        /*--SYSTEM*/
        v_msg := '==DCM_createAdhocProcCCFn==';
        v_validationresult := NULL;
        v_historymsg       := NULL;
        v_outData      := NULL;
        

        /*--GET BASIC PROCEDURE INFO*/
        v_procedureid := NVL(v_procedureid,0) ;
        v_procedurecode := Trim(v_procedurecode) ;
        IF v_procedureid = 0 THEN
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'INFO: Using Procedure Code ' || NVL(v_procedurecode,'==missing==') || ' to find Procedure ID') ;
            v_procedureid := F_util_getidbycode(tablename => 'tbl_procedure',
                                                code => v_procedurecode) ;
        END IF;
        
        BEGIN
            SELECT col_name,
                   col_code,
                   COL_DEBUGMODE
            INTO   v_prname,
                   v_prcode,
                   v_isdebug
            FROM   tbl_procedure
            WHERE  col_id = v_procedureid ;
            
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'INFO: Found Procedure with ID ' || TO_CHAR(v_procedureid)) ;
        EXCEPTION
        WHEN no_data_found THEN
            v_errorcode := 101;
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'ERROR: Task Type with ID ' || NVL(TO_CHAR(v_procedureid),'==missing==') || ' is missing') ;
            /*--GOTO cleanup;*/
        END;

/*GET INFO ABOUT TASK WORKFLOW*/
        v_tokendomain := f_UTIL_getDomainFn();
        v_workflow := f_DCM_getTaskWorkflowCodeFn();

    /*--COPY RECORDS FROM DESIGNTIME BO INTO RUNTIME BO*/
    v_result := F_dcm_copycommonevents(caseid      => NULL,
                                       casetypeid  => NULL,
                                       code        => NULL,
                                       procedureid => v_procedureid,
                                       tasktypeid  => NULL,
                                       taskid      => NULL);



  v_Attributes := '<SourceTaskId>' || TO_CHAR(v_sourceid) || '</SourceTaskId>' || 
                  '<Position>' || TO_CHAR(v_position) || '</Position>' ||                   
                  '<ProcedureId>' || TO_CHAR(v_procedureid) || '</ProcedureId>' ||
                  '<ProcedureCode>' || TO_CHAR(v_procedurecode) || '</ProcedureCode>';


  /*--
     CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_PROC- 
     AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_validationresult := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,  
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => NULL,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'CREATE_ADHOC_PROC',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'VALIDATION',
                                       historymessage   => v_historymsg,
                                       procedureid      => v_procedureid,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);

  IF NVL(v_validationresult, 0) <> 1 THEN
    v_ErrorCode    := 199;
    v_ErrorMessage := 'Validation failed. Error: ' || v_ErrorMessage;
    v_msg := F_util_addtomessage(originalmsg => v_msg, newmsg => v_ErrorMessage) ;
    GOTO cleanup;
  END IF;

  /*--
     CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_PROC- 
     AND EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_validationresult := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => NULL,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'CREATE_ADHOC_PROC',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'BEFORE',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => v_procedureid,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);
        
        
        

/*CREATE A PARENT TASK FOR THE INJECTED PROCEDURE*/

        --DCMS-327
        v_activitycode := f_DCM_getTaskInProcessState();
        IF v_activitycode IS NOT NULL THEN
          v_input2 := f_FORM_appendProperty2(Input => v_input, 
                                             ParamName => 'ActivityCode', 
                                             ParamValue => v_activitycode);
        ELSE 
          v_input2 := v_input;
        END IF;        

        v_name := NVL(TRIM(v_name),v_prname) ;
        v_injectNewParentId := F_dcm_createadhoctaskccfn(sourceid => v_sourceid,
                                                         position => v_position,
                                                         tasksystypecode => 'adhoc',
                                                         name => v_name,
                                                         description => v_description,
                                                         casepartyid => v_casepartyid,
                                                         tasksystypeid => NULL,
                                                         caseid => NULL,
                                                         input => v_input2,
                                                         workbasketid => NULL,
                                                         errorcode => v_temperrcd,
                                                         errormessage => v_temperrmsg) ;
        
        v_activitycode :=NULL;
        
        IF v_temperrcd > 0 OR NVL(v_injectNewParentId,0) = 0 THEN
            v_errorcode := v_temperrcd;
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'ERROR: there was an error creating the root ad-hoc task') ;
            GOTO cleanup;
        END IF;
        
        SELECT NVL(col_depth,0) + 1,
               COL_CASECCTASKCC
        INTO   v_parentdepth,
               v_caseid
        FROM   tbl_taskcc
        WHERE  col_id = v_injectNewParentId ;
        
        UPDATE tbl_taskcc
        SET    col_systemtype = 'adhoc',
               COL_TASKCCPROCEDURE = v_procedureid
        WHERE  col_id = v_injectNewParentId ;


/*--CREATE TASKS FROM PROCEDURE--*/
        v_transactionId := v_injectNewParentId;
        FOR procRec IN(
        SELECT    tt.col_id AS ID,
                  tt.col_parentttid AS PARENTID,
                  tt.col_description AS DESCRIPTION,
                  tt.col_name AS NAME,
                  tt.col_depth AS DEPTH,
                  tt.col_leaf AS LEAF,
                  tt.col_icon AS ICON,
                  tt.col_taskorder AS TASKORDER,
                  tt.col_tasktmpldict_tasksystype AS TASKSYSTYPE,
                  tt.col_execmethodtasktemplate AS EXECMETHOD,
                  tt.col_processorcode AS PROCESSORCODE,
                  ttype.COL_STATECONFIGTASKSYSTYPE AS TTYPE_STATECONFIG,
                  SYS_CONNECT_BY_PATH(tt.col_name || ' (' || TO_CHAR(tt.col_id) || ')',' &#x203A; ') AS PRINTPATH,
                  LEVEL AS lvl,
                  tt.COL_ISHIDDEN AS ISHIDDENTASK
        FROM      tbl_tasktemplate tt
        LEFT JOIN tbl_dict_TaskSysType ttype ON tt.COL_TASKTMPLDICT_TASKSYSTYPE = ttype.col_id
        WHERE     COL_PARENTTTID > 0
                  CONNECT BY PRIOR tt.col_id = tt.COL_PARENTTTID
                  START WITH COL_PARENTTTID = 0
                  AND
                  COL_PROCEDURETASKTEMPLATE = v_procedureid
        ORDER BY  LEVEL ASC
        )
        
        LOOP
            /*--create task*/
            INSERT INTO tbl_taskcc
                      (col_description,
                        col_name,
                        col_depth,
                        col_leaf,
                        col_taskorder,
                        col_casecctaskcc,
                        col_enabled,
                        col_taskccdict_tasksystype,
                        col_taskccdict_executionmtd,
                        COL_PROCESSORNAME,
                        col_taskccprocedure,
                        /*--temp info*/
                        col_id2,
                        col_parentid2,
                        COL_TRANSACTIONID,
                        col_isadhoc,
                        COL_ISHIDDEN
                      )
                      VALUES
                      (procRec.DESCRIPTION,
                        procRec.NAME,
                        v_parentdepth + procRec.lvl - 1,
                        procRec.LEAF,
                        procRec.TASKORDER,
                        v_caseid,1,
                        procRec.TASKSYSTYPE,
                        procRec.EXECMETHOD,
                        procRec.PROCESSORCODE,
                        v_procedureid,
                        /*--temp info*/
                        procRec.ID,
                        procRec.PARENTID,
                        v_transactionId,
                        1,
                        procRec.ISHIDDENTASK
                      )
            RETURNING col_id
            INTO      v_taskid ;
            
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => '--' || procRec.PRINTPATH || '--') ;

            /*--set task title (col_TaskId) and update parent*/
            v_result := F_dcm_generatetaskccid(errorcode => v_temperrcd,
                                               errormessage => v_temperrmsg,
                                               taskid => v_taskid,
                                               tasktitle => v_tempTaskIdTitle) ;
            
            IF procRec.lvl = 2 THEN
                /*--these are the first level tasks right after the original root*/
                v_tempParentID := v_injectNewParentId;
            ELSE
                SELECT col_id
                INTO   v_tempParentID
                FROM   tbl_taskcc
                WHERE  col_id2 = procRec.parentid ;
            
            END IF;
            
            UPDATE tbl_taskcc
            SET    col_taskid = v_tempTaskIdTitle,
                   COL_PARENTIDCC = v_tempParentID
            WHERE  col_id = v_taskid ;


            /*--create state inits for task*/
            v_result := F_dcm_copytaskccstateinittmpl(owner => NULL,
                                                      taskid => v_taskid) ;
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'INFO: ' || 'created task inits') ;

            /*--create workitem for task*/
            v_activitycode := F_dcm_gettaskstartedstate2(procRec.TTYPE_STATECONFIG) ;
            
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'INFO: ' || 'set to activity code ' || v_activitycode) ;
            v_result := F_tskw_createworkitem2cc(
                                                 activitycode => v_activitycode,
                                                 errorcode => v_temperrcd,
                                                 errormessage => v_temperrmsg,
                                                 
                                                 taskid => v_taskid,
                                                 
                                                 workflowcode => v_tokendomain || '_' || v_workflow) ;
            v_msg := F_util_addtomessage(originalmsg => v_msg,
                                         newmsg => 'INFO: ' || 'created work item') ;
            
            /*--create data events*/
            v_Result := f_DCM_createTaskDateEventCC(Name => 'DATE_TASK_CREATED',
                                                    TaskId => v_TaskId) ;
            v_Result := f_DCM_createTaskDateEventCC(Name => 'DATE_TASK_MODIFIED',
                                                    TaskId => v_TaskId) ;
            v_result := F_dcm_addtaskdateeventcclist(taskid => v_taskid,
                                                     state => v_activitycode) ;


            /*--create task extension procRecord*/
            INSERT INTO tbl_taskextcc
                   (col_taskextcctaskcc
                   )
                   VALUES
                   (v_taskid
                   ) ;
        
        END LOOP;
        v_msg := F_util_addtomessage(originalmsg => v_msg,
                                     newmsg => '----------------------') ;

        /*--COPY ADDITIONAL INFORMATION FOR THE NEWLY CREATED TASKS*/
        v_result := F_dcm_copyslaeventccadhocproc(transactionid => v_transactionid) ;
        v_msg := F_util_addtomessage(originalmsg => v_msg,
                                     newmsg => 'INFO: ' || 'copied SLA') ;
        v_result := F_dcm_copytaskdepccadhocproc(transactionid => v_transactionid) ;
        v_msg := F_util_addtomessage(originalmsg => v_msg,
                                     newmsg => 'INFO: ' || 'copied dependencies') ;
        v_result := F_dcm_copytaskeventccadhocprc(transactionid => v_transactionid) ;
        v_msg := F_util_addtomessage(originalmsg => v_msg,
                                     newmsg => 'INFO: ' || 'copied task events') ;
        v_result := F_dcm_copyruleparamccadhocprc(transactionid => v_transactionid) ;
        v_msg := F_util_addtomessage(originalmsg => v_msg,
                                     newmsg => 'INFO: ' || 'copied rule params') ;


/*--SET HISTORY THAT PROCEDURE WAS INJECTED*/
        v_result := F_hist_createhistoryfn(additionalinfo => v_msg,
                                           issystem => 0,
                                           MESSAGE => NULL,
                                           messagecode => 'ProcedureInjected',
                                           targetid => v_injectNewParentId,
                                           targettype => 'TASK') ;


  /*--
     CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -CREATE_ADHOC_PROC- 
     AND EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM
  --*/
  v_validationresult := 1;

  v_result := f_DCM_processCommonEvent(InData           => NULL,
                                       OutData          => v_outData,
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => NULL,
                                       casetypeid       => NULL,
                                       commoneventtype  => 'CREATE_ADHOC_PROC',
                                       errorcode        => v_errorcode,
                                       errormessage     => v_errormessage,
                                       eventmoment      => 'AFTER',
                                       eventtype        => 'ACTION',
                                       historymessage   => v_historymsg,
                                       procedureid      => v_procedureid,
                                       taskid           => NULL,
                                       tasktypeid       => NULL,
                                       validationresult => v_validationresult);                                           
                                           
                                           
/*--RETURN TASK ID*/
        RETURN v_taskid;

        /*--ERROR BLOCK*/
        <<cleanup>> 
		v_result := F_hist_createhistoryfn(additionalinfo => v_msg,
                                                       issystem => 0,
                                                       MESSAGE => 'ERROR BLOCK',
                                                       messagecode => NULL,
                                                       targetid => v_caseid,
                                                       targettype => 'CASE') ;
        RETURN 0;
    END;
END;