DECLARE
  v_TaskId INTEGER;
  v_state   NVARCHAR2(255) ;
  v_result  NUMBER;
  v_target  NVARCHAR2(255);
  v_FINISHDATEEVENTVALUE      DATE;
  v_SLAEVENTDATE              DATE;
  v_STARTDATEEVENTBY          NVARCHAR2(255);
  v_STARTDATEEVENTVALUE       DATE;


BEGIN
  v_TaskId := :TaskId;
  v_state := :state;

  FOR rec IN(
  SELECT     ts.col_id AS TaskStateId,
             ts.col_code AS TaskStateCode,
             ts.col_name AS TaskStateName,
             ts.col_activity AS TaskStateActivity,
             det.col_id AS DateEventTypeId,
             det.col_code AS DateEventTypeCode,
             det.col_name AS DateEventTypeName
  FROM       tbl_dict_taskstate ts
  INNER JOIN tbl_dict_tskst_dtevtp tsdet ON ts.col_id = tsdet.col_tskst_dtevtptaskstate
  INNER JOIN tbl_dict_dateeventtype det  ON tsdet.col_tskst_dtevtpdateeventtype = det.col_id
  WHERE      ts.col_activity = v_state
  )
  LOOP
      v_result := f_DCM_createTaskDateEventCC(Name => rec.DateEventTypeCode, TaskId => v_TaskId) ;
  END LOOP;

  --DCM-5571 begin  
  v_target := f_dcm_getTaskClosedState();

  FOR rec IN
  (
  SELECT COL_SLAEVENTCCSLAEVENT AS SEId, COL_SLAEVENTCC_DATEEVENTTYPE AS DateEventTypeId 
  FROM TBL_SLAEVENTCC 
  WHERE COL_SLAEVENTCCTASKCC=v_TaskId
  )
  LOOP 
    v_FINISHDATEEVENTVALUE  := NULL; 
    v_SLAEVENTDATE          := NULL;
    v_STARTDATEEVENTBY      := NULL;
    v_STARTDATEEVENTVALUE   := NULL;

    BEGIN
      SELECT MAX(COL_DATEVALUE) INTO  v_STARTDATEEVENTVALUE
      FROM TBL_DATEEVENTCC
      WHERE  COL_DATEEVENTCCTASKCC=v_TaskId AND
             COL_DATEEVENTCC_DATEEVENTTYPE=rec.DateEventTypeId;
    EXCEPTION 
      WHEN NO_DATA_FOUND THEN v_STARTDATEEVENTVALUE := NULL;
    END;

   IF v_STARTDATEEVENTVALUE IS NOT NULL THEN
    BEGIN
      SELECT s.COL_PERFORMEDBY INTO v_STARTDATEEVENTBY
      FROM
          ( 
          SELECT ROWNUM AS RN, COL_PERFORMEDBY
          FROM TBL_DATEEVENTCC
          WHERE  COL_DATEEVENTCCTASKCC=v_TaskId AND
                 COL_DATEEVENTCC_DATEEVENTTYPE=rec.DateEventTypeId AND
                 COL_DATEVALUE=v_STARTDATEEVENTVALUE
          ) s
       WHERE s.RN=1;
    END;  
    
    IF v_state=v_target  THEN v_FINISHDATEEVENTVALUE := v_STARTDATEEVENTVALUE; END IF;

    UPDATE TBL_SLAEVENTCC se2
    SET  COL_FINISHDATEEVENTVALUE  = v_FINISHDATEEVENTVALUE,
         COL_STARTDATEEVENTVALUE = v_STARTDATEEVENTVALUE, 
         COL_STARTDATEEVENTBY = v_STARTDATEEVENTBY,
         COL_SLAEVENTDATE = v_STARTDATEEVENTVALUE + NVL(TO_DSINTERVAL(se2.COL_INTERVALDS),TO_DSINTERVAL('0 0' || ':' || '0' || ':' || '0')) + NVL(TO_YMINTERVAL(se2.COL_INTERVALYM),TO_YMINTERVAL('0-0'))
    WHERE COL_ID=rec.SEId;

   END IF; --v_STARTDATEEVENTVALUE IS NOT NULL
  
  END LOOP;

  update tbl_taskcc tsk
  set col_goalslaeventdate = (select max(col_slaeventdate) from tbl_slaeventcc where col_slaeventcctaskcc = tsk.col_id and col_slaeventcc_slaeventtype =
  (select col_id from tbl_dict_slaeventtype where col_code = 'GOAL')),
  col_dlineslaeventdate = (select max(col_slaeventdate) from tbl_slaeventcc where col_slaeventcctaskcc = tsk.col_id and col_slaeventcc_slaeventtype =
  (select col_id from tbl_dict_slaeventtype where col_code = 'DEADLINE'))
  where tsk.col_id = v_TaskId;

  --DCM-5571 end

END;