DECLARE
  v_CaseId        NUMBER; 
  v_createdby     NVARCHAR2(255);
  v_createddate   DATE;
  v_modifiedby    NVARCHAR2(255);
  v_modifieddate  DATE;
  v_owner         NVARCHAR2(255);
  v_tsinitId      NUMBER;  
  v_CSisInCache   INTEGER;

BEGIN

  v_CaseId    := :CaseId;
  v_owner     := :owner;
  
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;

  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache

  ErrorCode := 0;
  ErrorMessage := null;

  --case not in new cache 
  IF v_CSisInCache=0 THEN	   
    begin
     insert into tbl_map_taskstateinitiation(col_code, col_map_taskstateinittask,col_processorcode,col_assignprocessorcode,col_map_tskstinit_initmtd,col_map_tskstinit_tskst,
                                            col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
     (select sys_guid(), tsk.col_id, col_processorcode, col_assignprocessorcode, col_map_tskstinittpl_initmtd, col_map_tskstinittpl_tskst, v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
      from tbl_map_taskstateinittmpl tsi
      inner join tbl_task tsk on tsi.col_map_taskstinittpltasktpl = tsk.col_id2
     where tsk.col_casetask = v_CaseId);
     exception
       when DUP_VAL_ON_INDEX then
         ErrorCode := 100;
         ErrorMessage := 'DCM_CopyTaskStateInit: ' || SUBSTR(SQLERRM, 1, 200);
         return -1;
       when OTHERS then
         ErrorCode := 100;
         ErrorMessage := 'DCM_CopyTaskStateInit: ' || SUBSTR(SQLERRM, 1, 200);
         return -1;
    end;
  END IF;


  --case in new cache 
  IF v_CSisInCache=1 THEN	 
    FOR rec IN
    (
      SELECT tsk.COL_ID, tsi.COL_PROCESSORCODE, tsi.COL_ASSIGNPROCESSORCODE, tsi.COL_MAP_TSKSTINITTPL_INITMTD, 
             tsi.COL_MAP_TSKSTINITTPL_TSKST
      FROM TBL_MAP_TASKSTATEINITTMPL tsi
      INNER JOIN TBL_CSTASK tsk on tsi.col_map_taskstinittpltasktpl = tsk.col_id2
      WHERE tsk.col_casetask = v_CaseId
    )
    LOOP
      SELECT gen_tbl_map_taskstateinitiat.NEXTVAL INTO v_tsinitId FROM dual;
      INSERT INTO TBL_CSMAP_TASKSTATEINIT(COL_ID, COL_CODE, COL_MAP_TASKSTATEINITTASK, COL_PROCESSORCODE, 
                                         COL_ASSIGNPROCESSORCODE, COL_MAP_TSKSTINIT_INITMTD, COL_MAP_TSKSTINIT_TSKST,
                                         COL_CREATEDBY, COL_CREATEDDATE,COL_MODIFIEDBY,COL_MODIFIEDDATE,COL_OWNER)
      VALUES(v_tsinitId, SYS_GUID(), rec.col_id, rec.COL_PROCESSORCODE, rec.COL_ASSIGNPROCESSORCODE, 
             rec.COL_MAP_TSKSTINITTPL_INITMTD, rec.COL_MAP_TSKSTINITTPL_TSKST, 
             v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner);
    END LOOP;
  END IF;

END;