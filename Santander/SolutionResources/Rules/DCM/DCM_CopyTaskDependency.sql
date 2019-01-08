DECLARE
  v_CaseId        NUMBER;
  v_createdby     NVARCHAR2(255);
  v_createddate   DATE;
  v_modifiedby    NVARCHAR2(255);
  v_modifieddate  DATE;
  v_owner         NVARCHAR2(255);
  v_taskDepId     NUMBER;  
  v_CSisInCache   INTEGER;

BEGIN

  v_CaseId := :CaseId;
  v_owner := :owner;
  v_createdby := v_owner;
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;

  ErrorCode := 0;
  ErrorMessage := null;

  v_CSisInCache := f_DCM_CSisCaseInCache(v_caseid);--new cache

    --case not in cache
  IF v_CSisInCache=0 THEN	
    begin        
        INSERT INTO TBL_TASKDEPENDENCY(COL_TSKDPNDCHLDTSKSTATEINIT,
                      COL_TSKDPNDPRNTTSKSTATEINIT,
                      COL_TYPE,
                      COL_PROCESSORCODE,
                      COL_TASKDEPENDENCYORDER,
                      COL_ISDEFAULT,
                      COL_CREATEDBY,
                      COL_CREATEDDATE,
                      COL_MODIFIEDBY,
                      COL_MODIFIEDDATE,
                      COL_OWNER,
                      COL_CODE)
         (select    tsic2.col_id,
                          tsip2.col_id,
                          td.col_type,
                          td.col_processorcode,
                          col_taskdependencyorder,
                          col_isdefault,
                          v_createdby,
                          v_createddate,
                          v_modifiedby,
                          v_modifieddate,
                          v_owner,
                          SYS_GUID()
                          --DESIGN
               from       tbl_taskdependencytmpl td
               inner join tbl_map_taskstateinittmpl tsic on td.col_taskdpchldtptaskstinittp = tsic.col_id
               inner join tbl_task tskc                  on tsic.col_map_taskstinittpltasktpl = tskc.col_id2
                          --RUNTIME
               inner join tbl_map_taskstateinitiation tsic2 on tskc.col_id = tsic2.col_map_taskstateinittask and tsic.col_map_tskstinittpl_tskst = tsic2.col_map_tskstinit_tskst
                          --DESIGN
               inner join tbl_map_taskstateinittmpl tsip on td.col_taskdpprnttptaskstinittp = tsip.col_id
               inner join tbl_task tskp                  on tsip.col_map_taskstinittpltasktpl = tskp.col_id2
                          --RUNTIME
               inner join tbl_map_taskstateinitiation tsip2 on tskp.col_id = tsip2.col_map_taskstateinittask and tsip.col_map_tskstinittpl_tskst = tsip2.col_map_tskstinit_tskst
               where      tskc.col_casetask = v_CaseId
                          and tskp.col_casetask = v_CaseId);       
    exception
    when DUP_VAL_ON_INDEX then
        :ErrorCode := 100;
        :ErrorMessage := 'DCM_CopyTaskDependency: ' || SUBSTR(SQLERRM,1,200);
        return -1;
    when OTHERS then
        :ErrorCode := 100;
        :ErrorMessage := 'DCM_CopyTaskDependency: ' || SUBSTR(SQLERRM,1,200);
        return -1;
    end;
  END IF;


    --case in cache
  IF v_CSisInCache=1 THEN    
    FOR rec IN
    (
     SELECT  tsic2.COL_ID AS Id, tsip2.COL_ID AS Id2, td.COL_TYPE, td.COL_PROCESSORCODE, 
             td.COL_TASKDEPENDENCYORDER, td.COL_ISDEFAULT
                --DESIGN
     FROM TBL_TASKDEPENDENCYTMPL td
     INNER JOIN TBL_MAP_TASKSTATEINITTMPL tsic on td.col_taskdpchldtptaskstinittp = tsic.col_id
     INNER JOIN TBL_CSTASK tskc on tsic.col_map_taskstinittpltasktpl = tskc.col_id2
                --RUNTIME
     INNER JOIN TBL_CSMAP_TASKSTATEINIT tsic2 on tskc.col_id = tsic2.col_map_taskstateinittask and tsic.col_map_tskstinittpl_tskst = tsic2.col_map_tskstinit_tskst
                --DESIGN
     INNER JOIN TBL_MAP_TASKSTATEINITTMPL tsip on td.col_taskdpprnttptaskstinittp = tsip.col_id
     INNER JOIN TBL_CSTASK tskp on tsip.col_map_taskstinittpltasktpl = tskp.col_id2
                --RUNTIME
     INNER JOIN TBL_CSMAP_TASKSTATEINIT tsip2 on tskp.col_id = tsip2.col_map_taskstateinittask and tsip.col_map_tskstinittpl_tskst = tsip2.col_map_tskstinit_tskst
     WHERE tskc.col_casetask = v_CaseId and tskp.col_casetask = v_CaseId
    )
    LOOP
      SELECT GEN_TBL_TASKDEPENDENCY.NEXTVAL INTO v_taskDepId FROM dual;

      INSERT INTO TBL_CSTASKDEPENDENCY(COL_ID, COL_TSKDPNDCHLDTSKSTATEINIT, COL_TSKDPNDPRNTTSKSTATEINIT,
                                       COL_TYPE, COL_PROCESSORCODE, COL_TASKDEPENDENCYORDER,
                                       COL_ISDEFAULT, COL_CREATEDBY, COL_CREATEDDATE, COL_MODIFIEDBY,
                                       COL_MODIFIEDDATE, COL_OWNER, COL_CODE)
       VALUES(v_taskDepId, rec.id, rec.id2, rec.col_type, rec.col_processorcode,
              rec.col_taskdependencyorder, rec.col_isdefault, v_createdby, v_createddate,
             v_modifiedby, v_modifieddate, v_owner, SYS_GUID()); 
    END LOOP;
  END IF;

END;