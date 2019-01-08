declare
  v_CaseId        NUMBER;
  v_createdby     NVARCHAR2(255);
  v_createddate   DATE;
  v_modifiedby    NVARCHAR2(255);
  v_modifieddate  DATE;
  v_owner         NVARCHAR2(255);   
  v_evtId         NUMBER;
  v_CSisInCache   INTEGER;

BEGIN

  v_CaseId := :CaseId;
  v_owner := :owner;

  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;

  :ErrorCode := 0;
  :ErrorMessage := null;

  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache

  --case not in new cache 
  IF v_CSisInCache=0 THEN	 
    begin    	    
      insert into tbl_taskevent(col_processorcode,col_taskeventtaskstateinit,col_taskeventmomenttaskevent,col_taskeventtypetaskevent,col_taskeventorder,
                                col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner, col_code)
      (select te.col_processorcode,tsi2.col_id,te.col_taskeventmomnttaskeventtp,te.col_taskeventtypetaskeventtp,te.col_taskeventorder,
              v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner, sys_guid()
        from tbl_taskeventtmpl te
       --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinittmpl tsi on te.col_taskeventtptaskstinittp = tsi.col_id
        inner join tbl_task tsk on tsi.col_map_taskstinittpltasktpl = tsk.col_id2
        --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
        inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinittpl_tskst = tsi2.col_map_tskstinit_tskst
        where tsk.col_casetask = v_CaseId);                
          
        exception
          when DUP_VAL_ON_INDEX then
            :ErrorCode := 100;
            :ErrorMessage := 'DCM_CopyTaskEvent: ' || SUBSTR(SQLERRM, 1, 200);
            return -1;
          when OTHERS then
            :ErrorCode := 100;
            :ErrorMessage := 'DCM_CopyTaskEvent: ' || SUBSTR(SQLERRM, 1, 200);
            return -1;
    end;
  END IF;


  --case in new cache 
  IF v_CSisInCache=1 THEN	 
    
    FOR rec IN
    (
     SELECT te.COL_PROCESSORCODE, tsi2.COL_ID, te.COL_TASKEVENTMOMNTTASKEVENTTP, 
            te.COL_TASKEVENTTYPETASKEVENTTP, te.COL_TASKEVENTORDER
    FROM TBL_TASKEVENTTMPL te
    --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
    INNER JOIN TBL_MAP_TASKSTATEINITTMPL tsi on te.col_taskeventtptaskstinittp = tsi.col_id
    INNER JOIN TBL_CSTASK tsk on tsi.col_map_taskstinittpltasktpl = tsk.col_id2
    --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
    INNER JOIN TBL_CSMAP_TASKSTATEINIT tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinittpl_tskst = tsi2.col_map_tskstinit_tskst
    WHERE tsk.col_casetask = v_CaseId)
    LOOP

    	SELECT GEN_TBL_TASKEVENT.NEXTVAL INTO v_evtId FROM dual;
    
      INSERT INTO TBL_CSTASKEVENT(COL_ID, COL_PROCESSORCODE,COL_TASKEVENTTASKSTATEINIT,COL_TASKEVENTMOMENTTASKEVENT,COL_TASKEVENTTYPETASKEVENT,COL_TASKEVENTORDER,
                                  COL_CREATEDBY,COL_CREATEDDATE,COL_MODIFIEDBY,COL_MODIFIEDDATE,COL_OWNER, COL_CODE)
      VALUES(v_evtId, rec.col_processorcode, rec.col_id, rec.col_taskeventmomnttaskeventtp, 
             rec.col_taskeventtypetaskeventtp, rec.col_taskeventorder,
              v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner, SYS_GUID());
    END LOOP;           
  END IF;

end;