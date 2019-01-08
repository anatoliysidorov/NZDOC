DECLARE
  v_CaseId                    INTEGER;
  v_SlaEventId                INTEGER;
  v_SlaActionId               INTEGER;
  v_arpId                     NUMBER;  
  v_SLAEVENTDATE              DATE;
  v_STARTDATEEVENTBY          NVARCHAR2(255);
  v_STARTDATEEVENTVALUE       DATE;
  v_FINISHDATEEVENTVALUE      DATE;
  v_CSisInCache               INTEGER;

BEGIN
  v_CaseId := :CaseId;
  :ErrorCode := 0;
  :ErrorMessage := null;
  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache

  BEGIN

  --case not in cache
  IF v_CSisInCache=0 THEN
    for rec in
      (select se.col_id as SlaEventId, tsk.col_id as TaskId, tsk.col_id2 as TaskTmplId, se.col_slaeventtp_slaeventtype as SlaEventType, se.col_slaeventtp_dateeventtype as DateEventType,
         se.col_intervalds as SlaEventIntervalDS, se.col_intervalym as SlaEventIntervalYM, se.col_slaeventtp_slaeventlevel as SlaEventLevel,
         se.col_maxattempts as MaxAttempts, se.col_attemptcount as AttemptCount, se.col_slaeventorder as SlaEventOrder
         from tbl_slaeventtmpl se
           inner join tbl_task tsk on se.col_slaeventtptasktemplate = tsk.col_id2
           where tsk.col_casetask = v_CaseId)
    LOOP
  
      --DCM-5571 begin    
      v_SLAEVENTDATE          := NULL;
      v_STARTDATEEVENTBY      := NULL;
      v_STARTDATEEVENTVALUE   := NULL;
      v_FINISHDATEEVENTVALUE  := NULL;
  
      BEGIN 
        SELECT  MAX(des.COL_DATEVALUE) INTO v_STARTDATEEVENTVALUE
        FROM  TBL_DATEEVENT des
        WHERE des.COL_DATEEVENTTASK=rec.TaskId AND  des.COL_DATEEVENT_DATEEVENTTYPE=rec.DateEventType;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN         
          v_STARTDATEEVENTVALUE   := NULL;
      END;
  
     BEGIN
        SELECT  MAX(des.COL_DATEVALUE) INTO v_FINISHDATEEVENTVALUE
        FROM  TBL_DATEEVENT des
        WHERE (des.COL_DATEEVENTTASK=rec.TaskId) AND  
              (des.COL_DATEEVENT_DATEEVENTTYPE=(SELECT COL_ID FROM TBL_DICT_DATEEVENTTYPE 
                                                WHERE COL_ISSLAEND = 1 AND LOWER(COL_TYPE)='task'));
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
                FROM  TBL_DATEEVENT des
                WHERE des.COL_DATEEVENTTASK=rec.TaskId AND  
                      des.COL_DATEEVENT_DATEEVENTTYPE=rec.DateEventType AND
                      des.COL_DATEVALUE=v_STARTDATEEVENTVALUE
            ) s
         WHERE s.RN=1;
        END;      
      END IF;    
  
      INSERT INTO TBL_SLAEVENT(COL_CODE, COL_SLAEVENTTASK, COL_SLAEVENTDICT_SLAEVENTTYPE, COL_SLAEVENT_DATEEVENTTYPE, 
                               COL_INTERVALDS, COL_INTERVALYM, COL_SLAEVENT_SLAEVENTLEVEL, COL_MAXATTEMPTS, 
                               COL_ATTEMPTCOUNT, COL_SLAEVENTORDER, COL_STARTDATEEVENTVALUE, 
                               COL_STARTDATEEVENTBY, COL_FINISHDATEEVENTVALUE)
      VALUES(SYS_GUID(), rec.TaskId, rec.SlaEventType, rec.DateEventType, rec.SlaEventIntervalDS, 
             rec.SlaEventIntervalYM, rec.SlaEventLevel, rec.MaxAttempts, rec.AttemptCount, rec.SlaEventOrder,
             v_STARTDATEEVENTVALUE, v_STARTDATEEVENTBY, v_FINISHDATEEVENTVALUE);
  
      select gen_tbl_slaevent.currval into v_SlaEventId from dual;
  
      UPDATE TBL_SLAEVENT se2
      SET  COL_SLAEVENTDATE = se2.COL_STARTDATEEVENTVALUE + NVL(TO_DSINTERVAL(se2.COL_INTERVALDS),TO_DSINTERVAL('0 0' || ':' || '0' || ':' || '0')) + NVL(TO_YMINTERVAL(se2.COL_INTERVALYM),TO_YMINTERVAL('0-0'))
      WHERE COL_ID=v_SlaEventId;
      --DCM-5571 end
  
      for rec2 in (select sa.col_id as SlaActionId, sa.col_code as SlaActionCode, sa.col_name as SlaActionName, sa.col_processorcode as SlaActionProcCode, sa.col_slaactiontp_slaeventlevel as SlaEventLevel,
                   sa.col_actionorder as SlaActionOrder
                   from tbl_slaactiontmpl sa
                   inner join tbl_slaeventtmpl se on sa.col_slaactiontpslaeventtp = se.col_id
                   inner join tbl_task tsk on se.col_slaeventtptasktemplate = tsk.col_id2
                   where se.col_id = rec.SlaEventId and tsk.col_casetask = v_CaseId
                   order by sa.col_actionorder)
      loop
        insert into tbl_slaaction(col_code, col_name, col_processorcode, col_slaactionslaevent, col_slaaction_slaeventlevel, col_actionorder)
        values(sys_guid(), rec2.SlaActionName, rec2.SlaActionProcCode, v_SlaEventId, rec2.SlaEventLevel, rec2.SlaActionOrder);

        select gen_tbl_slaaction.currval into v_SlaActionId from dual;

        for rec3 in (select arp.col_paramcode as ParamCode, col_paramvalue as ParamValue
                     from tbl_autoruleparamtmpl arp
                     inner join tbl_slaactiontmpl sa on arp.col_autorulepartpslaactiontp = sa.col_id
                     inner join tbl_slaeventtmpl se on sa.col_slaactiontpslaeventtp = se.col_id
                     inner join tbl_tasktemplate tt on se.col_slaeventtptasktemplate = tt.col_id
                     where tt.col_id = rec.TaskTmplId and sa.col_id = rec2.SlaActionId)
        loop
          insert into tbl_autoruleparameter(col_autoruleparamslaaction, col_paramcode, col_paramvalue, col_code)
          values(v_SlaActionId, rec3.ParamCode, rec3.ParamValue, SYS_GUID());  
        end loop;

      end loop;
    end loop;
  END IF; 


  --case in cache
  IF v_CSisInCache=1 THEN
    for rec in
      (select se.col_id as SlaEventId, tsk.col_id as TaskId, tsk.col_id2 as TaskTmplId, se.col_slaeventtp_slaeventtype as SlaEventType, se.col_slaeventtp_dateeventtype as DateEventType,
       se.col_intervalds as SlaEventIntervalDS, se.col_intervalym as SlaEventIntervalYM, se.col_slaeventtp_slaeventlevel as SlaEventLevel,
       se.col_maxattempts as MaxAttempts, se.col_attemptcount as AttemptCount, se.col_slaeventorder as SlaEventOrder
       FROM TBL_SLAEVENTTMPL se
       INNER JOIN TBL_CSTASK tsk on se.col_slaeventtptasktemplate = tsk.col_id2
       where tsk.col_casetask = v_CaseId)
    LOOP
  
      --DCM-5571 begin    
      v_SLAEVENTDATE          := NULL;
      v_STARTDATEEVENTBY      := NULL;
      v_STARTDATEEVENTVALUE   := NULL;
      v_FINISHDATEEVENTVALUE  := NULL;
  
      BEGIN 
        SELECT  MAX(des.COL_DATEVALUE) INTO v_STARTDATEEVENTVALUE
        FROM  TBL_CSDATEEVENT des
        WHERE des.COL_DATEEVENTTASK=rec.TaskId AND  des.COL_DATEEVENT_DATEEVENTTYPE=rec.DateEventType;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN         
          v_STARTDATEEVENTVALUE   := NULL;
      END;
  
     BEGIN
        SELECT  MAX(des.COL_DATEVALUE) INTO v_FINISHDATEEVENTVALUE
        FROM  TBL_CSDATEEVENT des
        WHERE (des.COL_DATEEVENTTASK=rec.TaskId) AND  
              (des.COL_DATEEVENT_DATEEVENTTYPE=(SELECT COL_ID FROM TBL_DICT_DATEEVENTTYPE 
                                                WHERE COL_ISSLAEND = 1 AND LOWER(COL_TYPE)='task'));
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
                FROM  TBL_CSDATEEVENT des
                WHERE des.COL_DATEEVENTTASK=rec.TaskId AND  
                      des.COL_DATEEVENT_DATEEVENTTYPE=rec.DateEventType AND
                      des.COL_DATEVALUE=v_STARTDATEEVENTVALUE
            ) s
         WHERE s.RN=1;
        END;      
      END IF;    

      SELECT gen_tbl_slaevent.NEXTVAL INTO v_SlaEventId FROM dual;
  
      INSERT INTO TBL_CSSLAEVENT(COL_ID, COL_CODE, COL_SLAEVENTTASK, COL_SLAEVENTDICT_SLAEVENTTYPE, COL_SLAEVENT_DATEEVENTTYPE, 
                                 COL_INTERVALDS, COL_INTERVALYM, COL_SLAEVENT_SLAEVENTLEVEL, COL_MAXATTEMPTS, 
                                 COL_ATTEMPTCOUNT, COL_SLAEVENTORDER, COL_STARTDATEEVENTVALUE, 
                                 COL_STARTDATEEVENTBY, COL_FINISHDATEEVENTVALUE, COL_SLAEVENTDATE)
      VALUES(v_SlaEventId, SYS_GUID(), rec.TaskId, rec.SlaEventType, rec.DateEventType, rec.SlaEventIntervalDS, 
             rec.SlaEventIntervalYM, rec.SlaEventLevel, rec.MaxAttempts, rec.AttemptCount, rec.SlaEventOrder,
             v_STARTDATEEVENTVALUE, v_STARTDATEEVENTBY, v_FINISHDATEEVENTVALUE,
             v_STARTDATEEVENTVALUE + 
             NVL(TO_DSINTERVAL(rec.SlaEventIntervalDS),TO_DSINTERVAL('0 0' || ':' || '0' || ':' || '0')) + 
             NVL(TO_YMINTERVAL(rec.SlaEventIntervalYM),TO_YMINTERVAL('0-0'))
             );        
      --DCM-5571 end
  
      FOR rec2 IN 
        (SELECT sa.col_id as SlaActionId, sa.col_code as SlaActionCode, sa.col_name as SlaActionName, 
                sa.col_processorcode as SlaActionProcCode, sa.col_slaactiontp_slaeventlevel as SlaEventLevel,
                sa.col_actionorder as SlaActionOrder
         FROM TBL_SLAACTIONTMPL sa
         INNER JOIN TBL_SLAEVENTTMPL se on sa.col_slaactiontpslaeventtp = se.col_id
         INNER JOIN TBL_CSTASK tsk on se.col_slaeventtptasktemplate = tsk.col_id2
         WHERE se.col_id = rec.SlaEventId and tsk.col_casetask = v_CaseId
         ORDER BY sa.col_actionorder)

      LOOP
        SELECT gen_tbl_slaaction.NEXTVAL INTO v_SlaActionId FROM dual;
        INSERT INTO TBL_CSSLAACTION(COL_ID, COL_CODE, COL_NAME, COL_PROCESSORCODE, COL_SLAACTIONSLAEVENT, 
                                    COL_SLAACTION_SLAEVENTLEVEL, COL_ACTIONORDER)
        VALUES(v_SlaActionId, SYS_GUID(), rec2.SlaActionName, rec2.SlaActionProcCode, v_SlaEventId, 
               rec2.SlaEventLevel, rec2.SlaActionOrder);
        
        FOR rec3 IN 
          (SELECT arp.col_paramcode as ParamCode, col_paramvalue as ParamValue
           FROM TBL_AUTORULEPARAMTMPL arp
           INNER JOIN TBL_SLAACTIONTMPL sa on arp.col_autorulepartpslaactiontp = sa.col_id
           INNER JOIN TBL_SLAEVENTTMPL se on sa.col_slaactiontpslaeventtp = se.col_id
           INNER JOIN TBL_TASKTEMPLATE tt on se.col_slaeventtptasktemplate = tt.col_id
           WHERE tt.col_id = rec.TaskTmplId and sa.col_id = rec2.SlaActionId)

        LOOP
          SELECT gen_tbl_autoruleparameter.NEXTVAL INTO v_arpId FROM dual;
          INSERT INTO TBL_CSAUTORULEPARAMETER(COL_ID, COL_CODE, COL_AUTORULEPARAMSLAACTION, 
                                              COL_PARAMCODE, COL_PARAMVALUE)
          VALUES(v_arpId, SYS_GUID(), v_SlaActionId, rec3.ParamCode, rec3.ParamValue);                        
        END LOOP;
      END LOOP;
    END LOOP;
  END IF; 

  exception 
    when OTHERS then
     :ErrorCode := 100;
     :ErrorMessage := 'DCM_copySlaEvent: ' || SUBSTR(SQLERRM, 1, 200);
  end;
END;