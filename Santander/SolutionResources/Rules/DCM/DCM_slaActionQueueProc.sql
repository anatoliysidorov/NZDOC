DECLARE 
    v_queueparams       NCLOB; 
    v_domain            NVARCHAR2(255); 
    v_result            NUMBER; 
    v_isvalid           NUMBER; 
    v_caseid            INTEGER; 
    v_slaeventid        INTEGER; 
    v_message           NCLOB; 
    v_input             NVARCHAR2(32767); 
	
	v_proccesedState INTEGER; 
	v_newState INTEGER; 
BEGIN 
    v_caseid := :CaseId; 
    v_slaeventid := 0; 
	
	v_proccesedState := f_UTIL_getIdByCode(TableName => 'tbl_dict_processingstatus', Code=> 'PROCESSED');
	v_newState := f_UTIL_getIdByCode(TableName => 'tbl_dict_processingstatus', Code=> 'NEW');


    --READ DOMAIN FROM CONFIGURATION 
    v_domain := f_UTIL_getDomainFn(); 

    --START TASKS FOR ALL CASES IN TASK EVENT QUEUE 
    FOR rec IN (SELECT saq.col_id                      AS SaqId, 
                       saq.col_slaactionqueueslaaction AS SaId, 
                       saq.col_slaactionqueueslaevent  AS SeId, 
                       sa.col_processorcode            AS ProcessorCode, 
                       tsk.col_id                      AS TaskId, 
                       se.col_attemptcount             AS AttemptCount, 
                       se.col_maxattempts              AS MaxAttempts 
                FROM   tbl_slaactionqueue saq 
                       inner join tbl_slaaction sa 
                               ON saq.col_slaactionqueueslaaction = sa.col_id 
                       inner join tbl_slaevent se 
                               ON sa.col_slaactionslaevent = se.col_id 
                       inner join tbl_task tsk 
                               ON se.col_slaeventtask = tsk.col_id 
                WHERE  tsk.col_casetask = v_caseid 
                       AND saq.col_slaactionqueueprocstatus = v_newState) 
	LOOP 	
		v_result := f_UTIL_createSysLogFn('SLA fired for ' || TO_CHAR(rec.TaskId));
	
	
        IF (Substr(rec.processorcode, 1, 2) = 'f_' ) THEN 
			v_input := '<CustomData><Attributes>'; 

			FOR rec2 IN (SELECT col_paramcode  AS ParamCode, 
						  col_paramvalue AS ParamValue 
				   FROM   tbl_autoruleparameter 
				   WHERE  col_autoruleparamslaaction = 
						  (SELECT col_id 
						   FROM   tbl_slaaction 
						   WHERE  col_id = rec.said)) 
			LOOP 
				v_input := v_input || '<' || rec2.paramcode || '>' || rec2.paramvalue || '</' || rec2.paramcode || '>'; 
			END LOOP; 

			v_input := v_input || '</Attributes></CustomData>'; 

			v_result := F_dcm_invokeslaprocessor2(
							input => v_input, 
							message => v_message, 
							processorname => rec.processorcode, 
							slaactionid => rec.said, 
							validationresult => v_isvalid
						); 

			UPDATE tbl_slaactionqueue 
			SET    col_slaactionqueueprocstatus = v_proccesedState 
			WHERE  col_id = rec.saqid; 
        ELSE 
          v_queueparams := F_util_jsonautoruleprmsla(rec.said); 
          v_result := f_UTIL_addToQueueFn(
								rulecode => rec.processorcode, 
								parameters => v_queueparams
							); 

          UPDATE tbl_slaactionqueue 
          SET    col_queueeventid = v_result, 
                 col_slaactionqueueprocstatus = v_proccesedState
          WHERE  col_id = rec.saqid; 
        END IF; 

        IF v_slaeventid <> rec.seid THEN 
          UPDATE tbl_slaevent 
          SET    col_attemptcount = col_attemptcount + 1 
          WHERE  col_id = rec.seid; 

          IF ( rec.attemptcount + 1 ) < rec.maxattempts THEN 
            DELETE FROM tbl_slaactionqueue 
            WHERE  col_slaactionqueueslaevent = rec.seid; 
          END IF; 

          v_slaeventid := rec.seid; 
        END IF; 
    END LOOP; 
END; 