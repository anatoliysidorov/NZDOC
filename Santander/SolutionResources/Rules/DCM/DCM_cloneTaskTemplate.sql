declare
  v_createdby nvarchar2(255);
  v_createddate date;
  v_owner nvarchar2(255);
  v_modifiedby nvarchar2(255);
  v_modifieddate date;  
  v_procedureid Integer;
  v_newprocedureid Integer;
  v_procedurename NVARCHAR2(255);
  v_name NVARCHAR2(255);
  v_isdefault NUMBER;
  v_description NCLOB;
  
  v_counter number;
  v_lastcounter number;
begin
  v_ProcedureId := :ProcedureId;
  v_owner := '@TOKEN_USERACCESSSUBJECT@';
  v_createdby := '@TOKEN_USERACCESSSUBJECT@';
  v_createddate := sysdate;
  v_modifiedby := v_createdby;
  v_modifieddate := v_createddate;
  v_procedurename := :ProcedureName; 
  v_description := :Description; 
  v_name := 'root'; 
  v_isdefault := :IsDefault; 

  INSERT INTO tbl_procedure
                (col_createdby,
                 col_createddate,
                 col_modifiedby,
                 col_modifieddate,
                 col_owner,
                 col_name,
                 col_description,
                 col_isdefault)
    VALUES      (v_createdby,
                 v_createddate,
                 v_createdby,
                 v_createddate,
                 v_createdby,
                 v_procedurename,
                 v_description,
                 v_isdefault);

  SELECT gen_tbl_procedure.CURRVAL
    INTO v_newprocedureid
    FROM dual;

select GEN_TBL_TASKTEMPLATE.nextval into v_counter from dual;

  INSERT INTO tbl_tasktemplate
                (col_id2,
                 col_createdby,
                 col_createddate,
                 col_modifiedby,
                 col_modifieddate,
                 col_owner,
                 col_type,
                 col_parentttid,
                 col_deadline,
                 col_description,
                 col_goal,
                 col_name,
                 col_taskid,
                 col_urgency,
                 col_depth,
                 col_iconcls,
                 col_icon,
                 col_leaf,
                 col_taskorder,
                 col_required,
                 col_SystemType,
                 col_proceduretasktemplate)
  SELECT col_id,
         v_createdby,
         v_createddate,
         v_modifiedby,
         v_modifieddate,
         v_owner,
         col_type,
         col_parentttid,
         col_deadline,
         col_description,
         col_goal,
         col_name,
         col_taskid,
         col_urgency,
         col_depth,
         col_iconcls,
         col_icon,
         col_leaf,
         col_taskorder,
         col_required,
         col_SystemType,
         v_newprocedureid
    FROM tbl_tasktemplate
    WHERE col_proceduretasktemplate = v_procedureid
    ORDER BY col_depth,
             col_parentttid,
             col_id;


  UPDATE tbl_tasktemplate tt1
    SET col_parentttid = (SELECT col_id
                          FROM tbl_tasktemplate tt2
                          WHERE tt2.col_id2 = tt1.col_parentttid
                          AND tt2.col_proceduretasktemplate = v_newprocedureid)
    WHERE col_proceduretasktemplate = v_newprocedureid
    AND col_parentttid <> 0;
    
  select GEN_TBL_TASKTEMPLATE.currval into v_lastcounter from dual;

  for rec in (select col_id from tbl_tasktemplate where col_id between v_counter and v_lastcounter)
  loop
    update tbl_tasktemplate set col_code = sys_guid() where col_id = rec.col_id;
  end loop;
    
  :NewProcedureId := v_newprocedureid;
end;
