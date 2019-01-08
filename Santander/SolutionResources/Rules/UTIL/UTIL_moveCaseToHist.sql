DECLARE 
v_schema_name   VARCHAR2(255);
v_col_id        VARCHAR2(12);
v_temp_xml      XMLTYPE;  
BEGIN

v_schema_name := :SchemaName;

IF v_schema_name IS NULL THEN
    SELECT USER
    INTO
    v_schema_name
    FROM dual;
END IF;

v_col_id:= :CaseId;




FOR action IN (SELECT col_id FROM TBL_ACTION WHERE COL_ACTIONCASE = v_col_id) LOOP 
  
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_ACTION', (SELECT DBURIType('/'||v_schema_name||'/TBL_ACTION/ROW[COL_ID='||action.col_id||']').getXML() FROM dual), v_col_id);

        DELETE FROM TBL_ACTION
        WHERE col_id = action.col_id;

END LOOP; --action


FOR MAPCaStatInit IN (SELECT col_id FROM tbl_MAP_CaseStateInitiation WHERE 	col_map_casestateinitcase = v_col_id ) LOOP
    
      FOR CaseDep IN (SELECT col_id, col_casedependencyglobalevent FROM tbl_casedependency WHERE col_casedpndchldcasestateinit = MAPCaStatInit.col_id) LOOP
        
        FOR ARParam IN (SELECT col_id FROM  tbl_autoruleparameter WHERE col_autoruleparamcasedep = CaseDep.col_id) LOOP
          
              INSERT INTO TBL_HISTORY_CASE
              (col_origin_table_name, col_xml_data, col_case_id  )
              VALUES
              ('TBL_AUTORULEPARAMETER', (SELECT DBURIType('/'||v_schema_name||'/TBL_AUTORULEPARAMETER/ROW[COL_ID='||ARParam.col_id||']').getXML() FROM dual), v_col_id);

                  DELETE FROM TBL_AUTORULEPARAMETER
                  WHERE col_id = ARParam.col_id;          
        
        END LOOP; --ARParam 
        
        FOR CaseEvent IN (SELECT col_id FROM tbl_caseevent WHERE col_CaseEventCaseStateInit = CaseDep.col_id) LOOP
          
              INSERT INTO TBL_HISTORY_CASE
              (col_origin_table_name, col_xml_data, col_case_id  )
              VALUES
              ('TBL_CASEEVENTQUEUE', (SELECT DBURIType('/'||v_schema_name||'/TBL_CASEEVENTQUEUE/ROW[COL_CASEEVENTQUEUECASEEVENT='||CaseEvent.col_id||']').getXML() FROM dual), v_col_id);

                  DELETE FROM TBL_CASEEVENTQUEUE
                  WHERE 	col_CaseEventQueueCaseEvent = CaseEvent.col_id;  

              INSERT INTO TBL_HISTORY_CASE
              (col_origin_table_name, col_xml_data, col_case_id  )
              VALUES
              ('TBL_AUTORULEPARAMETER', (SELECT DBURIType('/'||v_schema_name||'/TBL_AUTORULEPARAMETER/ROW[COL_CASEEVENTAUTORULEPARAM='||CaseEvent.col_id||']').getXML() FROM dual), v_col_id);

                  DELETE FROM TBL_AUTORULEPARAMETER
                  WHERE 	COL_CASEEVENTAUTORULEPARAM = CaseEvent.col_id;                   
        
              INSERT INTO TBL_HISTORY_CASE
              (col_origin_table_name, col_xml_data, col_case_id  )
              VALUES
              ('TBL_CASEEVENT', (SELECT DBURIType('/'||v_schema_name||'/TBL_CASEEVENT/ROW[COL_ID='||CaseEvent.col_id||']').getXML() FROM dual), v_col_id);

                  DELETE FROM TBL_CASEEVENT
                  WHERE col_id = CaseEvent.col_id;         
        END LOOP; --CaseEvent
        

        
        INSERT INTO TBL_HISTORY_CASE
        (col_origin_table_name, col_xml_data, col_case_id  )
        VALUES
        ('TBL_GLOBALEVENT', (SELECT DBURIType('/'||v_schema_name||'/TBL_GLOBALEVENT/ROW[COL_ID='||CaseDep.col_casedependencyglobalevent||']').getXML() FROM dual), v_col_id);

            DELETE FROM TBL_GLOBALEVENT
            WHERE col_id = CaseDep.col_casedependencyglobalevent;         

        INSERT INTO TBL_HISTORY_CASE
        (col_origin_table_name, col_xml_data, col_case_id  )
        VALUES
        ('TBL_CASEDEPENDENCY', (SELECT DBURIType('/'||v_schema_name||'/TBL_CASEDEPENDENCY/ROW[COL_ID='||CaseDep.col_id||']').getXML() FROM dual), v_col_id);

            DELETE FROM TBL_CASEDEPENDENCY
            WHERE col_id = CaseDep.col_id;         
      
      END LOOP;  -- CaseDep
      
  
  
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_MAP_CASESTATEINITIATION', (SELECT DBURIType('/'||v_schema_name||'/TBL_MAP_CASESTATEINITIATION/ROW[COL_ID='||MAPCaStatInit.col_id||']').getXML() FROM dual), v_col_id);

        DELETE FROM TBL_MAP_CASESTATEINITIATION
        WHERE col_id = MAPCaStatInit.col_id;     

