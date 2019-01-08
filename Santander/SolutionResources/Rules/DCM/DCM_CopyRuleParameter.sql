declare
  v_CaseId        NUMBER;
  v_createdby     NVARCHAR2(255);
  v_createddate   DATE;
  v_modifiedby    NVARCHAR2(255);
  v_modifieddate  DATE;
  v_owner         NVARCHAR2(255);  
  v_arpId         NUMBER;
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
      insert into tbl_autoruleparameter(COL_CODE, col_ruleparam_taskstateinit,col_taskeventautoruleparam,col_paramcode,col_paramvalue,col_ttautoruleparameter,col_autoruleparametertask,
                                        col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
      (select sys_guid(), s1.RTTaskStateInitId, s1.RTTaskEventId, s1.RuleParamCode, s1.RuleParamValue, s1.RuleParamTaskTmplId, s1.RTTaskId,
              v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
        from
        (
        --SELECT AUTORULEPARAMETER RECORDS FOR COPYING FROM DESIGN TIME TO RUNTIME
        --SELECT ALL RULE PARAMETERS RELATED TO TASK STATE INITIATION
        select tsi.col_id as DTTaskStateInitId, tsi.col_processorcode as TaskStateInitProcessorCode, tsi.col_map_taskstateinittptaskcc as TaskStateInitTaskId,
               tsi.col_map_tskstinittpl_initmtd as TaskStateInitMethodId, tsi.col_map_tskstinittpl_tskst as TaskStateInitStateId,
               tsi.col_map_taskstinittpltasktpl as TaskTmplId,
               tsi2.col_id as RTTaskStateInitId, tsi2.col_map_taskstateinittask as TaskId, null as RTTaskId,
               arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_rulepartp_taskstateinittp as RuleParamTaskStateInitId, arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId, arp.col_tasktemplateautorulepartp as RuleParamTaskTmplId,
               null as TaskEventId, null as TaskEventProcessorCode,
               null as RTTaskEventId, null as RTTaskEventProcCode
          from tbl_autoruleparamtmpl arp
          --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
          inner join tbl_map_taskstateinittmpl tsi on arp.col_rulepartp_taskstateinittp = tsi.col_id
          inner join tbl_task tsk on tsi.col_map_taskstinittpltasktpl = tsk.col_id2
          --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
          inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinittpl_tskst = tsi2.col_map_tskstinit_tskst
          where arp.col_taskeventtpautoruleparmtp is null and tsk.col_casetask = v_CaseId
        union
        --SELECT ALL RULEPARAMETERS FOR EVENTS, RELATED TO TASK STATE INITIATION EVENTS
        select tsi.col_id as DTTaskStateInitId, tsi.col_processorCode as TaskStateInitProcessorCode, tsi.col_map_taskstateinittptaskcc as TaskStateInitTaskId,
               tsi.col_map_tskstinittpl_initmtd as TaskStateInitMethodId, tsi.col_map_tskstinittpl_tskst as TaskStateInitStateId,
               tsi.col_map_taskstinittpltasktpl as TaskTmplId,
               null as RTTaskStateInitId, tsi2.col_map_taskstateinittask as TaskId, null as RTTaskId,
               arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_rulepartp_taskstateinittp as RuleParamTaskStateInitId, arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId, arp.col_tasktemplateautorulepartp as RuleParamTaskTmplId,
               te.col_id as TaskEventId, te.col_processorcode as TaskEventProcessorCode,
               te2.col_id as RTTaskEventId, te2.col_processorcode as RTTaskEventProcCode
          from tbl_autoruleparamtmpl arp
          inner join tbl_taskeventtmpl te on arp.col_taskeventtpautoruleparmtp = te.col_id
          --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
          inner join tbl_map_taskstateinittmpl tsi on te.col_taskeventtptaskstinittp = tsi.col_id
          inner join tbl_task tsk on tsi.col_map_taskstinittpltasktpl = tsk.col_id2
          --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
          inner join tbl_map_taskstateinitiation tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinittpl_tskst = tsi2.col_map_tskstinit_tskst
          inner join tbl_taskevent te2 on tsi2.col_id = te2.col_taskeventtaskstateinit and te.col_taskeventorder = te2.col_taskeventorder
          where tsk.col_casetask = v_CaseId
        union
        --SELECT ALL RULEPARAMETERS FOR AUTOMATIC TASKS
        select null as DTTaskStateInitId, cast(tsk.col_processorName as nvarchar2(255)) as TaskStateInitProcessorCode, null as TaskStateInitTaskId,
               null as TaskStateInitMethodId, null as TaskStateInitStateId,
               tskt.col_Id as TaskTmplId,
               null as RTTaskStateInitId, tsk.col_id as TaskId, tsk.col_id as RTTaskId,
               arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_rulepartp_taskstateinittp as RuleParamTaskStateInitId, arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId, null as RuleParamTaskTmplId,
               null as TaskEventId, null as TaskEventProcessorCode,
               null as RTTaskEventId, null as RTTaskEventProcCode
          from tbl_autoruleparamtmpl arp
            inner join tbl_tasktemplate tskt on arp.col_tasktemplateautorulepartp = tskt.col_id
            inner join tbl_task tsk on tskt.col_id = tsk.col_id2
            where tsk.col_casetask = v_CaseId
        )s1);
        exception
         when DUP_VAL_ON_INDEX then
           :ErrorCode := 100;
           :ErrorMessage := 'DCM_CopyRuleParameter: ' || SUBSTR(SQLERRM, 1, 200);
           return -1;
         when OTHERS then
           :ErrorCode := 100;
           :ErrorMessage := 'DCM_CopyRuleParameter: ' || SUBSTR(SQLERRM, 1, 200);
           return -1;
    end;
  
    begin
      insert into tbl_autoruleparameter(COL_CODE, col_autoruleparamtaskdep, col_paramcode,col_paramvalue,
                                        col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
       select sys_guid(), s1.RTTaskDependencyId, s1.RuleParamCode, s1.RuleParamValue,
                                        v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
       from
       (select td.col_id as DTTaskDependencyId, td2.col_id as RTTaskDependencyId,
               ctsi.col_id as CDTTaskStateInitId, ctsi.col_processorcode as CTaskStateInitProcessorCode, ctsi.col_map_taskstateinittptaskcc as CTaskStateInitTaskId,
               ctsi.col_map_tskstinittpl_initmtd as CTaskStateInitMethodId, ctsi.col_map_tskstinittpl_tskst as CTaskStateInitStateId,
               ctsi.col_map_taskstinittpltasktpl as CTaskTmplId,
               ctsi2.col_id as CRTTaskStateInitId, ctsi2.col_map_taskstateinittask as CTaskId,
               ptsi.col_id as PDTTaskStateInitId, ptsi.col_processorcode as PTaskStateInitProcessorCode, ptsi.col_map_taskstateinittptaskcc as PTaskStateInitTaskId,
               ptsi.col_map_tskstinittpl_initmtd as PTaskStateInitMethodId, ptsi.col_map_tskstinittpl_tskst as PTaskStateInitStateId,
               ptsi.col_map_taskstinittpltasktpl as PTaskTmplId,
               ptsi2.col_id as PRTTaskStateInitId, ptsi2.col_map_taskstateinittask as PTaskId,
               arp.col_id as ARPId, arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_rulepartp_taskstateinittp as RuleParamTaskStateInitId, arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId,
               arp.col_tasktemplateautorulepartp as RuleParamTaskTmplId
        from tbl_autoruleparamtmpl arp
        inner join tbl_taskdependencytmpl td on arp.col_autoruleparamtptaskdeptp = td.col_id
        inner join tbl_map_taskstateinittmpl ctsi on td.col_taskdpchldtptaskstinittp = ctsi.col_id
        inner join tbl_task ctsk on ctsi.col_map_taskstinittpltasktpl = ctsk.col_id2
        inner join tbl_map_taskstateinittmpl ptsi on td.col_taskdpprnttptaskstinittp = ptsi.col_id
        inner join tbl_task ptsk on ptsi.col_map_taskstinittpltasktpl = ptsk.col_id2
        --RUNTIME
        inner join tbl_map_taskstateinitiation ctsi2 on ctsk.col_id = ctsi2.col_map_taskstateinittask and ctsi.col_map_tskstinittpl_tskst = ctsi2.col_map_tskstinit_tskst
        inner join tbl_map_taskstateinitiation ptsi2 on ptsk.col_id = ptsi2.col_map_taskstateinittask and ptsi.col_map_tskstinittpl_tskst = ptsi2.col_map_tskstinit_tskst
        inner join tbl_taskdependency td2 on ctsi2.col_id = td2.col_tskdpndchldtskstateinit and ptsi2.col_id = td2.col_tskdpndprnttskstateinit
        where ctsk.col_casetask = v_CaseId and ptsk.col_casetask = v_CaseId) s1;
        exception
         when DUP_VAL_ON_INDEX then
           :ErrorCode := 100;
           :ErrorMessage := 'DCM_CopyRuleParameter: ' || SUBSTR(SQLERRM, 1, 200);
           return -1;
         when OTHERS then
           :ErrorCode := 100;
           :ErrorMessage := 'DCM_CopyRuleParameter: ' || SUBSTR(SQLERRM, 1, 200);
           return -1;
    end;
  
    begin
      insert into tbl_autoruleparameter(col_CODE, col_ruleparam_casestateinit, col_caseeventautoruleparam, col_paramcode, col_paramvalue,
                                        col_createdby,col_createddate,col_modifiedby,col_modifieddate,col_owner)
       select sys_guid(), s1.RTCaseStateInitId, s1.RTCaseEventId, s1.RuleParamCode, s1.RuleParamValue,
              v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
       from
       (select csi.col_id as DTCaseStateInitId, csi.col_processorcode as CaseStateInitProcessorCode, csi.col_map_casestateinittpcasecc as CaseStateInitCaseId,
               csi.col_casestateinittp_initmtd as CaseStateInitMethodId, csi.col_map_csstinittp_csst as CaseStateInitStateId,
               csi.col_casestateinittp_casetype as CaseSysTypeId,
               csi2.col_id as RTCaseStateInitId, csi2.col_map_casestateinitcase as CaseId, null as RTCaseId,
               arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_rulepartp_taskstateinittp as RuleParamCaseStateInitId, arp.col_caseeventtpautorulepartp as RuleParamCaseEventId, arp.col_tasktemplateautorulepartp as RuleParamTaskTmplId,
               null as CaseEventId, null as CaseEventProcessorCode,
               null as RTCaseEventId, null as RTCaseEventProcCode
          from tbl_autoruleparamtmpl arp
          --JOIN TO DESIGN TIME CASESTATEINITIATION RECORDS
          inner join tbl_map_casestateinittmpl csi on arp.col_rulepartp_casestateinittp = csi.col_id
          inner join tbl_case cs on csi.col_casestateinittp_casetype = cs.col_casedict_casesystype
          --JOIN TO RUNTIME CASESTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME CASESTATEINITIATION RECORDS
          inner join tbl_map_casestateinitiation csi2 on cs.col_id = csi2.col_map_casestateinitcase and csi.col_map_csstinittp_csst = csi2.col_map_csstinit_csst
          where cs.col_id = v_CaseId) s1;
        exception
         when DUP_VAL_ON_INDEX then
           :ErrorCode := 100;
           :ErrorMessage := 'DCM_CopyRuleParameter: ' || SUBSTR(SQLERRM, 1, 200);
           return -1;
         when OTHERS then
           :ErrorCode := 100;
           :ErrorMessage := 'DCM_CopyRuleParameter: ' || SUBSTR(SQLERRM, 1, 200);
           return -1;
    end;  
 END IF;



  --case  in new cache 
  IF v_CSisInCache=1 THEN	  
    
    FOR rec IN
      (select s1.RTTaskStateInitId, s1.RTTaskEventId, s1.RuleParamCode, s1.RuleParamValue,  s1.RuleParamTaskTmplId, 
              s1.RTTaskId
        from
        (
        --SELECT AUTORULEPARAMETER RECORDS FOR COPYING FROM DESIGN TIME TO RUNTIME
        --SELECT ALL RULE PARAMETERS RELATED TO TASK STATE INITIATION
        select tsi.col_id as DTTaskStateInitId, tsi.col_processorcode as TaskStateInitProcessorCode, tsi.col_map_taskstateinittptaskcc as TaskStateInitTaskId,
               tsi.col_map_tskstinittpl_initmtd as TaskStateInitMethodId, tsi.col_map_tskstinittpl_tskst as TaskStateInitStateId,
               tsi.col_map_taskstinittpltasktpl as TaskTmplId,
               tsi2.col_id as RTTaskStateInitId, tsi2.col_map_taskstateinittask as TaskId, null as RTTaskId,
               arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_rulepartp_taskstateinittp as RuleParamTaskStateInitId, arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId, arp.col_tasktemplateautorulepartp as RuleParamTaskTmplId,
               null as TaskEventId, null as TaskEventProcessorCode,
               null as RTTaskEventId, null as RTTaskEventProcCode
          from tbl_autoruleparamtmpl arp
          --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
          inner join tbl_map_taskstateinittmpl tsi on arp.col_rulepartp_taskstateinittp = tsi.col_id
          inner join tbl_Cstask tsk on tsi.col_map_taskstinittpltasktpl = tsk.col_id2
          --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
          inner join TBL_CSMAP_TASKSTATEINIT tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinittpl_tskst = tsi2.col_map_tskstinit_tskst
          where arp.col_taskeventtpautoruleparmtp is null and tsk.col_casetask = v_CaseId
        union
        --SELECT ALL RULEPARAMETERS FOR EVENTS, RELATED TO TASK STATE INITIATION EVENTS
        select tsi.col_id as DTTaskStateInitId, tsi.col_processorCode as TaskStateInitProcessorCode, tsi.col_map_taskstateinittptaskcc as TaskStateInitTaskId,
               tsi.col_map_tskstinittpl_initmtd as TaskStateInitMethodId, tsi.col_map_tskstinittpl_tskst as TaskStateInitStateId,
               tsi.col_map_taskstinittpltasktpl as TaskTmplId,
               null as RTTaskStateInitId, tsi2.col_map_taskstateinittask as TaskId, null as RTTaskId,
               arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_rulepartp_taskstateinittp as RuleParamTaskStateInitId, arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId, arp.col_tasktemplateautorulepartp as RuleParamTaskTmplId,
               te.col_id as TaskEventId, te.col_processorcode as TaskEventProcessorCode,
               te2.col_id as RTTaskEventId, te2.col_processorcode as RTTaskEventProcCode
          from tbl_autoruleparamtmpl arp
          inner join tbl_taskeventtmpl te on arp.col_taskeventtpautoruleparmtp = te.col_id
          --JOIN TO DESIGN TIME TASLSTATEINITIATION RECORDS
          inner join tbl_map_taskstateinittmpl tsi on te.col_taskeventtptaskstinittp = tsi.col_id
          inner join tbl_cstask tsk on tsi.col_map_taskstinittpltasktpl = tsk.col_id2
          --JOIN TO RUNTIME TASKSTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME TASKSTATEINITIATION RECORDS
          inner join TBL_CSMAP_TASKSTATEINIT tsi2 on tsk.col_id = tsi2.col_map_taskstateinittask and tsi.col_map_tskstinittpl_tskst = tsi2.col_map_tskstinit_tskst
          inner join tbl_cstaskevent te2 on tsi2.col_id = te2.col_taskeventtaskstateinit and te.col_taskeventorder = te2.col_taskeventorder
          where tsk.col_casetask = v_CaseId
        union
        --SELECT ALL RULEPARAMETERS FOR AUTOMATIC TASKS
        select null as DTTaskStateInitId, cast(tsk.col_processorName as nvarchar2(255)) as TaskStateInitProcessorCode, null as TaskStateInitTaskId,
               null as TaskStateInitMethodId, null as TaskStateInitStateId,
               tskt.col_Id as TaskTmplId,
               null as RTTaskStateInitId, tsk.col_id as TaskId, tsk.col_id as RTTaskId,
               arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_rulepartp_taskstateinittp as RuleParamTaskStateInitId, arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId, null as RuleParamTaskTmplId,
               null as TaskEventId, null as TaskEventProcessorCode,
               null as RTTaskEventId, null as RTTaskEventProcCode
          from tbl_autoruleparamtmpl arp
            inner join tbl_tasktemplate tskt on arp.col_tasktemplateautorulepartp = tskt.col_id
            inner join tbl_cstask tsk on tskt.col_id = tsk.col_id2
            where tsk.col_casetask = v_CaseId
        ) s1)    
    LOOP
      SELECT gen_tbl_autoruleparameter.NEXTVAL INTO v_arpId FROM dual;

      INSERT INTO TBL_CSAUTORULEPARAMETER(COL_ID, COL_RULEPARAM_TASKSTATEINIT, COL_TASKEVENTAUTORULEPARAM, COL_PARAMCODE, 
                                          COL_PARAMVALUE,COL_TTAUTORULEPARAMETER,COL_AUTORULEPARAMETERTASK,
                                          COL_CREATEDBY,COL_CREATEDDATE,COL_MODIFIEDBY,COL_MODIFIEDDATE,COL_OWNER, COL_CODE)
      VALUES(v_arpId, rec.RTTaskStateInitId, rec.RTTaskEventId, rec.RuleParamCode, rec.RuleParamValue, rec.RuleParamTaskTmplId, rec.RTTaskId,
             v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner, SYS_GUID());
    END LOOP;
    

    FOR rec IN
    (
       select s1.RTTaskDependencyId, s1.RuleParamCode, s1.RuleParamValue,
              v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
       from
       (select td.col_id as DTTaskDependencyId, td2.col_id as RTTaskDependencyId,
               ctsi.col_id as CDTTaskStateInitId, ctsi.col_processorcode as CTaskStateInitProcessorCode, ctsi.col_map_taskstateinittptaskcc as CTaskStateInitTaskId,
               ctsi.col_map_tskstinittpl_initmtd as CTaskStateInitMethodId, ctsi.col_map_tskstinittpl_tskst as CTaskStateInitStateId,
               ctsi.col_map_taskstinittpltasktpl as CTaskTmplId,
               ctsi2.col_id as CRTTaskStateInitId, ctsi2.col_map_taskstateinittask as CTaskId,
               ptsi.col_id as PDTTaskStateInitId, ptsi.col_processorcode as PTaskStateInitProcessorCode, ptsi.col_map_taskstateinittptaskcc as PTaskStateInitTaskId,
               ptsi.col_map_tskstinittpl_initmtd as PTaskStateInitMethodId, ptsi.col_map_tskstinittpl_tskst as PTaskStateInitStateId,
               ptsi.col_map_taskstinittpltasktpl as PTaskTmplId,
               ptsi2.col_id as PRTTaskStateInitId, ptsi2.col_map_taskstateinittask as PTaskId,
               arp.col_id as ARPId, arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
               arp.col_rulepartp_taskstateinittp as RuleParamTaskStateInitId, arp.col_taskeventtpautoruleparmtp as RuleParamTaskEventId,
               arp.col_tasktemplateautorulepartp as RuleParamTaskTmplId
        from tbl_autoruleparamtmpl arp
        inner join tbl_taskdependencytmpl td on arp.col_autoruleparamtptaskdeptp = td.col_id
        inner join tbl_map_taskstateinittmpl ctsi on td.col_taskdpchldtptaskstinittp = ctsi.col_id
        inner join tbl_cstask ctsk on ctsi.col_map_taskstinittpltasktpl = ctsk.col_id2
        inner join tbl_map_taskstateinittmpl ptsi on td.col_taskdpprnttptaskstinittp = ptsi.col_id
        inner join tbl_cstask ptsk on ptsi.col_map_taskstinittpltasktpl = ptsk.col_id2
        --RUNTIME
        inner join TBL_CSMAP_TASKSTATEINIT ctsi2 on ctsk.col_id = ctsi2.col_map_taskstateinittask and ctsi.col_map_tskstinittpl_tskst = ctsi2.col_map_tskstinit_tskst
        inner join TBL_CSMAP_TASKSTATEINIT ptsi2 on ptsk.col_id = ptsi2.col_map_taskstateinittask and ptsi.col_map_tskstinittpl_tskst = ptsi2.col_map_tskstinit_tskst
        inner join TBL_CSTASKDEPENDENCY td2 on ctsi2.col_id = td2.col_tskdpndchldtskstateinit and ptsi2.col_id = td2.col_tskdpndprnttskstateinit
        where ctsk.col_casetask = v_CaseId and ptsk.col_casetask = v_CaseId) s1)
    LOOP
      SELECT gen_tbl_autoruleparameter.NEXTVAL INTO v_arpId FROM dual;

      INSERT INTO TBL_CSAUTORULEPARAMETER(COL_ID, COL_AUTORULEPARAMTASKDEP, COL_PARAMCODE,COL_PARAMVALUE,
                                          COL_CREATEDBY,COL_CREATEDDATE,COL_MODIFIEDBY,COL_MODIFIEDDATE, 
                                          COL_OWNER, COL_CODE)
       VALUES(v_arpId,  rec.RTTaskDependencyId, rec.RuleParamCode, rec.RuleParamValue,
              v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner, SYS_GUID());
    END LOOP;

    
   
   FOR rec IN
   (
     select s1.RTCaseStateInitId, s1.RTCaseEventId, s1.RuleParamCode, s1.RuleParamValue,
            v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner
     from
     (select csi.col_id as DTCaseStateInitId, csi.col_processorcode as CaseStateInitProcessorCode, csi.col_map_casestateinittpcasecc as CaseStateInitCaseId,
             csi.col_casestateinittp_initmtd as CaseStateInitMethodId, csi.col_map_csstinittp_csst as CaseStateInitStateId,
             csi.col_casestateinittp_casetype as CaseSysTypeId,
             csi2.col_id as RTCaseStateInitId, csi2.col_map_casestateinitcase as CaseId, null as RTCaseId,
             arp.col_id as AutoRuleParamId, arp.col_paramcode as RuleParamCode, arp.col_paramvalue as RuleParamValue,
             arp.col_rulepartp_taskstateinittp as RuleParamCaseStateInitId, arp.col_caseeventtpautorulepartp as RuleParamCaseEventId, arp.col_tasktemplateautorulepartp as RuleParamTaskTmplId,
             null as CaseEventId, null as CaseEventProcessorCode,
             null as RTCaseEventId, null as RTCaseEventProcCode
        from tbl_autoruleparamtmpl arp
        --JOIN TO DESIGN TIME CASESTATEINITIATION RECORDS
        inner join tbl_map_casestateinittmpl csi on arp.col_rulepartp_casestateinittp = csi.col_id
        inner join tbl_cscase cs on csi.col_casestateinittp_casetype = cs.col_casedict_casesystype
        --JOIN TO RUNTIME CASESTATEINITIATION RECORDS CORRESPONDING TO DESIGN TIME CASESTATEINITIATION RECORDS
        inner join TBL_CSMAP_CASESTATEINIT csi2 on cs.col_id = csi2.col_map_casestateinitcase and csi.col_map_csstinittp_csst = csi2.col_map_csstinit_csst
        where cs.col_id = v_CaseId) s1)
   LOOP

      SELECT gen_tbl_autoruleparameter.NEXTVAL INTO v_arpId FROM dual;

      INSERT INTO TBL_CSAUTORULEPARAMETER(COL_ID, COL_RULEPARAM_CASESTATEINIT, COL_CASEEVENTAUTORULEPARAM, 
                                          COL_PARAMCODE, COL_PARAMVALUE, COL_CREATEDBY, COL_CREATEDDATE, 
                                          COL_MODIFIEDBY, COL_MODIFIEDDATE, COL_OWNER, COL_CODE)
      VALUES(v_arpId,  rec.RTCaseStateInitId, rec.RTCaseEventId, rec.RuleParamCode, rec.RuleParamValue,
             v_createdby, v_createddate, v_modifiedby, v_modifieddate, v_owner, SYS_GUID());
   END LOOP;     
  END IF;
END;