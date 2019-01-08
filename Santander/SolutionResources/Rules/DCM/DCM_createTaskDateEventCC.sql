DECLARE
    v_date            DATE;
    v_performedby     NVARCHAR2(255);
    v_caseworkerid    INTEGER;
    v_taskid          INTEGER;
    v_name            NVARCHAR2(255);
    v_eventtypeid     INTEGER;
    v_eventtypecode   NVARCHAR2(255);
    v_dateeventid     INTEGER;
    v_multipleallowed NUMBER;
    v_canoverwrite    NUMBER;
    v_result          NUMBER;
BEGIN
    v_taskid := :TaskId;
    v_name := :Name;
    v_date := SYSDATE;
    v_performedby := Sys_context('CLIENTCONTEXT', 'AccessSubject');

    BEGIN
        SELECT id
        INTO   v_caseworkerid
        FROM   vw_ppl_caseworkersusers
        WHERE  accode = v_performedby;
    EXCEPTION
        WHEN no_data_found THEN
          v_caseworkerid := NULL;
    END;

    BEGIN
        SELECT col_id,
               col_code,
               col_multipleallowed,
               col_canoverwrite
        INTO   v_eventtypeid, v_eventtypecode, v_multipleallowed, v_canoverwrite
        FROM   tbl_dict_dateeventtype
        WHERE  Upper(col_code) = Upper(v_name);
    EXCEPTION
        WHEN no_data_found THEN
          v_eventtypeid := NULL;
          v_eventtypecode := NULL;
          v_multipleallowed := NULL;
          v_canoverwrite := NULL;
    END;

    IF ( v_multipleallowed IS NULL ) OR ( v_multipleallowed = 0 ) THEN
      BEGIN
          SELECT col_id
          INTO   v_dateeventid
          FROM   tbl_dateeventcc
          WHERE  col_dateeventcctaskcc = v_taskid
                 AND Upper(col_datename) = Upper(v_name);
      EXCEPTION
          WHEN no_data_found THEN
            v_dateeventid := NULL;
          WHEN too_many_rows THEN
            DELETE FROM tbl_dateeventcc
            WHERE  col_dateeventcctaskcc = v_taskid AND Upper(col_datename) = Upper(v_name);
            v_dateeventid := NULL;
      END;
    ELSE
      v_dateeventid := NULL;
    END IF;

    IF ( v_dateeventid IS NULL ) THEN
      v_result := f_DCM_fwrdDateEventCC();
      INSERT INTO tbl_dateeventcc
                  (col_dateeventcctaskcc,
                   col_datename,
                   col_datevalue,
                   col_performedby,
                   col_dateeventccppl_caseworker,
                   col_dateeventccppl_workbasket,
                   col_dateeventcc_dateeventtype)
      VALUES      (v_taskid,
                   Upper(v_name),
                   v_date,
                   v_performedby,
                   v_caseworkerid,
                   (select col_taskppl_workbasket from tbl_task where col_id = v_taskid),
                   v_eventtypeid);
    ELSIF ( v_dateeventid IS NOT NULL ) AND ( v_multipleallowed IS NOT NULL ) AND ( v_multipleallowed = 1 ) THEN
      v_result := f_DCM_fwrdDateEventCC();
      INSERT INTO tbl_dateeventcc
                  (col_dateeventcctaskcc,
                   col_datename,
                   col_datevalue,
                   col_performedby,
                   col_dateeventccppl_caseworker,
                   col_dateeventccppl_workbasket,
                   col_dateeventcc_dateeventtype)
      VALUES      (v_taskid,
                   Upper(v_name),
                   v_date,
                   v_performedby,
                   v_caseworkerid,
                   (select col_taskppl_workbasket from tbl_task where col_id = v_taskid),
                   v_eventtypeid);
    ELSIF ( v_dateeventid IS NOT NULL ) AND ( ( v_multipleallowed IS NULL ) OR ( v_multipleallowed = 0 ) ) AND ( v_canoverwrite IS NOT NULL ) AND ( v_canoverwrite = 1 ) THEN
      UPDATE tbl_dateeventcc
      SET    col_datevalue = v_date,
             col_performedby = v_performedby,
             col_dateeventccppl_caseworker = v_caseworkerid,
             col_dateeventccppl_workbasket = (select col_taskppl_workbasket from tbl_task where col_id = v_taskid)
      WHERE  col_dateeventcctaskcc = v_taskid
             AND Upper(col_datename) = Upper(v_name);
    END IF;
END;