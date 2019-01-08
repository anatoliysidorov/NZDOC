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
    v_CSisInCache     INTEGER;  
    v_taskppl_workbasket NUMBER;
    v_dteId    NUMBER;

BEGIN
  v_taskid := :TaskId;
  v_name := :Name;
  v_date := SYSDATE;
  
  v_performedby := Sys_context('CLIENTCONTEXT', 'AccessSubject');
  v_CSisInCache := f_DCM_CSisTaskInCache(v_TaskId);--new cache

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
        FROM   tbl_dateevent
        WHERE  col_dateeventtask = v_taskid
               AND Upper(col_datename) = Upper(v_name);
    EXCEPTION
        WHEN no_data_found THEN
          v_dateeventid := NULL;
        WHEN too_many_rows THEN
          DELETE FROM tbl_dateevent
          WHERE  col_dateeventtask = v_taskid AND Upper(col_datename) = Upper(v_name);
          v_dateeventid := NULL;
    END;
  ELSE
    v_dateeventid := NULL;
  END IF;

  --case not in new cache 
  IF v_CSisInCache=0 THEN	
     SELECT COL_TASKPPL_WORKBASKET  INTO v_taskppl_workbasket
     FROM TBL_TASK WHERE COL_ID = v_taskid;

    IF ( v_dateeventid IS NULL ) THEN
      INSERT INTO tbl_dateevent
                  (col_dateeventtask,
                   col_datename,
                   col_datevalue,
                   col_performedby,
                   col_dateeventppl_caseworker,
                   col_dateeventppl_workbasket,
                   col_dateevent_dateeventtype)
      VALUES      (v_taskid,
                   Upper(v_name),
                   v_date,
                   v_performedby,
                   v_caseworkerid,
                   v_taskppl_workbasket,
                   v_eventtypeid);
    ELSIF ( v_dateeventid IS NOT NULL ) AND ( v_multipleallowed IS NOT NULL ) AND ( v_multipleallowed = 1 ) THEN
      INSERT INTO tbl_dateevent
                  (col_dateeventtask,
                   col_datename,
                   col_datevalue,
                   col_performedby,
                   col_dateeventppl_caseworker,
                   col_dateeventppl_workbasket,
                   col_dateevent_dateeventtype)
      VALUES      (v_taskid,
                   Upper(v_name),
                   v_date,
                   v_performedby,
                   v_caseworkerid,
                   v_taskppl_workbasket,
                   v_eventtypeid);
    ELSIF ( v_dateeventid IS NOT NULL ) AND ( ( v_multipleallowed IS NULL ) OR ( v_multipleallowed = 0 ) ) AND ( v_canoverwrite IS NOT NULL ) AND ( v_canoverwrite = 1 ) THEN
      UPDATE tbl_dateevent
      SET    col_datevalue = v_date,
             col_performedby = v_performedby,
             col_dateeventppl_caseworker = v_caseworkerid,
             col_dateeventppl_workbasket = v_taskppl_workbasket
      WHERE  col_dateeventtask = v_taskid
             AND Upper(col_datename) = Upper(v_name);
    END IF;
  END IF;


      --case  in new cache 
  IF v_CSisInCache=1 THEN	
     
     SELECT gen_tbl_DateEvent.nextval INTO v_dteId FROM dual;

     SELECT COL_TASKPPL_WORKBASKET  INTO v_taskppl_workbasket
     FROM TBL_CSTASK WHERE COL_ID = v_taskid;

    IF ( v_dateeventid IS NULL ) THEN
      INSERT INTO TBL_CSDATEEVENT
                  (COL_ID,
                   COL_DATEEVENTTASK,
                   COL_DATENAME,
                   COL_DATEVALUE,
                   COL_PERFORMEDBY,
                   COL_DATEEVENTPPL_CASEWORKER,
                   COL_DATEEVENTPPL_WORKBASKET,
                   COL_DATEEVENT_DATEEVENTTYPE)
      VALUES      (v_dteId,
                   v_taskid,
                   Upper(v_name),
                   v_date,
                   v_performedby,
                   v_caseworkerid,
                   v_taskppl_workbasket,
                   v_eventtypeid);
    ELSIF ( v_dateeventid IS NOT NULL ) AND ( v_multipleallowed IS NOT NULL ) AND ( v_multipleallowed = 1 ) THEN
      INSERT INTO TBL_CSDATEEVENT
                  (COL_ID,
                   COL_DATEEVENTTASK,
                   COL_DATENAME,
                   COL_DATEVALUE,
                   COL_PERFORMEDBY,
                   COL_DATEEVENTPPL_CASEWORKER,
                   COL_DATEEVENTPPL_WORKBASKET,
                   COL_DATEEVENT_DATEEVENTTYPE)
      VALUES      (v_dteId,
                   v_taskid,
                   Upper(v_name),
                   v_date,
                   v_performedby,
                   v_caseworkerid,
                   v_taskppl_workbasket,
                   v_eventtypeid);
    ELSIF ( v_dateeventid IS NOT NULL ) AND ( ( v_multipleallowed IS NULL ) OR ( v_multipleallowed = 0 ) ) AND ( v_canoverwrite IS NOT NULL ) AND ( v_canoverwrite = 1 ) THEN
      UPDATE TBL_CSDATEEVENT
      SET    col_datevalue = v_date,
             col_performedby = v_performedby,
             col_dateeventppl_caseworker = v_caseworkerid,
             col_dateeventppl_workbasket = v_taskppl_workbasket
      WHERE  col_dateeventtask = v_taskid
             AND Upper(col_datename) = Upper(v_name);
    END IF;
  END IF;

END;