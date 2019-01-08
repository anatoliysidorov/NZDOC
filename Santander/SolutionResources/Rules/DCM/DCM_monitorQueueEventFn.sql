DECLARE
    v_processedstatus   NUMBER;
    v_errorstatus       NUMBER;
    v_stateresolved     NVARCHAR2(255);
    v_caseid            INTEGER;
    v_result            NUMBER;
BEGIN
    v_stateresolved := f_dcm_gettaskresolvedstate ();
    FOR rec IN (
        SELECT
            col_id,
            col_queueeventid,
            col_taskeventqueuetask
        FROM
            tbl_taskeventqueue
        WHERE
            col_queueeventid IS NOT NULL
    ) LOOP
        BEGIN
            SELECT
                processedstatus,
                errorstatus
            INTO
                v_processedstatus,v_errorstatus
            FROM
                queue_event
            WHERE
                queueid = rec.col_queueeventid;

        EXCEPTION
            WHEN no_data_found THEN
                continue;
        END;

        IF
            v_processedstatus < 8
        THEN
            BEGIN
                SELECT
                    col_casetask
                INTO
                    v_caseid
                FROM
                    tbl_task
                WHERE
                    col_id = rec.col_taskeventqueuetask;

            EXCEPTION
                WHEN no_data_found THEN
                    v_caseid := NULL;
            END;
      
      --INVALIDATE CASE WHERE TASKS CHANGED THEIR STATE

            IF
                v_caseid IS NOT NULL
            THEN
                v_result := f_dcm_invalidatecase(caseid => v_caseid);
            END IF;

            continue;
        END IF;

        IF
            v_errorstatus = 1
        THEN
            UPDATE tbl_tw_workitem
                SET
                    col_activity = v_stateresolved,
                    col_tw_workitemprevtaskstate = col_tw_workitemdict_taskstate,
                    col_tw_workitemdict_taskstate = (
                        SELECT
                            col_id
                        FROM
                            tbl_dict_taskstate
                        WHERE
                            col_activity = v_stateresolved
                    )
            WHERE
                col_id = (
                    SELECT
                        col_tw_workitemtask
                    FROM
                        tbl_task
                    WHERE
                        col_id = rec.col_taskeventqueuetask
                );
                
      --SET TASK DATE EVENT

            v_result := f_dcm_createtaskdateevent(name => 'DATE_TASK_RESOLVED',taskid => rec.col_taskeventqueuetask);
            DELETE FROM tbl_taskeventqueue
            WHERE
                col_id = rec.col_id;

            BEGIN
                SELECT
                    col_casetask
                INTO
                    v_caseid
                FROM
                    tbl_task
                WHERE
                    col_id = rec.col_taskeventqueuetask;

            EXCEPTION
                WHEN no_data_found THEN
                    v_caseid := NULL;
            END;
      --INVALIDATE CASE WHERE TASKS CHANGED THEIR STATE

            IF
                v_caseid IS NOT NULL
            THEN
                v_result := f_dcm_invalidatecase(caseid => v_caseid);
            END IF;

        ELSIF v_errorstatus > 1 THEN
      --PROCESS ERROR IN QUEUE EVENT PROCESSING
            DELETE FROM tbl_taskeventqueue
            WHERE
                col_id = rec.col_id;

        END IF;

    END LOOP;

END;