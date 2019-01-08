declare
v_cw_id NUMBER;
v_task_id Number;
v_tmp Number;
v_ppl_orgchart_id Number;
v_caseworkerchild_id Number;
v_caseworkerparent_id Number;
v_result Number;

BEGIN
v_task_id := :Task_Id;
v_cw_id :=0;
v_tmp :=0;
v_ppl_orgchart_id := 0;
v_caseworkerchild_id := 0;
v_caseworkerparent_id := 0;
v_result := -1;
---get the attached caseworker to the given task
BEGIN
  SELECT cw.col_id into v_cw_id 
  FROM tbl_PPL_CaseWorker cw 
  INNER JOIN tbl_PPL_Workbasket wb
  ON (cw.col_id = wb.COL_CASEWORKERWORKBASKET)
  WHERE wb.col_id in (
    SELECT t.COL_TASKPPL_WORKBASKET
    FROM tbl_Task t 
    WHERE t.col_id = v_task_id
  );
  --dbms_output.put_line(v_cw_id);
  EXCEPTION 
  WHEN NO_DATA_FOUND THEN
   -- dbms_output.put_line('No CaseWorker for the given Task Id:'|| v_task_id);
    goto cleanup;
END;
---get the attached PPL_OrgChart to the given task
BEGIN
  Select 
    Poc.Col_Id Into V_Ppl_Orgchart_id
  From Tbl_Task Tsk
  Left Join Tbl_Case Cs
  On (Tsk.Col_Casetask = Cs.Col_Id)
  Left Join Tbl_Dict_Casesystype Cst
  On(Cs.Col_Casedict_Casesystype = Cst.Col_Id)
  Left Join Tbl_Ppl_Orgchart Poc
  On(Cst.Col_Id = Poc.Col_Casesystypeorgchart)
  Where Tsk.Col_Id = v_task_id;
  If V_Ppl_Orgchart_id IS NULL THEN
 -- Dbms_Output.Put_Line('V_Ppl_Orgchart_id is null');
  goto cleanup;
  END IF;
  Exception 
  When No_Data_Found Then
   -- Dbms_Output.Put_Line('No PPL_OrgChart for the given Task Id:'|| v_task_id);
    goto cleanup;
END;
---Find the CaseWorker attached to the Task within the PPL_OrgChartMap
BEGIN
  SELECT 
  COL_CASEWORKERCHILD,COL_CASEWORKERPARENT 
  INTO v_caseworkerchild_id,v_caseworkerparent_id
  FROM TBL_PPL_ORGCHARTMAP
  WHERE COL_ORGCHARTORGCHARTMAP = V_Ppl_Orgchart_id 
  AND COL_CASEWORKERCHILD = v_cw_id;
  
  If v_caseworkerchild_id IS NULL THEN
 --Dbms_Output.Put_Line('v_caseworkerchild_id is null');
  goto cleanup;
  ELSE
  --Dbms_Output.Put_Line(v_caseworkerparent_id);
  v_result := v_caseworkerparent_id;
  END IF;
  Exception 
  When No_Data_Found Then
   -- Dbms_Output.Put_Line('Bad!');
    goto cleanup;
END;
<<cleanup>> 
    
return v_result;
END;