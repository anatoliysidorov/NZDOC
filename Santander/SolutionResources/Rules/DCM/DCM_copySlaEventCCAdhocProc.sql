DECLARE
  v_TransactionId Integer;
  v_SlaActionId Integer;
  v_counter Integer;
  v_lastcounter Integer;
  v_SLAEVENTDATE              DATE;
  v_STARTDATEEVENTBY          NVARCHAR2(255);
  v_STARTDATEEVENTVALUE       DATE;
  v_FINISHDATEEVENTVALUE      DATE;

BEGIN
  
  v_TransactionId := :TransactionId;

  select gen_tbl_slaeventcc.nextval into v_counter from dual;

  BEGIN

    insert into tbl_slaeventcc(col_slaeventcctaskcc, col_slaeventcc_slaeventtype, col_slaeventcc_dateeventtype, 
                               col_intervalds, col_intervalym, col_slaeventcc_slaeventlevel, 
                               col_maxattempts, col_attemptcount, col_slaeventorder, col_code)
    (select tsk.col_id, se.col_slaeventtp_slaeventtype, se.col_slaeventtp_dateeventtype, 
            se.col_intervalds, se.col_intervalym, se.col_slaeventtp_slaeventlevel, 
            se.col_maxattempts, se.col_attemptcount, se.col_slaeventorder, sys_guid()
     from tbl_slaeventtmpl se
     inner join tbl_taskcc tsk on se.col_slaeventtptasktemplate = tsk.col_id2
     where tsk.col_transactionid = v_TransactionId);

    select gen_tbl_slaeventcc.currval into v_lastcounter from dual;

    FOR rec2 in (select tsk.col_id2 as TaskTmplId, secc.col_id as SlaEventId, sa.col_id as SlaActionId, sa.col_code as SlaActionCode, sa.col_name as SlaActionName,
                 sa.col_processorcode as SlaActionProcCode, sa.col_slaactiontp_slaeventlevel as SlaEventLevel,
                 sa.col_actionorder as SlaActionOrder
                 from tbl_slaactiontmpl sa
                 inner join tbl_slaeventtmpl se on sa.col_slaactiontpslaeventtp = se.col_id
                 inner join tbl_taskcc tsk on se.col_slaeventtptasktemplate = tsk.col_id2
                 inner join tbl_slaeventcc secc on tsk.col_id = secc.col_slaeventcctaskcc and se.col_slaeventorder = secc.col_slaeventorder
                 where se.col_id in (select se.col_id
                                     from tbl_slaeventtmpl se
                                     inner join tbl_taskcc tsk on se.col_slaeventtptasktemplate = tsk.col_id2
                                     where tsk.col_transactionid = v_TransactionId)
                 and tsk.col_transactionid = v_TransactionId
                 order by sa.col_actionorder)
    LOOP
      insert into tbl_slaactioncc(col_code, col_name, col_processorcode, col_slaactionccslaeventcc, 
                                  col_slaactioncc_slaeventlevel, col_actionorder)
      values(sys_guid(), rec2.SlaActionName, rec2.SlaActionProcCode, rec2.SlaEventId, 
             rec2.SlaEventLevel, rec2.SlaActionOrder) RETURNING col_id INTO v_SlaActionId;

      select gen_tbl_slaactioncc.currval into v_SlaActionId from dual;

      FOR rec3 IN (select arp.col_paramcode as ParamCode, col_paramvalue as ParamValue
                   from tbl_autoruleparamtmpl arp
                   inner join tbl_slaactiontmpl sa on arp.col_autorulepartpslaactiontp = sa.col_id
                   inner join tbl_slaeventtmpl se on sa.col_slaactiontpslaeventtp = se.col_id
                   inner join tbl_tasktemplate tt on se.col_slaeventtptasktemplate = tt.col_id
                   where tt.col_id = rec2.TaskTmplId and sa.col_id = rec2.SlaActionId)
      LOOP
        insert into tbl_autoruleparamcc(col_code, col_autoruleparccslaactioncc, col_paramcode, col_paramvalue)
        values(sys_guid(), v_SlaActionId, rec3.ParamCode, rec3.ParamValue);
      END LOOP;
    END LOOP;

   exception
     when DUP_VAL_ON_INDEX then
       return -1;
     when OTHERS then
       return -1;
  END;

  select gen_tbl_slaeventcc.currval into v_lastcounter from dual;
  

  FOR rec IN 
    (
     SELECT COL_ID  AS SEId, COL_SLAEVENTCC_DATEEVENTTYPE AS DateEventTypeId,
            COL_SLAEVENTCCTASKCC AS TaskId
     FROM TBL_SLAEVENTCC 
     WHERE COL_SLAEVENTCCTASKCC IN (SELECT COL_ID FROM TBL_TASKCC WHERE col_transactionid = v_TransactionId)
     )
  LOOP
    --DCM-5571 begin    
    v_SLAEVENTDATE          := NULL;
    v_STARTDATEEVENTBY      := NULL;
    v_STARTDATEEVENTVALUE   := NULL;
    v_FINISHDATEEVENTVALUE  := NULL;
    
      BEGIN 
        SELECT  MAX(des.COL_DATEVALUE) INTO v_STARTDATEEVENTVALUE
        FROM  TBL_DATEEVENTCC des
        WHERE des.COL_DATEEVENTCCTASKCC=rec.TaskId AND  
              des.COL_DATEEVENTCC_DATEEVENTTYPE=rec.DateEventTypeId;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN           
          v_STARTDATEEVENTVALUE   := NULL;
      END;

      BEGIN 
        SELECT  MAX(des.COL_DATEVALUE) INTO v_FINISHDATEEVENTVALUE
        FROM  TBL_DATEEVENTCC des
        WHERE des.COL_DATEEVENTCCTASKCC=rec.TaskId AND  
              des.COL_DATEEVENTCC_DATEEVENTTYPE=(SELECT COL_ID FROM TBL_DICT_DATEEVENTTYPE                                                  
                                                 WHERE COL_ISSLAEND = 1 AND COL_TYPE='TASK');

      EXCEPTION 
        WHEN NO_DATA_FOUND THEN           
          v_FINISHDATEEVENTVALUE   := NULL;
      END;
      
      IF v_STARTDATEEVENTVALUE IS NOT NULL THEN
        BEGIN 
          SELECT s.COL_PERFORMEDBY INTO v_STARTDATEEVENTBY
          FROM
              ( 
                SELECT ROWNUM AS RN, COL_PERFORMEDBY 
                FROM  TBL_DATEEVENTCC des
                WHERE des.COL_DATEEVENTCCTASKCC=rec.TaskId AND  
                      des.COL_DATEEVENTCC_DATEEVENTTYPE=rec.DateEventTypeId AND
                      des.COL_DATEVALUE=v_STARTDATEEVENTVALUE
            ) s
         WHERE s.RN=1;
        END;      
      END IF;

      UPDATE TBL_SLAEVENTCC se2
        SET COL_CODE = SYS_GUID(),
            COL_FINISHDATEEVENTVALUE  = v_FINISHDATEEVENTVALUE,
            COL_STARTDATEEVENTVALUE = v_STARTDATEEVENTVALUE, 
            COL_STARTDATEEVENTBY    = v_STARTDATEEVENTBY,
            COL_SLAEVENTDATE = v_STARTDATEEVENTVALUE + NVL(TO_DSINTERVAL(se2.COL_INTERVALDS),TO_DSINTERVAL('0 0' || ':' || '0' || ':' || '0')) + NVL(TO_YMINTERVAL(se2.COL_INTERVALYM),TO_YMINTERVAL('0-0'))
      WHERE  COL_ID = rec.SEId;
  END LOOP;
  --DCM-5571 end

END;
