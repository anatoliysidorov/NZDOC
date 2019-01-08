DECLARE
 v_ErrorCode     NUMBER;
 v_ErrorMessage  nvarchar2(255);
 v_CaseID        NUMBER;
 v_ProcedureId   NUMBER;
 v_col_owner     nvarchar2(255);
 v_col_taskid    nvarchar2(255);
 v_Result        NUMBER;
 v_col_createdby nvarchar2(255);
 v_col_createddate date;
 v_col_modifiedby nvarchar2(255);
 v_col_modifieddate date;
 v_Recordid INTEGER;
 v_prefix nvarchar2(255);
BEGIN
 :affectedRows := 0;
 :recordId := 0;
 :ErrorCode := 0;
 :ErrorMessage := null;

 v_CaseId := :CaseId;
 v_ProcedureId := :ProcedureId;
 v_col_owner := :owner;
 v_col_createdby := :TOKEN_USERACCESSSUBJECT;
 v_prefix := :prefix;
 if v_prefix is null then
   v_prefix := 'TASK-';
 end if;
 v_col_createddate := sysdate;
 v_col_modifiedby := v_col_createdby;
 v_col_modifieddate := v_col_createddate;
 
 BEGIN

   DELETE FROM tbl_taskcc
   WHERE  col_casecctaskcc = v_caseid;

	INSERT INTO tbl_taskcc
                (col_id2,
                 col_createdby,
                 col_createddate,
                 col_modifiedby,
                 col_modifieddate,
                 col_owner,
                 col_type, 
                 col_parentidcc,
                 col_description,
                 col_name, 
                 col_taskid,
                 col_depth,
                 col_iconcls,
                 col_icon,
                 col_leaf,
                 col_taskorder,
                 col_required,
                 col_casecctaskcc,
                 col_taskccdict_tasksystype,
                 col_processorname,
                 col_taskccdict_executionmtd,
                 col_pagecode)
    SELECT col_id, 
           v_col_createdby, 
           v_col_createddate, 
           v_col_modifiedby, 
           v_col_modifieddate, 
           v_col_owner, 
           col_type, 
           col_parentttid, 
           col_description, 
           col_name, 
           col_taskid, 
           col_depth, 
           col_iconcls, 
           col_icon, 
           col_leaf, 
           col_taskorder, 
           col_required, 
           v_caseid,
           col_tasktmpldict_tasksystype,
           col_processorcode,
           col_execmethodtasktemplate,
           col_pagecode
    FROM   tbl_tasktemplate 
    WHERE  col_proceduretasktemplate = v_procedureid 
    ORDER  BY col_depth, 
              col_parentttid,
              col_taskorder,
              col_id; 

    UPDATE tbl_taskcc tt1 
    SET    col_parentidcc = (SELECT col_id
                           FROM   tbl_taskcc tt2
                           WHERE  tt2.col_id2 = tt1.col_parentidcc
                             AND tt2.col_casecctaskcc = v_caseid)
    WHERE  col_casecctaskcc = v_caseid;
   
   begin
     for task_rec in (
     select col_id, col_taskid from tbl_taskcc where col_casecctaskcc = v_CaseId)
     loop
       v_Result := f_DCM_generateTaskCCId(ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, TaskId => task_rec.col_id, TaskTitle => v_col_taskid);
     end loop;
   end;


   update tbl_taskcc set col_parentidcc = 0 where col_casecctaskcc = v_CaseId and col_parentidcc is null;


    :affectedRows := 1;
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN
     :affectedRows := 0;
    WHEN OTHERS THEN
     :ErrorCode := 100;
     :ErrorMessage := 'DCM_CopyTaskCC: ' || SUBSTR(SQLERRM, 1, 200);
  END;

  return :affectedRows;
      
END;