END LOOP; --MAPCaStatInit

SELECT DBURIType('/'||v_schema_name||'/TBL_CASEQUEUE/ROW[COL_CASECASEQUEUE='||v_col_id||']').getXML()
INTO v_temp_xml
FROM DUAL;

IF v_temp_xml IS NOT NULL THEN 
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_CASEQUEUE', v_temp_xml, v_col_id);

        DELETE FROM  TBL_CASEQUEUE
        WHERE COL_CASECASEQUEUE = v_col_id;

END IF;


SELECT DBURIType('/'||v_schema_name||'/TBL_CASEEVENTQUEUE/ROW[COL_CASEEVENTQUEUECASE='||v_col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL;

IF v_temp_xml IS NOT NULL THEN 
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_CASEEVENTQUEUE', v_temp_xml, v_col_id);

        DELETE FROM  TBL_CASEEVENTQUEUE
        WHERE COL_CASEEVENTQUEUECASE = v_col_id;
END IF;

/*
INSERT INTO TBL_HISTORY_CASE
(col_origin_table_name, col_xml_data, col_case_id  )
VALUES
('TBL_CASEEVENT', (SELECT DBURIType('/'||v_schema_name||'/TBL_CASEEVENT/ROW[COL_CASEEVENTQUEUECASE='||v_col_id||']').getXML() FROM DUAL), v_col_id);

    \*DELETE FROM  TBL_CASEEVENT
    WHERE COL_CASEEVENTQUEUECASE = v_col_id;*\   */

SELECT DBURIType('/'||v_schema_name||'/TBL_SMPL_BUSINESSLOAN/ROW[COL_BUSINESSLOANCASE='||v_col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL;

/*
IF v_temp_xml IS NOT NULL THEN 
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_SMPL_BUSINESSLOAN', v_temp_xml, v_col_id);

        DELETE FROM  TBL_SMPL_BUSINESSLOAN
        WHERE COL_BUSINESSLOANCASE = v_col_id;
END IF;
*/

FOR slaEvent IN (SELECT col_id FROM  TBL_SLAEVENT WHERE col_SLAEventCase = v_col_id) LOOP
  
    FOR SlaAction IN (SELECT col_id FROM tbl_slaaction WHERE col_SLAActionSLAEvent = slaEvent.col_id) LOOP
      
         FOR SLAActionQueue IN (SELECT col_id FROM tbl_SLAActionQueue WHERE col_SLAActionQueueSLAAction = SlaAction.col_id ) LOOP


         INSERT INTO TBL_HISTORY_CASE
            (col_origin_table_name, col_xml_data, col_case_id  )
            VALUES
            ('TBL_SLAACTIONQUEUE', (SELECT DBURIType('/'||v_schema_name||'/TBL_SLAACTIONQUEUE/ROW[COL_ID='||SLAActionQueue.col_id||']').getXML() FROM dual), v_col_id);

                DELETE FROM TBL_SLAACTIONQUEUE
                WHERE col_id = SLAActionQueue.col_id;            
         
         
         END LOOP; --SLAActionQueue
         
         INSERT INTO TBL_HISTORY_CASE
            (col_origin_table_name, col_xml_data, col_case_id  )
            VALUES
            ('TBL_SLAACTION', (SELECT DBURIType('/'||v_schema_name||'/TBL_SLAACTION/ROW[COL_ID='||SlaAction.col_id||']').getXML() FROM dual), v_col_id);

                DELETE FROM TBL_SLAACTION
                WHERE col_id = SlaAction.col_id;       
                
    END LOOP;  --SlaAction   
  
     INSERT INTO TBL_HISTORY_CASE
        (col_origin_table_name, col_xml_data, col_case_id  )
        VALUES
        ('TBL_SLAEVENT', (SELECT DBURIType('/'||v_schema_name||'/TBL_SLAEVENT/ROW[COL_ID='||slaEvent.col_id||']').getXML() FROM dual), v_col_id);

            DELETE FROM TBL_SLAEVENT
            WHERE col_id = slaEvent.col_id;   
         
END LOOP; --slaEvent

FOR dynamictask IN (SELECT col_id, col_dynamictasktw_workitem FROM  tbl_dynamictask WHERE col_CaseDynamicTask = v_col_id) LOOP 

   INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_SLAEVENT', (SELECT DBURIType('/'||v_schema_name||'/TBL_SLAEVENT/ROW[COL_SLAEVENTDYNAMICTASK='||dynamictask.col_id||']').getXML() FROM DUAL), v_col_id);

        DELETE FROM  TBL_SLAEVENT
        WHERE COL_SLAEVENTDYNAMICTASK = dynamictask.col_id;  

   INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_TW_WORKITEM', (SELECT DBURIType('/'||v_schema_name||'/TBL_TW_WORKITEM/ROW[COL_ID='||dynamictask.col_dynamictasktw_workitem||']').getXML() FROM DUAL), v_col_id);

        DELETE FROM  TBL_TW_WORKITEM
        WHERE COL_ID = dynamictask.col_dynamictasktw_workitem;  

 
   INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_DYNAMICTASK', (SELECT DBURIType('/'||v_schema_name||'/TBL_DYNAMICTASK/ROW[COL_ID='||dynamictask.col_id||']').getXML() FROM DUAL), v_col_id);

        DELETE FROM  TBL_DYNAMICTASK
        WHERE COL_ID = dynamictask.col_id;  

END LOOP;  --dynamictask

SELECT DBURIType('/'||v_schema_name||'/TBL_DCM_WORKACTIVITY/ROW[COL_WORKACTIVITYCASE='||v_col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL;

IF v_temp_xml IS NOT NULL THEN 
  
  INSERT INTO TBL_HISTORY_CASE
  (col_origin_table_name, col_xml_data, col_case_id  )
  VALUES
  ('TBL_DCM_WORKACTIVITY', v_temp_xml, v_col_id);

      DELETE FROM  TBL_DCM_WORKACTIVITY
      WHERE COL_WORKACTIVITYCASE = v_col_id;

END IF;




FOR THREAD IN (SELECT col_id FROM  TBL_THREAD WHERE COL_THREADCASE = v_col_id) LOOP
  
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_THREAD', (SELECT DBURIType('/'||v_schema_name||'/TBL_THREAD/ROW[COL_ID='||THREAD.col_id||']').getXML() FROM DUAL), v_col_id);

        DELETE FROM  TBL_THREAD
        WHERE COL_ID = THREAD.col_id;

END LOOP;  


FOR subscription IN (SELECT col_id FROM tbl_subscription WHERE 	col_SubscriptionCase = v_col_id) LOOP
  
      INSERT INTO TBL_HISTORY_CASE
      (col_origin_table_name, col_xml_data, col_case_id  )
      VALUES
      ('TBL_NOTIFICATION', (SELECT DBURIType('/'||v_schema_name||'/TBL_NOTIFICATION/ROW[COL_NOTIFICATIONSUBSCRIPTION='||subscription.col_id||']').getXML() FROM DUAL), v_col_id);

          DELETE FROM  TBL_NOTIFICATION
          WHERE col_NotificationSubscription = subscription.col_id;


      INSERT INTO TBL_HISTORY_CASE
      (col_origin_table_name, col_xml_data, col_case_id  )
      VALUES
      ('TBL_CASEWORKERSUBSCRIPTION', (SELECT DBURIType('/'||v_schema_name||'/TBL_CASEWORKERSUBSCRIPTION/ROW[COL_CWSUBSCRIPSUBSCRIPTION='||subscription.col_id||']').getXML() FROM DUAL), v_col_id);

          DELETE FROM  TBL_CASEWORKERSUBSCRIPTION
          WHERE COL_CWSUBSCRIPSUBSCRIPTION = subscription.col_id;
      
  
      INSERT INTO TBL_HISTORY_CASE
      (col_origin_table_name, col_xml_data, col_case_id  )
      VALUES
      ('TBL_SUBSCRIPTION', (SELECT DBURIType('/'||v_schema_name||'/TBL_SUBSCRIPTION/ROW[COL_ID='||subscription.col_id||']').getXML() FROM DUAL), v_col_id);

          DELETE FROM  TBL_SUBSCRIPTION
          WHERE COL_ID = subscription.col_id;

END LOOP;  

/*****************************************************************************************************************************/
SELECT DBURIType('/'||v_schema_name||'/TBL_SPGLEAKAGEEXT/ROW[COL_SPGLEAKAGEEXTCASE='||v_col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL ;

IF v_temp_xml IS NOT NULL THEN 
      INSERT INTO TBL_HISTORY_CASE
      (col_origin_table_name, col_xml_data, col_case_id  )
      VALUES
      ('TBL_SPGLEAKAGEEXT', v_temp_xml, v_col_id);

          DELETE FROM  TBL_SPGLEAKAGEEXT
          WHERE COL_SPGLEAKAGEEXTCASE = v_col_id;

END IF;

/*****************************************************************************************************************************/
SELECT DBURIType('/'||v_schema_name||'/TBL_DCM_WORKACTIVITY/ROW[COL_WORKACTIVITYCASE='||v_col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL;

IF v_temp_xml IS NOT NULL THEN 
      INSERT INTO TBL_HISTORY_CASE
      (col_origin_table_name, col_xml_data, col_case_id  )
      VALUES
      ('TBL_DCM_WORKACTIVITY', (v_temp_xml), v_col_id);

          DELETE FROM  TBL_DCM_WORKACTIVITY
          WHERE COL_WORKACTIVITYCASE = v_col_id;
END IF;
/*****************************************************************************************************************************/
FOR rec IN (SELECT col_id FROM TBL_CASEPARTY WHERE COL_CASEPARTYCASE = v_col_id) LOOP

    INSERT INTO TBL_HISTORY_CASE
      (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
      ('TBL_CASEPARTY', (SELECT DBURIType('/'||v_schema_name||'/TBL_CASEPARTY/ROW[COL_ID='||rec.col_id||']').getXML() FROM DUAL), v_col_id);

    DELETE FROM  TBL_CASEPARTY
      WHERE COL_ID = rec.col_id;

END LOOP;


/*****************************************************************************************************************************/
/*****************************************************************************************************************************/

FOR CASEDOCUMENT IN (SELECT col_id, col_doccasedocument  FROM Tbl_Doc_Doccase WHERE  col_doccasecase  = v_col_id ) LOOP
 
/*****************************************************************************************************************************/ 
SELECT DBURIType('/'||v_schema_name||'/TBL_DOC_DOCUMENT/ROW[COL_ID='||CASEDOCUMENT.col_doccasedocument||']').getXML() 
into v_temp_xml
FROM DUAL;

IF v_temp_xml IS NOT NULL THEN 
        INSERT INTO TBL_HISTORY_CASE
        (col_origin_table_name, col_xml_data, col_case_id  )
        VALUES
        ('TBL_DOC_DOCUMENT', (v_temp_xml), v_col_id);

            DELETE FROM  TBL_DOC_DOCUMENT
            WHERE COL_ID = CASEDOCUMENT.col_doccasedocument;  
END IF;            
/*****************************************************************************************************************************/



END LOOP;
/*****************************************************************************************************************/
SELECT DBURIType('/'||v_schema_name||'/TBL_DOCFOLDER/ROW[COL_DOCFOLDERCASE='||v_col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL;

/*
IF v_temp_xml IS NOT NULL THEN 
      INSERT INTO TBL_HISTORY_CASE
      (col_origin_table_name, col_xml_data, col_case_id  )
      VALUES
      ('TBL_DOCFOLDER', (v_temp_xml), v_col_id);

          DELETE FROM  TBL_DOCFOLDER
          WHERE COL_DOCFOLDERCASE = v_col_id;
END IF;
*/
/*****************************************************************************************************************/
SELECT DBURIType('/'||v_schema_name||'/TBL_CASESERVICEEXT/ROW[COL_CASECASESERVICEEXT='||v_col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL;

IF v_temp_xml IS NOT NULL THEN 
      INSERT INTO TBL_HISTORY_CASE
      (col_origin_table_name, col_xml_data, col_case_id  )
      VALUES
      ('TBL_CASESERVICEEXT', (v_temp_xml), v_col_id);

          DELETE FROM  TBL_CASESERVICEEXT
          WHERE COL_CASECASESERVICEEXT = v_col_id;
END IF;
/*****************************************************************************************************************/

SELECT DBURIType('/'||v_schema_name||'/TBL_SUBSCRIPTION/ROW[COL_SUBSCRIPTIONCASE='||v_col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL;

IF v_temp_xml IS NOT NULL THEN 
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_SUBSCRIPTION', (v_temp_xml), v_col_id);

        DELETE FROM  TBL_SUBSCRIPTION
        WHERE COL_SUBSCRIPTIONCASE = v_col_id;
END IF;
/*****************************************************************************************************************/

FOR rec IN (SELECT col_id FROM TBL_DATEEVENT WHERE COL_DATEEVENTCASE = v_col_id ) LOOP

    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_DATEEVENT', (SELECT DBURIType('/'||v_schema_name||'/TBL_DATEEVENT/ROW[COL_ID='||rec.col_id||']').getXML() FROM DUAL), v_col_id);

        DELETE FROM  TBL_DATEEVENT
        WHERE COL_ID = rec.col_id;

END LOOP;

/**********************************************************************************************************************/
SELECT DBURIType('/'||v_schema_name||'/TBL_SMPL_LOG/ROW[COL_CASELOG='||v_col_id||']').getXML()
INTO v_temp_xml  
FROM DUAL;

  IF v_temp_xml IS NOT NULL THEN 
      INSERT INTO TBL_HISTORY_CASE
      (col_origin_table_name, col_xml_data, col_case_id  )
      VALUES
      ('TBL_SMPL_LOG', (v_temp_xml), v_col_id);

          DELETE FROM  TBL_SMPL_LOG
          WHERE COL_CASELOG = v_col_id;
  END IF;
  
/**********************************************************************************************************************/  
  SELECT DBURIType('/'||v_schema_name||'/TBL_NOTE/ROW[COL_CASENOTE='||v_col_id||']').getXML() 
  INTO v_temp_xml 
  FROM DUAL;

  IF v_temp_xml IS NOT NULL THEN 
        INSERT INTO TBL_HISTORY_CASE
        (col_origin_table_name, col_xml_data, col_case_id  )
        VALUES
        ('TBL_NOTE', (v_temp_xml), v_col_id);

            DELETE FROM  TBL_NOTE
            WHERE COL_CASENOTE = v_col_id;
  END IF;
/**********************************************************************************************************************/

/*Tables connected to task**/

FOR task IN (SELECT col_id, col_tw_workitemtask  FROM tbl_task WHERE col_CaseTask =  v_col_id ) LOOP

/**********************************************************************************************************************/
SELECT DBURIType('/'||v_schema_name||'/TBL_TASKDOCUMENT/ROW[COL_TASKDOCTASK='||task.col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL;

/*
IF v_temp_xml IS NOT NULL THEN 
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_TASKDOCUMENT', (v_temp_xml), v_col_id);

        DELETE FROM  TBL_TASKDOCUMENT
        WHERE COL_TASKDOCTASK = task.col_id;
END IF;    
*/    
/**********************************************************************************************************************/


SELECT DBURIType('/'||v_schema_name||'/TBL_TASKEXT/ROW[COL_TASKEXTTASK='||task.col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL;        

IF v_temp_xml IS NOT NULL THEN 
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_TASKEXT', (v_temp_xml), v_col_id);

        DELETE FROM  TBL_TASKEXT
        WHERE COL_TASKEXTTASK = task.col_id;        
END IF;        
/**********************************************************************************************************************/ 

SELECT DBURIType('/'||v_schema_name||'/TBL_NOTE/ROW[COL_TASKNOTE='||task.col_id||']').getXML() 
into v_temp_xml
FROM DUAL;

IF  v_temp_xml IS NOT NULL THEN 
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_NOTE', (v_temp_xml), v_col_id);

        DELETE FROM  TBL_NOTE
        WHERE COL_TASKNOTE = task.col_id;
END IF;        

/**********************************************************************************************************************/ 

SELECT DBURIType('/'||v_schema_name||'/TBL_COMMONEVENT/ROW[COL_COMMONEVENTTASK='||task.col_id||']').getXML() 
INTO v_temp_xml
FROM DUAL;

IF v_temp_xml IS NOT NULL THEN 
    INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_COMMONEVENT', (v_temp_xml), v_col_id);

        DELETE FROM  TBL_COMMONEVENT
        WHERE col_CommonEventTask = task.col_id;
END IF;        
/**********************************************************************************************************************/ 
 FOR smplLog IN (SELECT col_id FROM tbl_SMPL_Log WHERE col_TaskLog = task.col_id) LOOP
   
         INSERT INTO TBL_HISTORY_CASE
            (col_origin_table_name, col_xml_data, col_case_id  )
         VALUES
            ('TBL_SMPL_LOG', (SELECT DBURIType('/'||v_schema_name||'/TBL_SMPL_LOG/ROW[COL_ID='||smplLog.col_id||']').getXML() FROM DUAL), v_col_id);

        DELETE FROM  TBL_SMPL_LOG
        WHERE COL_ID = smplLog.col_id;  
 
 
 END LOOP;  --smplLog
 
 FOR action IN (SELECT col_id FROM tbl_action WHERE col_ActionTask = task.col_id) LOOP 
   
          INSERT INTO TBL_HISTORY_CASE
            (col_origin_table_name, col_xml_data, col_case_id  )
         VALUES
            ('TBL_AUTORULEPARAMETER', (SELECT DBURIType('/'||v_schema_name||'/TBL_AUTORULEPARAMETER/ROW[COL_ACTIONAUTORULEPARAMETER='||action.col_id||']').getXML() FROM DUAL), v_col_id);   
   
          DELETE FROM  TBL_AUTORULEPARAMETER
          WHERE COL_ACTIONAUTORULEPARAMETER = action.col_id;  
    
          INSERT INTO TBL_HISTORY_CASE
            (col_origin_table_name, col_xml_data, col_case_id  )
         VALUES
            ('TBL_ACTION', (SELECT DBURIType('/'||v_schema_name||'/TBL_ACTION/ROW[COL_ID='||action.col_id||']').getXML() FROM DUAL), v_col_id);

        DELETE FROM  TBL_ACTION
        WHERE COL_ID = action.col_id;  
   
 END LOOP;  --action

     FOR dataevent IN (SELECT col_id FROM TBL_DATEEVENT WHERE COL_DATEEVENTTASK = task.col_id ) LOOP
       
          INSERT INTO TBL_HISTORY_CASE
             (col_origin_table_name, col_xml_data, col_case_id  )
          VALUES
            ('TBL_DATEEVENT', (SELECT DBURIType('/'||v_schema_name||'/TBL_DATEEVENT/ROW[COL_ID='||dataevent.col_id||']').getXML() FROM DUAL), v_col_id);

              DELETE FROM  TBL_DATEEVENT
              WHERE COL_ID = dataevent.col_id;
     END LOOP; --dataevent
     
     FOR taskinit IN (SELECT col_id FROM tbl_map_taskstateinitiation WHERE col_map_taskstateinittask   = task.col_id) LOOP
          
     
            
     
          FOR taskdep IN (SELECT col_id FROM tbl_taskdependency 
                             WHERE col_tskdpndchldtskstateinit = taskinit.col_id  
                                OR col_tskdpndprnttskstateinit = taskinit.col_id ) LOOP
                                
                SELECT DBURIType('/'||v_schema_name||'/TBL_AUTORULEPARAMETER/ROW[COL_AUTORULEPARAMTASKDEP='||taskdep.col_id||']').getXML() 
                INTO v_temp_xml
                FROM DUAL ;
                
                IF v_temp_xml IS NOT NULL THEN 
                    INSERT INTO TBL_HISTORY_CASE
                        (col_origin_table_name, col_xml_data, col_case_id  )
                     VALUES
                        ('TBL_AUTORULEPARAMETER', v_temp_xml, v_col_id);

                        DELETE FROM  TBL_AUTORULEPARAMETER
                        WHERE COL_AUTORULEPARAMTASKDEP = taskdep.col_id;                                   
                END IF; 
                          
                INSERT INTO TBL_HISTORY_CASE
                    (col_origin_table_name, col_xml_data, col_case_id  )
                 VALUES
                    ('TBL_TASKDEPENDENCY', (SELECT DBURIType('/'||v_schema_name||'/TBL_TASKDEPENDENCY/ROW[COL_ID='||taskdep.col_id||']').getXML() FROM DUAL), v_col_id);

                    DELETE FROM  TBL_TASKDEPENDENCY
                    WHERE COL_ID = taskdep.col_id;                                   
                                
          END LOOP; ---taskdep

          FOR taskevent IN (SELECT col_id FROM tbl_taskevent WHERE col_TaskEventTaskStateInit = taskinit.col_id) LOOP
            
   /******************************************************************************************************************************/           
             SELECT DBURIType('/'||v_schema_name||'/TBL_TASKEVENTQUEUE/ROW[COL_TASKEVENTQUEUETASKEVENT='||taskevent.col_id||']').getXML() 
             INTO v_temp_xml
             FROM DUAL;
             
             IF v_temp_xml IS NOT NULL THEN 
                   INSERT INTO TBL_HISTORY_CASE
                    (col_origin_table_name, col_xml_data, col_case_id  )
                    VALUES
                    ('TBL_TASKEVENTQUEUE', (v_temp_xml), v_col_id);

                        DELETE FROM  TBL_TASKEVENTQUEUE
                        WHERE COL_TASKEVENTQUEUETASKEVENT = taskevent.col_id;  
              END IF;            
   /******************************************************************************************************************************/           
              SELECT DBURIType('/'||v_schema_name||'/TBL_AUTORULEPARAMETER/ROW[COL_TASKEVENTAUTORULEPARAM='||taskevent.col_id||']').getXML() 
              INTO v_temp_xml
              FROM DUAL;
              
              IF v_temp_xml IS NOT NULL THEN 
                  INSERT INTO TBL_HISTORY_CASE
                     (col_origin_table_name, col_xml_data, col_case_id  )
                  VALUES
                    ('TBL_AUTORULEPARAMETER', (v_temp_xml), v_col_id);

                      DELETE FROM  TBL_AUTORULEPARAMETER
                      WHERE COL_TASKEVENTAUTORULEPARAM = taskevent.col_id;                            
              END IF;    
   /******************************************************************************************************************************/ 
   
   INSERT INTO TBL_HISTORY_CASE
                 (col_origin_table_name, col_xml_data, col_case_id  )
              VALUES
                ('TBL_TASKEVENT', (SELECT DBURIType('/'||v_schema_name||'/TBL_TASKEVENT/ROW[COL_ID='||taskevent.col_id||']').getXML() FROM DUAL), v_col_id);

                  DELETE FROM  TBL_TASKEVENT
                  WHERE COL_ID = taskevent.col_id;                       
       
       
          END LOOP; --taskevent   

--
      SELECT DBURIType('/'||v_schema_name||'/TBL_AUTORULEPARAMETER/ROW[COL_RULEPARAM_TASKSTATEINIT='||taskinit.col_id||']').getXML() 
       INTO v_temp_xml
      FROM DUAL;
          IF v_temp_xml IS NOT NULL THEN  
                INSERT INTO TBL_HISTORY_CASE
                   (col_origin_table_name, col_xml_data, col_case_id  )
                VALUES
                  ('TBL_AUTORULEPARAMETER',(v_temp_xml) , v_col_id);
          END IF;    
      
          INSERT INTO TBL_HISTORY_CASE
             (col_origin_table_name, col_xml_data, col_case_id  )
          VALUES
            ('TBL_MAP_TASKSTATEINITIATION', (SELECT DBURIType('/'||v_schema_name||'/TBL_MAP_TASKSTATEINITIATION/ROW[COL_ID='||taskinit.col_id||']').getXML() FROM DUAL), v_col_id);

              DELETE FROM  TBL_MAP_TASKSTATEINITIATION
              WHERE COL_ID = taskinit.col_id;   
     
     
     END LOOP;  --taskinit
     FOR slaevent IN (SELECT col_id FROM tbl_SLAEvent WHERE col_SLAEventTask = task.col_id) LOOP
       
     
              FOR slaaction IN (SELECT col_id FROM  tbl_slaaction WHERE  col_SLAActionSLAEvent = slaevent.col_id) LOOP
                   
                  
                   FOR SLAActionQueue IN (SELECT col_id FROM tbl_SLAActionQueue WHERE col_SLAActionQueueSLAAction = slaaction.col_id) LOOP
                     
                        INSERT INTO TBL_HISTORY_CASE
                           (col_origin_table_name, col_xml_data, col_case_id  )
                        VALUES
                          ('TBL_SLAACTIONQUEUE', (SELECT DBURIType('/'||v_schema_name||'/TBL_SLAACTIONQUEUE/ROW[COL_ID='||SLAActionQueue.col_id||']').getXML() FROM DUAL), v_col_id);

                            DELETE FROM  TBL_SLAACTIONQUEUE
                            WHERE COL_ID = SLAActionQueue.col_id;                       
                     
                   END LOOP;  
                   
                   FOR autorule IN (SELECT col_id  FROM tbl_autoruleparameter WHERE col_autoruleparamslaaction = slaaction.col_id) LOOP
                     
                        INSERT INTO TBL_HISTORY_CASE
                           (col_origin_table_name, col_xml_data, col_case_id  )
                        VALUES
                          ('TBL_AUTORULEPARAMETER', (SELECT DBURIType('/'||v_schema_name||'/TBL_AUTORULEPARAMETER/ROW[COL_ID='||autorule.col_id||']').getXML() FROM DUAL), v_col_id);

                            DELETE FROM  TBL_AUTORULEPARAMETER
                            WHERE COL_ID = autorule.col_id;                       
                     
                   END LOOP;  --autorule
                
                  INSERT INTO TBL_HISTORY_CASE
                     (col_origin_table_name, col_xml_data, col_case_id  )
                  VALUES
                    ('TBL_SLAACTION', (SELECT DBURIType('/'||v_schema_name||'/TBL_SLAACTION/ROW[COL_ID='||slaaction.col_id||']').getXML() FROM DUAL), v_col_id);

                      DELETE FROM  TBL_SLAACTION
                      WHERE COL_ID = slaaction.col_id;          
              
              
              END LOOP;  --slaaction 
              
                   FOR SLAActionQueue IN (SELECT col_id FROM tbl_SLAActionQueue WHERE col_SLAActionQueueSLAEvent = slaevent.col_id) LOOP
                     
                        INSERT INTO TBL_HISTORY_CASE
                           (col_origin_table_name, col_xml_data, col_case_id  )
                        VALUES
                          ('TBL_SLAACTIONQUEUE', (SELECT DBURIType('/'||v_schema_name||'/TBL_SLAACTIONQUEUE/ROW[COL_ID='||SLAActionQueue.col_id||']').getXML() FROM DUAL), v_col_id);

                            DELETE FROM  TBL_SLAACTIONQUEUE
                            WHERE COL_ID = SLAActionQueue.col_id;                       
                     
                   END LOOP;               
       
              INSERT INTO TBL_HISTORY_CASE
                 (col_origin_table_name, col_xml_data, col_case_id  )
              VALUES
                ('TBL_SLAEVENT', (SELECT DBURIType('/'||v_schema_name||'/TBL_SLAEVENT/ROW[COL_ID='||slaevent.col_id||']').getXML() FROM DUAL), v_col_id);

                  DELETE FROM  TBL_SLAEVENT
                  WHERE COL_ID = slaevent.col_id;          
     
     END LOOP;  --slaevent

     FOR thread IN (SELECT col_id FROM tbl_thread WHERE col_ThreadSourceTask = task.col_id OR col_ThreadTargetTask = task.col_id ) LOOP
       
              INSERT INTO TBL_HISTORY_CASE
                 (col_origin_table_name, col_xml_data, col_case_id  )
              VALUES
                ('TBL_THREAD', (SELECT DBURIType('/'||v_schema_name||'/TBL_THREAD/ROW[COL_ID='||thread.col_id||']').getXML() FROM DUAL), v_col_id);

                  DELETE FROM  TBL_THREAD
                  WHERE COL_ID = thread.col_id;         
     END LOOP; --thread  
     FOR slahold IN (SELECT col_id FROM tbl_SLAHold WHERE col_SLAHoldTask	= task.col_id) LOOP
       
              INSERT INTO TBL_HISTORY_CASE
                 (col_origin_table_name, col_xml_data, col_case_id  )
              VALUES
                ('TBL_SLAHOLD', (SELECT DBURIType('/'||v_schema_name||'/TBL_SLAHOLD/ROW[COL_ID='||slahold.col_id||']').getXML() FROM DUAL), v_col_id);

                  DELETE FROM  TBL_SLAHOLD
                  WHERE COL_ID = slahold.col_id;       
       
     END LOOP;  --	slahold	
     
        INSERT INTO TBL_HISTORY_CASE
    (col_origin_table_name, col_xml_data, col_case_id  )
    VALUES
    ('TBL_TW_WORKITEM', (SELECT DBURIType('/'||v_schema_name||'/TBL_TW_WORKITEM/ROW[COL_ID='||task.col_tw_workitemtask||']').getXML() FROM DUAL), v_col_id);

        DELETE FROM  TBL_TW_WORKITEM
        WHERE COL_ID = task.col_tw_workitemtask;  

     INSERT INTO TBL_HISTORY_CASE
       (col_origin_table_name, col_xml_data, col_case_id  )
     VALUES
        ('TBL_TASK', (SELECT DBURIType('/'||v_schema_name||'/TBL_TASK/ROW[COL_ID='||task.col_id||']').getXML() FROM DUAL), v_col_id);

      DELETE FROM  TBL_TASK
      WHERE COL_ID = task.col_id;       
     
     
END LOOP; --task


/**/





FOR rec IN (SELECT col_CW_WorkitemCase FROM tbl_case WHERE col_id = v_col_id) LOOP

        INSERT INTO TBL_HISTORY_CASE
        (col_origin_table_name, col_xml_data, col_case_id  )
        VALUES
        ('TBL_CW_WORKITEM', (SELECT DBURIType('/'||v_schema_name||'/TBL_CW_WORKITEM/ROW[COL_ID='||rec.col_CW_WorkitemCase||']').getXML() FROM DUAL), v_col_id);

            DELETE FROM  TBL_CW_WORKITEM
            WHERE COL_ID = rec.col_CW_WorkitemCase;
            

END LOOP;

INSERT INTO TBL_HISTORY_CASE
(col_origin_table_name, col_xml_data, col_case_id  )
VALUES
('TBL_CASE', (SELECT DBURIType('/'||v_schema_name||'/TBL_CASE/ROW[COL_ID='||v_col_id||']').getXML() FROM DUAL), v_col_id);

    DELETE FROM  TBL_CASE
    WHERE COL_ID = v_col_id;


RETURN 'Ok';

EXCEPTION
  WHEN OTHERS THEN
    RETURN dbms_utility.format_error_stack || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
END;