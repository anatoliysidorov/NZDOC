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
    
    select gen_tbl_slaevent.nextval into v_counter from dual;
    
    begin
        insert into tbl_slaevent(col_slaeventtask, col_slaeventdict_slaeventtype, col_slaevent_dateeventtype, col_intervalds, col_intervalym, col_slaevent_slaeventlevel, col_maxattempts, col_attemptcount, col_slaeventorder)
          (select    tsk.col_id, se.col_slaeventtp_slaeventtype, se.col_slaeventtp_dateeventtype, se.col_intervalds, se.col_intervalym,  se.COL_SLAEVENTTP_SLAEVENTLEVEL, se.col_maxattempts, se.col_attemptcount, se.col_slaeventorder
               from       tbl_slaeventtmpl se
               inner join tbl_task         tsk on se.col_slaeventtptasktemplate = tsk.col_id2
               where      tsk.col_transactionid = v_TransactionId);
        
        select gen_tbl_slaevent.currval into v_lastcounter from   dual;
        
        for rec2 in(select tsk.col_id2 as TaskTmplId, se2.col_id as SlaEventId, sa.col_id as SlaActionId, sa.col_code as SlaActionCode, sa.col_name as SlaActionName, sa.col_processorcode as SlaActionProcCode, sa.col_SLAActionTp_SLAEventLevel as SlaEventLevel,
                   sa.col_actionorder as SlaActionOrder
                   from TBL_SLAACTIONTMPL sa
                   inner join tbl_slaeventtmpl se on sa.col_SLAActionTpSLAEventTp = se.col_id
                   inner join tbl_task tsk on se.COL_SLAEventTpTaskTemplate = tsk.col_id2
                   inner join tbl_slaevent se2 on tsk.col_id = se2.COL_SLAEventTask and se.col_slaeventorder = se2.col_slaeventorder
                   where se.col_id in (select se.col_id from tbl_slaeventtmpl se
                                               inner join tbl_task tsk on se.COL_SLAEventTpTaskTemplate = tsk.col_id2
                                               where tsk.col_transactionid = v_TransactionId)
                                               and tsk.col_transactionid = v_TransactionId
                  order by   sa.col_actionorder)
        loop
            insert into tbl_slaaction(col_code, col_name, col_processorcode, col_slaactionslaevent, col_slaaction_slaeventlevel, col_actionorder)
                   values(sys_guid(), rec2.SlaActionName, rec2.SlaActionProcCode,  rec2.SlaEventId,  rec2.SlaEventLevel, rec2.SlaActionOrder) RETURNING COL_ID INTO v_SlaActionId;
            for rec3 in (select arp.col_paramcode as ParamCode, col_paramvalue as ParamValue
                             from tbl_AutoRuleParamTmpl arp
                             inner join TBL_SLAACTIONTMPL sa on arp.col_AutoRuleParTpSLAActionTp = sa.col_id
                             inner join tbl_slaeventtmpl se on sa.col_SLAActionTpSLAEventTp = se.col_id
                             inner join tbl_tasktemplate tt on se.COL_SLAEventTpTaskTemplate = tt.col_id
                             where tt.col_id = rec2.TaskTmplId
                             and sa.col_id = rec2.SlaActionId)
            loop
                insert into tbl_AutoRuleParameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
                       values(sys_guid(), v_SlaActionId, rec3.ParamCode, rec3.ParamValue);
            end loop;
        end loop;
    exception
    when DUP_VAL_ON_INDEX then
        return -1;
    when OTHERS then
        return -1;
    end;

    select gen_tbl_slaevent.currval into v_lastcounter from   dual;

    for rec IN
      (SELECT COL_ID, COL_SLAEVENTTASK, COL_SLAEVENT_DATEEVENTTYPE 
       FROM TBL_SLAEVENT 
       WHERE COL_ID BETWEEN v_counter AND v_lastcounter)
    LOOP
      --DCM-5571 begin    
      v_SLAEVENTDATE          := NULL;
      v_STARTDATEEVENTBY      := NULL;
      v_STARTDATEEVENTVALUE   := NULL;
      v_FINISHDATEEVENTVALUE  := NULL; 

      BEGIN 
        SELECT  MAX(des.COL_DATEVALUE) INTO v_STARTDATEEVENTVALUE
        FROM  TBL_DATEEVENT des
        WHERE des.COL_DATEEVENTTASK=rec.COL_SLAEVENTTASK AND  
              des.COL_DATEEVENT_DATEEVENTTYPE=rec.COL_SLAEVENT_DATEEVENTTYPE;
      EXCEPTION 
        WHEN NO_DATA_FOUND THEN           
          v_STARTDATEEVENTVALUE   := NULL;
      END;

      BEGIN 
        SELECT  MAX(des.COL_DATEVALUE) INTO v_FINISHDATEEVENTVALUE
        FROM  TBL_DATEEVENT des
        WHERE (des.COL_DATEEVENTTASK=rec.COL_SLAEVENTTASK) AND                
              (des.COL_DATEEVENT_DATEEVENTTYPE=(SELECT COL_ID FROM TBL_DICT_DATEEVENTTYPE 
                                                WHERE COL_ISSLAEND = 1 AND COL_TYPE='TASK'));
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
                WHERE des.COL_DATEEVENTTASK=rec.COL_SLAEVENTTASK AND  
                      des.COL_DATEEVENT_DATEEVENTTYPE=rec.COL_SLAEVENT_DATEEVENTTYPE AND
                      des.COL_DATEVALUE=v_STARTDATEEVENTVALUE
            ) s
         WHERE s.RN=1;
        END;      
      END IF;


      UPDATE TBL_SLAEVENT se2
        SET COL_CODE = SYS_GUID(),
            COL_FINISHDATEEVENTVALUE  = v_FINISHDATEEVENTVALUE,
            COL_STARTDATEEVENTVALUE = v_STARTDATEEVENTVALUE, 
            COL_STARTDATEEVENTBY    = v_STARTDATEEVENTBY,
            COL_SLAEVENTDATE = v_STARTDATEEVENTVALUE + NVL(TO_DSINTERVAL(se2.COL_INTERVALDS),TO_DSINTERVAL('0 0' || ':' || '0' || ':' || '0')) + NVL(TO_YMINTERVAL(se2.COL_INTERVALYM),TO_YMINTERVAL('0-0'))
      WHERE  COL_ID = rec.COL_ID;
    END LOOP;
    --DCM-5571 end
END;
