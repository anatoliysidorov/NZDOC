DECLARE
    v_StartTaskId INTEGER;
    v_SlaActionId INTEGER;
    v_counter INTEGER;
    v_lastcounter INTEGER;
BEGIN
    v_StartTaskId := :StartTaskId;
    SELECT gen_tbl_slaevent.nextval
    INTO   v_counter
    FROM   dual ;
    
    BEGIN
        INSERT INTO tbl_slaevent
               (col_slaeventtask,
                      col_slaeventdict_slaeventtype,
                      col_slaevent_dateeventtype,
                      col_intervalds,
                      col_intervalym,
                      col_slaevent_slaeventlevel,
                      col_maxattempts,
                      col_attemptcount,
                      col_slaeventorder
               )
               (
                          SELECT     tsk.col_id,
                                     se.col_slaeventdict_slaeventtype,
                                     se.col_slaevent_dateeventtype,
                                     se.col_intervalds,
                                     se.col_intervalym,
                                     se.col_slaevent_slaeventlevel,
                                     se.col_maxattempts,
                                     se.col_attemptcount,
                                     se.col_slaeventorder
                          FROM       tbl_slaevent        se
                                     INNER JOIN tbl_task tsk ON se.col_slaeventtasktemplate = tsk.col_id2
                          WHERE      tsk.col_id > v_StartTaskId
               ) ;
        
        SELECT gen_tbl_slaevent.currval
        INTO   v_lastcounter
        FROM   dual ;
        
        FOR rec2 IN
        (
                   SELECT     tsk.col_id2                    AS TaskTmplId,
                              se2.col_id                     AS SlaEventId,
                              sa.col_id                      AS SlaActionId,
                              sa.col_code                    AS SlaActionCode,
                              sa.col_name                    AS SlaActionName,
                              sa.col_processorcode           AS SlaActionProcCode,
                              sa.col_slaaction_slaeventlevel AS SlaEventLevel,
                              sa.col_actionorder             AS SlaActionOrder
                   FROM       tbl_slaaction                     sa
                              INNER JOIN tbl_slaevent           se  ON sa.col_slaactionslaevent = se.col_id
                              INNER JOIN tbl_task               tsk ON se.col_slaeventtasktemplate = tsk.col_id2
                              INNER JOIN tbl_slaevent           se2 ON tsk.col_id = se2.col_slaeventtask AND se.col_slaeventorder = se2.col_slaeventorder
                   WHERE      se.col_id IN
                              (
                                         SELECT     se.col_id
                                         FROM       tbl_slaevent        se
                                                    INNER JOIN tbl_task tsk ON se.col_slaeventtasktemplate = tsk.col_id2
                                         WHERE      tsk.col_id > v_StartTaskId
                              )
                              AND tsk.col_id > v_StartTaskId
                   ORDER BY
                              sa.col_actionorder
        )
        LOOP
            INSERT INTO tbl_slaaction
                   (col_code,
                          col_name,
                          col_processorcode,
                          col_slaactionslaevent,
                          col_slaaction_slaeventlevel,
                          col_actionorder
                   )
                   VALUES
                   (sys_guid(),
                          rec2.SlaActionName,
                          rec2.SlaActionProcCode,
                          rec2.SlaEventId,
                          rec2.SlaEventLevel,
                          rec2.SlaActionOrder
                   ) ;
            
            SELECT gen_tbl_slaaction.currval
            INTO   v_SlaActionId
            FROM   dual ;
            
            FOR rec3 IN
            (
                       SELECT     arp.col_paramcode           AS ParamCode,
                                  col_paramvalue              AS ParamValue
                       FROM       tbl_autoruleparameter          arp
                                  INNER JOIN tbl_slaaction       sa ON arp.col_autoruleparamslaaction = sa.col_id
                                  INNER JOIN tbl_slaevent        se ON sa.col_slaactionslaevent = se.col_id
                                  INNER JOIN tbl_tasktemplate    tt ON se.col_slaeventtasktemplate = tt.col_id
                       WHERE      tt.col_id = rec2.TaskTmplId
                                  AND sa.col_id = rec2.SlaActionId
            )
            LOOP
                INSERT INTO tbl_autoruleparameter
                       (col_code,
                              col_autoruleparamslaaction,
                              col_paramcode,
                              col_paramvalue
                       )
                       VALUES
                       (sys_guid(),
                              v_SlaActionId,
                              rec3.ParamCode,
                              rec3.ParamValue
                       ) ;
            
            END LOOP;
        END LOOP;
    EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RETURN -1;
    WHEN OTHERS THEN
        RETURN -1;
    END;
    SELECT gen_tbl_slaevent.currval
    INTO   v_lastcounter
    FROM   dual ;
    
    FOR rec IN
    (
           SELECT col_id
           FROM   tbl_slaevent
           WHERE  col_id BETWEEN v_counter AND v_lastcounter
    )
    LOOP
        UPDATE
               tbl_slaevent
        SET    col_code = sys_guid()
        WHERE  col_id = rec.col_id ;
    
    END LOOP;
END;