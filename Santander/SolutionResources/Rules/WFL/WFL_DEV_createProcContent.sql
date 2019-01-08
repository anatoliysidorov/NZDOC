declare
  v_input xmltype;
  v_output nclob;
  v_count Integer;
  v_result nvarchar2(255);
  v_result2 nvarchar2(255);
  v_elementid Integer;
  v_code nvarchar2(255);
  v_name nvarchar2(255);
  v_description nclob;
  v_procedureid Integer;
  v_procedurecode nvarchar2(255);
  v_inserttotask number;
  v_taskType nvarchar2(255);
  v_taskTypeId Integer;
  v_stateConfigId Integer;
  v_stateid Integer;
  v_executionMethod nvarchar2(255);
  v_executionMethodId Integer;
  v_executionType nvarchar2(255);
  v_executionTypeId Integer;
  v_autoassignrule nvarchar2(255);
  v_rootTaskTemplateId Integer;
  v_taskTemplateId Integer;
  v_taskEventId Integer;
  v_taskEventTmplId Integer;
  v_eventtype nvarchar2(255);
  v_priority nvarchar2(255);
  v_subtype nvarchar2(255);
  v_resolutioncode nvarchar2(255);
  v_sourceid Integer;
  v_targetid Integer;
  v_taskstateinitsourceid Integer;
  v_taskstateinitsrctmplid Integer;
  v_taskstateinittargetid Integer;
  v_taskstateinittrgtmplid Integer;
  v_type nvarchar2(255);
  v_processorcode nvarchar2(255);
  v_taskDependencyId Integer;
  v_taskDependencyTmplId Integer;
  v_eventtask Integer;
  v_executionMoment nvarchar2(255);
  v_ruleCode nvarchar2(255);
  v_taskstateinitiationid Integer;
  v_taskstateinittmplid Integer;
  v_slaeventid Integer;
  v_slaeventtmplid Integer;
  v_slaActionId Integer;
  v_slaActionTmplId Integer;
  v_distributionchannel nvarchar2(255);
  v_fromrule nvarchar2(255);
  v_torule nvarchar2(255);
  v_ccrule nvarchar2(255);
  v_bccrule nvarchar2(255);
  v_templaterule nvarchar2(255);
  v_attachmentsrule nvarchar2(255);
  v_template nvarchar2(255);
  v_from nvarchar2(255);
  v_to nvarchar2(255);
  v_cc nvarchar2(255);
  v_bcc nvarchar2(255);
  v_messagecode nvarchar2(255);
  v_channel nvarchar2(255);
  v_messageslack nvarchar2(255);
  v_messagerule nvarchar2(255);
  v_participantcode nvarchar2(255);
  v_workbasketrule nvarchar2(255);
  v_category nvarchar2(255);
  v_mediatype nvarchar2(255);
  v_pagesend1 nvarchar2(255);
  v_pagesend2 nvarchar2(255);
  v_pagesendparamsrule1 nvarchar2(255);
  v_pagesendparamsrule2 nvarchar2(255);
  v_customdatarule nvarchar2(255);
  --xml using
  v_XMLParameters NCLOB;
  v_XMLcount INTEGER; 
  v_XMLPathName NVARCHAR2(255);
  v_XMLPathValue NVARCHAR2(255);
  v_XMLParamName NVARCHAR2(255);
  v_XMLParamValue NVARCHAR2(4000);
  
begin
  v_output := f_WFL_DEV_parseProcModel(:Input);

  begin
    select col_procedureid into v_procedureid from tbl_processcache where col_procedureid is not null;
    exception
    when NO_DATA_FOUND then
    v_procedureid := null;
    return -1;
    when TOO_MANY_ROWS then
    v_procedureid := null;
    return -1;
  end;
  v_count := f_WFL_deleteProcContentTmpl(v_procedureid);
  v_count := f_WFL_deleteProcContent(v_procedureid);
  --v_code := f_UTIL_extract_value_xml(Input => v_input, Path => '/Process/Procedure/@code');
  begin
    select col_elementid, col_procedureid, col_code
    into v_elementid, v_procedureid, v_code
    from tbl_processcache
    where col_type = 'root';
    exception
    when NO_DATA_FOUND then
      v_procedureid := null;
      return -1;
    when TOO_MANY_ROWS then
      v_procedureid := null;
      return -1;
  end;
  begin
    select col_id into v_rootTaskTemplateId from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid and lower(col_name) = 'root';
    exception
    when NO_DATA_FOUND then
      insert into tbl_tasktemplate(col_name, col_taskid, col_tasktmpldict_tasksystype, col_proceduretasktemplate, col_parentttid, col_execmethodtasktemplate, col_taskorder, col_id2, col_code)
                            values('Root', 'Root', null, v_procedureid, 0, null, 1, to_number(v_result), sys_guid());
      select gen_tbl_tasktemplate.currval into v_rootTaskTemplateId from dual;
    when TOO_MANY_ROWS then
      delete from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid and lower(col_name) = 'root';
      insert into tbl_tasktemplate(col_name, col_taskid, col_tasktmpldict_tasksystype, col_proceduretasktemplate, col_parentttid, col_execmethodtasktemplate, col_taskorder, col_id2, col_code)
                            values('Root', 'Root', null, v_procedureid, 0, null, 1, to_number(v_result), sys_guid());
      select gen_tbl_tasktemplate.currval into v_rootTaskTemplateId from dual;
  end;

  --Tasks and gateways
  v_count := 1;
  for rec in (select col_elementid as ElementId, col_type as Type, col_istask as IsTask, col_name as Name, col_tasktypecode as TaskType, col_executiontypecode as ExecutionType, col_description as Description,
              col_rulecode as RuleCode, col_autoassignrule as AutoAssignRule, col_defaultstate as DefaultState
              from tbl_processcache
              where col_type in ('task','gateway')
              order by col_elementid)
  loop
    if rec.Type = 'task' or (rec.Type = 'gateway' and rec.IsTask = 1) then
      v_name := rec.Name;
      v_tasktype := rec.TaskType;
      v_ruleCode := rec.RuleCode;
      v_autoassignrule := rec.AutoAssignRule;
      begin
        select col_id, col_stateconfigtasksystype into v_taskTypeId, v_stateConfigId from tbl_dict_tasksystype where col_code = v_tasktype;
        exception
        when NO_DATA_FOUND then
        v_taskTypeId := null;
        v_stateConfigId := null;
        when TOO_MANY_ROWS then
        v_taskTypeId := null;
        v_stateConfigId := null;
      end;
      -- Execution Method is used to make initiation method property for all task states AUTOMATIC (Initiation Method in TBL_MAP_TASKSTATEINITIATION)
      v_executionMethod := rec.ExecutionType;
      begin
        select col_id into v_executionMethodId from tbl_dict_initmethod where col_code = v_executionMethod;
        exception
        when NO_DATA_FOUND then
        v_executionMethodId := null;
        when TOO_MANY_ROWS then
        v_executionMethodId := null;
      end;
      -- Execution Type is always 'MANUAL' (in the current implememntation) and is used as the property of the entire task (Execution Method in TBL_TASK)
      v_executiontype := 'MANUAL';
      begin
        select col_id into v_executionTypeId from tbl_dict_executionmethod where col_code = v_executionType;
        exception
        when NO_DATA_FOUND then
        v_executionTypeId := null;
        when TOO_MANY_ROWS then
        v_executionTypeId := null;
      end;
      --Calculate task state machine configuration
      if v_stateConfigId is null then
        begin
          select col_id into v_stateConfigId from tbl_dict_stateconfig where col_isdefault = 1 and lower(col_type) = 'task';
          exception
          when NO_DATA_FOUND then
            v_stateConfigId := null;
          when TOO_MANY_ROWS then
            v_stateConfigId := null;
        end;
      end if;
      --Calculate task state in which task must be created
      if rec.DefaultState is null then
        v_stateid := null;
      elsif lower(rec.DefaultState) = 'default' then
        begin
          select col_id into v_stateid from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateconfigid,0) and col_isdefaultoncreate = 1;
          exception
          when NO_DATA_FOUND then
          v_stateid := null;
          when TOO_MANY_ROWS then
          v_stateid := null;
        end;
      elsif lower(rec.DefaultState) = 'start' then
        begin
          select col_id into v_stateid from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateconfigid,0) and col_isstart = 1;
          exception
          when NO_DATA_FOUND then
          v_stateid := null;
          when TOO_MANY_ROWS then
          v_stateid := null;
        end;
      elsif lower(rec.DefaultState) = 'assign' then
        begin
          select col_id into v_stateid from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateconfigid,0) and col_isassign = 1;
          exception
          when NO_DATA_FOUND then
          v_stateid := null;
          when TOO_MANY_ROWS then
          v_stateid := null;
        end;
      elsif lower(rec.DefaultState) = 'inprocess' then
        begin
          select col_id into v_stateid from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateconfigid,0) and col_isdefaultoncreate2 = 1;
          exception
          when NO_DATA_FOUND then
          v_stateid := null;
          when TOO_MANY_ROWS then
          v_stateid := null;
        end;
      elsif lower(rec.DefaultState) = 'resolve' then
        begin
          select col_id into v_stateid from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateconfigid,0) and col_isresolve = 1;
          exception
          when NO_DATA_FOUND then
          v_stateid := null;
          when TOO_MANY_ROWS then
          v_stateid := null;
        end;
      elsif lower(rec.DefaultState) = 'finish' then
        begin
          select col_id into v_stateid from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateconfigid,0) and col_isfinish = 1;
          exception
          when NO_DATA_FOUND then
          v_stateid := null;
          when TOO_MANY_ROWS then
          v_stateid := null;
        end;
      else
        begin
          select col_id into v_stateid from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateconfigid,0) and col_isdefaultoncreate = 1;
          exception
          when NO_DATA_FOUND then
          v_stateid := null;
          when TOO_MANY_ROWS then
          v_stateid := null;
        end;
      end if;

      insert into tbl_tasktemplate(col_name, col_tasktmpldict_tasksystype, col_proceduretasktemplate, col_parentttid, col_execmethodtasktemplate, col_taskorder, col_description, col_id2, col_processorcode, col_tasktmpldict_taskstate, col_code)
        values(v_name, v_taskTypeId, v_procedureid, v_rootTaskTemplateId, v_executionTypeId, v_count, rec.Description, rec.ElementId, v_ruleCode, v_stateid, sys_guid());
      select gen_tbl_tasktemplate.currval into v_taskTemplateId from dual;
      for rec2 in (select col_id as StateId, col_code as StateCode, col_name as StateName, col_activity as StateActivity, col_isfinish as IsFinishState, col_isstart as IsStartState, col_isassign as IsAssignState
                   from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0))
      loop
        insert into tbl_map_taskstateinitiation(col_map_taskstateinittasktmpl, col_map_tskstinit_tskst, col_map_tskstinit_initmtd, col_assignprocessorcode, col_code)
          values(v_taskTemplateId, (select col_id from tbl_dict_taskstate where col_activity = rec2.StateActivity and nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)),
          case when nvl(rec2.IsStartState,0) = 0 and nvl(rec2.IsFinishState,0) = 0 then
          (select col_id from tbl_dict_initmethod where col_code = 'AUTOMATIC')
          when rec2.IsStartState = 1 then
          (select col_id from tbl_dict_initmethod where col_code = 'AUTOMATIC_RULE')
          when rec2.IsFinishState = 1 then
          (select col_id from tbl_dict_initmethod where col_code = (case when v_executionMethod = 'MANUAL' then 'MANUAL' when v_executionMethod = 'AUTOMATIC' then 'AUTOMATIC' else 'MANUAL' end))
          else (select col_id from tbl_dict_initmethod where col_code = 'AUTOMATIC') end,
          case when nvl(rec2.IsAssignState,0) = 1 then v_autoassignrule else null end,
          sys_guid());
        insert into tbl_map_taskstateinittmpl(col_map_taskstinittpltasktpl, col_map_tskstinittpl_tskst, col_map_tskstinittpl_initmtd, col_assignprocessorcode, col_code)
          values(v_taskTemplateId, (select col_id from tbl_dict_taskstate where col_activity = rec2.StateActivity and nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)),
          case when nvl(rec2.IsStartState,0) = 0 and nvl(rec2.IsFinishState,0) = 0 then
          (select col_id from tbl_dict_initmethod where col_code = 'AUTOMATIC')
          when rec2.IsStartState = 1 then
          (select col_id from tbl_dict_initmethod where col_code = 'AUTOMATIC_RULE')
          when rec2.IsFinishState = 1 then
          (select col_id from tbl_dict_initmethod where col_code = (case when v_executionMethod = 'MANUAL' then 'MANUAL' when v_executionMethod = 'AUTOMATIC' then 'AUTOMATIC' else 'MANUAL' end))
          else (select col_id from tbl_dict_initmethod where col_code = 'AUTOMATIC') end,
          case when nvl(rec2.IsAssignState,0) = 1 then v_autoassignrule else null end,
          sys_guid());
      end loop;
    end if;
    v_count := v_count + 1;
  end loop;
  --End of tasks and gateways


  --Dependencies--
  v_count := 1;
  for rec in (select col_elementid as ElementId, col_dependencytype as DependencyType, col_resolutioncode as ResolutionCode, col_source as Source, col_target as Target, col_source2 as Source2,
              col_conditiontype as ConditionType, col_rulecode as RuleCode
              from tbl_processcache
              where col_type = 'dependency'
              order by col_elementid)
  loop
    v_elementid := rec.ElementId;
    v_sourceid := nvl(rec.Source2,rec.Source);
    v_targetid := rec.Target;
    v_type := rec.DependencyType;
    v_ResolutionCode := rec.ResolutionCode;
    begin
      select col_tasktypecode
      into v_tasktype
      from tbl_processcache
      where col_elementid = v_sourceid and col_type = 'task';
      exception
      when NO_DATA_FOUND then
      v_tasktype := null;
      when TOO_MANY_ROWS then
      v_tasktype := null;
    end;
    begin
      select col_id, col_stateconfigtasksystype into v_taskTypeId, v_stateConfigId from tbl_dict_tasksystype where col_code = v_tasktype;
      exception
      when NO_DATA_FOUND then
      v_taskTypeId := null;
      v_stateConfigId := null;
      when TOO_MANY_ROWS then
      v_taskTypeId := null;
      v_stateConfigId := null;
    end;
    --Calculate task state machine configuration
    if v_stateConfigId is null then
      begin
        select col_id into v_stateConfigId from tbl_dict_stateconfig where col_isdefault = 1 and lower(col_type) = 'task';
        exception
        when NO_DATA_FOUND then
          v_stateConfigId := null;
        when TOO_MANY_ROWS then
          v_stateConfigId := null;
      end;
    end if;
    --Calculate TaskStateInit source
    begin
      select col_id into v_taskstateinitsourceid from tbl_map_taskstateinitiation where col_map_taskstateinittasktmpl =
      (select col_id from tbl_tasktemplate where col_id2 = v_sourceid and col_proceduretasktemplate = v_procedureid)
      and col_map_tskstinit_tskst = (select col_id from tbl_dict_taskstate where col_activity =
      (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isfinish = 1)
      and nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0));
      exception
      when NO_DATA_FOUND then
      v_taskstateinitsourceid := null;
      when TOO_MANY_ROWS then
      v_taskstateinitsourceid := null;
    end;
    begin
      select col_id into v_taskstateinitsrctmplid from tbl_map_taskstateinittmpl where col_map_taskstinittpltasktpl =
      (select col_id from tbl_tasktemplate where col_id2 = v_sourceid and col_proceduretasktemplate = v_procedureid)
      and col_map_tskstinittpl_tskst = (select col_id from tbl_dict_taskstate where col_activity =
      (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isfinish = 1)
      and nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0));
      exception
      when NO_DATA_FOUND then
      v_taskstateinitsrctmplid := null;
      when TOO_MANY_ROWS then
      v_taskstateinitsrctmplid := null;
    end;
    begin
      select col_tasktypecode
      into v_tasktype
      from tbl_processcache
      where col_elementid = v_targetid and col_type = 'task';
      exception
      when NO_DATA_FOUND then
      v_tasktype := null;
      when TOO_MANY_ROWS then
      v_tasktype := null;
    end;
    begin
      select col_id, col_stateconfigtasksystype into v_taskTypeId, v_stateConfigId from tbl_dict_tasksystype where col_code = v_tasktype;
      exception
      when NO_DATA_FOUND then
      v_taskTypeId := null;
      v_stateConfigId := null;
      when TOO_MANY_ROWS then
      v_taskTypeId := null;
      v_stateConfigId := null;
    end;
    --Calculate task state machine configuration
    if v_stateConfigId is null then
      begin
        select col_id into v_stateConfigId from tbl_dict_stateconfig where col_isdefault = 1 and lower(col_type) = 'task';
        exception
        when NO_DATA_FOUND then
          v_stateConfigId := null;
        when TOO_MANY_ROWS then
          v_stateConfigId := null;
      end;
    end if;
    --Calculate TaskStateInit target
    begin
      select col_id into v_taskstateinittargetid from tbl_map_taskstateinitiation where col_map_taskstateinittasktmpl =
      (select col_id from tbl_tasktemplate where col_id2 = v_targetid and col_proceduretasktemplate = v_procedureid)
      and col_map_tskstinit_tskst = (select col_id from tbl_dict_taskstate where col_activity = /*'root_TSK_Status_STARTED'*/
      (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isstart = 1)
      and nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0));
      exception
      when NO_DATA_FOUND then
      v_taskstateinittargetid := null;
      when TOO_MANY_ROWS then
      v_taskstateinittargetid := null;
    end;
    begin
      select col_id into v_taskstateinittrgtmplid from tbl_map_taskstateinittmpl where col_map_taskstinittpltasktpl =
      (select col_id from tbl_tasktemplate where col_id2 = v_targetid and col_proceduretasktemplate = v_procedureid)
      and col_map_tskstinittpl_tskst = (select col_id from tbl_dict_taskstate where col_activity =
      (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isstart = 1)
      and nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0));
      exception
      when NO_DATA_FOUND then
      v_taskstateinittrgtmplid := null;
      when TOO_MANY_ROWS then
      v_taskstateinittrgtmplid := null;
    end;
    if lower(rec.DependencyType) = 'and' then
      v_type := 'FSCA';
      v_processorcode := 'f_ECX_verifyResCodeANDMatch';
    elsif lower(rec.DependencyType) = 'inclusivegw' then
      v_type := 'FSCIN';
      v_processorcode := 'f_ECX_verifyResCodeINMatch';
    elsif lower(rec.DependencyType) = 'fsclr' and rec.ConditionType = 'rule' then
      v_type := 'FSCLR';
      v_processorcode := rec.RuleCode;
    elsif lower(rec.DependencyType) = 'fsclr' and rec.ResolutionCode is not null then
      v_type := 'FSCLR';
      v_processorcode := 'f_ECX_verifyResCodeMatch';
    elsif lower(rec.DependencyType) = 'fsclr' and rec.ResolutionCode is null then
      v_type := 'FSCLR';
      v_processorcode := null;
    elsif lower(rec.DependencyType) = 'fsc' then
      v_type := 'FSC';
      v_processorcode := null;
    end if;
    if v_taskstateinitsourceid is not null and v_taskstateinittargetid is not null then
      insert into tbl_taskdependency (col_id2, col_tskdpndprnttskstateinit, col_tskdpndchldtskstateinit, col_type, col_processorcode, col_code)
      values(v_elementid, v_taskstateinitsourceid, v_taskstateinittargetid, v_type, v_processorcode, sys_guid());
      select gen_tbl_taskdependency.currval into v_taskDependencyId from dual;
      if not(v_subtype in ('FSC', 'FSCLR') and v_resolutioncode is null) then
        insert into tbl_autoruleparameter (col_autoruleparamtaskdep, col_paramcode, col_paramvalue, col_code)
        values (v_taskDependencyId, 'ResolutionCode', v_resolutioncode, sys_guid());
      end if;
    end if;
    if v_taskstateinitsrctmplid is not null and v_taskstateinittrgtmplid is not null then
      insert into tbl_taskdependencytmpl (col_id2, col_taskdpprnttptaskstinittp, col_taskdpchldtptaskstinittp, col_type, col_processorcode, col_code)
      values(v_elementid, v_taskstateinitsrctmplid, v_taskstateinittrgtmplid, v_type, v_processorcode, sys_guid());
      select gen_tbl_taskdependencytmpl.currval into v_taskDependencyTmplId from dual;
      if not(v_subtype in ('FSC', 'FSCLR') and v_resolutioncode is null) then
        insert into tbl_autoruleparamtmpl (col_autoruleparamtptaskdeptp, col_paramcode, col_paramvalue, col_code)
        values (v_taskDependencyTmplId, 'ResolutionCode', v_resolutioncode, sys_guid());
      end if;
    end if;
    v_count := v_count + 1;
  end loop;
  --End of dependencies

  --Slas
  v_count := 1;
  for rec in (select col_elementid as ElementId, 
                     col_eventtask as EventTask, 
                     col_subtype as Subtype, 
                     /*col_eventtype as EventType, 
                     col_prioritycode as PriorityCode, col_priority as Priority,
                     col_resolutioncode as ResolutionCode, col_distributionchannel as DistributionChannel, col_fromrule as FromRule, col_torule as ToRule, col_ccrule as CcRule, col_bccrule as BccRule,
                     col_templaterule as TemplateRule, col_template as Template, col_attachmentrule as AttachmentRule, col_fromparam as FromParam, col_toparam as ToParam, col_cc as Cc, col_bcc as Bcc,
                     col_messagecode as MessageCode, col_channel as Channel, col_messageslack as MessageSlack, col_messagerule as MessageRule, col_executionmoment as ExecutionMoment, col_rulecode as RuleCode,
                     col_paramname as ParamName, col_paramvalue as ParamValue,*/ 
                     col_intervalym as IntervalYM, col_intervalds as IntervalDS, col_dateeventtype as DateEventType, 
                     col_parameters AS XMLParameters
                     /*VV: a new values add here please*/
              from tbl_processcache
              where col_type = 'sla'
              order by col_elementid)
  LOOP
    --use a XML instead a column's data and/or preserve a backward compatibility
    IF  rec.XMLParameters IS NOT NULL THEN
      v_XMLcount :=1;
     WHILE (TRUE)
      LOOP      
        v_XMLPathName  :='/Parameters/Parameter['||TO_CHAR(v_XMLcount)||']/@name';
        v_XMLPathValue :='/Parameters/Parameter['||TO_CHAR(v_XMLcount)||']/@value'; 
        v_XMLParamName  :=NULL;
        v_XMLParamValue :=NULL;
        
        v_XMLParamName := F_UTIL_EXTRACT_VALUE_XML(Input =>xmltype(rec.XMLParameters), Path =>v_XMLPathName);
        IF v_XMLParamName IS NULL THEN EXIT; END IF;
        v_XMLParamValue := F_UTIL_EXTRACT_VALUE_XML(xmltype(rec.XMLParameters), v_XMLPathValue);
        
        IF UPPER(v_XMLParamName)='SERVICETYPE' THEN rec.Subtype:=v_XMLParamValue; END IF;      
        IF UPPER(v_XMLParamName)='INTERVALYM' THEN rec.IntervalYM:=v_XMLParamValue; END IF;      
        IF UPPER(v_XMLParamName)='INTERVALDS' THEN rec.IntervalDS:=v_XMLParamValue; END IF;      
        IF UPPER(v_XMLParamName)='COUNT_FROM' THEN rec.DateEventType:=v_XMLParamValue; END IF;      
        
        v_XMLcount :=v_XMLcount+1;
      END LOOP;
    END IF; --eof use a XML

    v_eventtask := rec.EventTask;
    begin
      select col_id into v_taskTemplateId from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid and col_id2 = v_eventtask;
      exception
      when NO_DATA_FOUND then
      v_taskTemplateId := null;
      when TOO_MANY_ROWS then
      v_taskTemplateId := null;
    end;
    insert into tbl_slaevent(col_id2, col_slaeventtasktemplate, col_slaeventdict_slaeventtype, col_slaeventorder, col_slaevent_dateeventtype, col_intervalym, col_intervalds,
                             col_slaevent_slaeventlevel, col_attemptcount, col_maxattempts)
    values(rec.ElementId, v_taskTemplateId, (select col_id from tbl_dict_slaeventtype where lower(col_code) = lower(rec.Subtype)),
           (select nvl(max(col_slaeventorder),0) + 1 from tbl_slaevent where col_slaeventtasktemplate = v_taskTemplateId), (select col_id from tbl_dict_dateeventtype where col_code = rec.DateEventType), rec.IntervalYM, rec.IntervalDS,
           (select col_id from tbl_dict_slaeventlevel where col_code = 'BLOCKER'), 0, 1);
    insert into tbl_slaeventtmpl(col_id2, col_slaeventtptasktemplate, col_slaeventtp_slaeventtype, col_slaeventorder, col_slaeventtp_dateeventtype, col_intervalym, col_intervalds,
                             col_slaeventtp_slaeventlevel, col_attemptcount, col_maxattempts)
    values(rec.ElementId, v_taskTemplateId, (select col_id from tbl_dict_slaeventtype where lower(col_code) = lower(rec.Subtype)),
           (select nvl(max(col_slaeventorder),0) + 1 from tbl_slaevent where col_slaeventtasktemplate = v_taskTemplateId), (select col_id from tbl_dict_dateeventtype where col_code = rec.DateEventType), rec.IntervalYM, rec.IntervalDS,
           (select col_id from tbl_dict_slaeventlevel where col_code = 'BLOCKER'), 0, 1);
  end loop;
  --End Slas

  --Events
  v_count := 1;
  for rec in (SELECT col_elementid as ElementId, col_eventtask as EventTask, col_eventtype as EventType, 
             col_subtype as Subtype, col_prioritycode as PriorityCode, col_priority as Priority,
             col_resolutioncode as ResolutionCode, col_distributionchannel as DistributionChannel, 
             col_fromrule as FromRule, col_torule as ToRule, col_ccrule as CcRule, col_bccrule as BccRule,
             col_templaterule as TemplateRule, col_template as Template, 
             col_attachmentrule as AttachmentRule, col_fromparam as FromParam, col_toparam as ToParam, 
             col_cc as Cc, col_bcc as Bcc,
             col_messagecode as MessageCode, col_channel as Channel, col_messageslack as MessageSlack, 
             col_messagerule as MessageRule, col_participantcode as ParticipantCode, 
             col_workbasketrule as WorkbasketRule, col_executionmoment as ExecutionMoment, 
             col_rulecode as RuleCode, col_paramname as ParamName, col_paramvalue as ParamValue,
             col_category as Category, col_mediatype as MediaType, col_pagesend1 as PageSend1, 
             col_pagesend2 as PageSend2, col_pagesendparamsrule1 as PageSendParamsRule1, col_pagesendparamsrule2 as PageSendParamsRule2,
             col_customdatarule as CustomDataRule, col_name as Name, col_description as Description, 
             col_procedurecode as ProcedureCode, col_tasktypecode as TaskTypeCode, 
             col_inserttotask as InsertToTask, col_parameters AS XMLParameters
             /*VV: a new values add here please*/             
             FROM tbl_processcache 
             WHERE col_type = 'event'
             ORDER BY col_elementid)
  loop
    --use a XML instead a column's data and/or preserve a backward compatibility
    IF  rec.XMLParameters IS NOT NULL THEN
      v_XMLcount :=1;
     WHILE (TRUE)
      LOOP      
        v_XMLPathName  :='/Parameters/Parameter['||TO_CHAR(v_XMLcount)||']/@name';
        v_XMLPathValue :='/Parameters/Parameter['||TO_CHAR(v_XMLcount)||']/@value'; 
        v_XMLParamName  :=NULL;
        v_XMLParamValue :=NULL;
        
        v_XMLParamName := F_UTIL_EXTRACT_VALUE_XML(Input =>xmltype(rec.XMLParameters), Path =>v_XMLPathName);
        IF v_XMLParamName IS NULL THEN EXIT; END IF;
        v_XMLParamValue := F_UTIL_EXTRACT_VALUE_XML(xmltype(rec.XMLParameters), v_XMLPathValue);
        
        IF UPPER(v_XMLParamName)='INSERT_TO_TASK' THEN rec.InsertToTask:=TO_NUMBER(v_XMLParamValue); END IF;      
        IF UPPER(v_XMLParamName)='TASK_TYPE_CODE' THEN rec.TaskTypeCode:=v_XMLParamValue; END IF;      
        IF UPPER(v_XMLParamName)='PROCEDURE_CODE' THEN rec.ProcedureCode:=v_XMLParamValue; END IF;      
        IF UPPER(v_XMLParamName)='NAME' THEN rec.Name:=v_XMLParamValue; END IF;      
        IF UPPER(v_XMLParamName)='DESCRIPTION' THEN rec.Description:=v_XMLParamValue; END IF;        
        IF UPPER(v_XMLParamName)='CUSTOMDATARULE' THEN rec.CustomDataRule:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='PAGESENDPARAMSRULE2' THEN rec.PageSendParamsRule2:=v_XMLParamValue; END IF;       
        IF UPPER(v_XMLParamName)='PAGESENDPARAMSRULE1' THEN rec.PageSendParamsRule1:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='PAGESEND2' THEN rec.PageSend2:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='PAGESEND1' THEN rec.PageSend1:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='MEDIATYPE' THEN rec.MediaType:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='CATEGORY' THEN rec.Category:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='PARAMNAMES' THEN rec.ParamName:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='PARAMVALUES' THEN rec.ParamValue:=v_XMLParamValue; END IF;           
        IF UPPER(v_XMLParamName)='RULE_CODE' THEN rec.RuleCode:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='EXECUTION_MOMENT' THEN rec.ExecutionMoment:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='WORKBASKET_RULE' THEN rec.WorkbasketRule:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='PARTICIPANT_CODE' THEN rec.ParticipantCode:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='MESSAGE_RULE' THEN rec.MessageRule:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='MESSAGESLACK' THEN rec.MessageSlack:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='CHANNEL' THEN rec.Channel:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='MESSAGE_CODE' THEN rec.MessageCode:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='BCC' THEN rec.Bcc:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='CC' THEN rec.Cc:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='TO' THEN rec.ToParam:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='FROM' THEN rec.FromParam:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='ATTACHMENTS_RULE' THEN rec.AttachmentRule:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='TEMPLATE' THEN rec.Template:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='TEMPLATE_RULE' THEN rec.TemplateRule:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='BCC_RULE' THEN rec.BccRule:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='CC_RULE' THEN rec.CcRule:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='PRIORITY_CODE' THEN rec.PriorityCode:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='PRIORITY' THEN rec.Priority:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='RESOLUTION_CODE' THEN rec.ResolutionCode:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='DISTRIBUTIONCHANNEL' THEN rec.DistributionChannel:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='FROM_RULE' THEN rec.FromRule:=v_XMLParamValue; END IF;
        IF UPPER(v_XMLParamName)='TO_RULE' THEN rec.ToRule:=v_XMLParamValue; END IF;
        
        v_XMLcount :=v_XMLcount+1;
      END LOOP;
    END IF; --eof use a XML
    
    v_eventtask := rec.EventTask;
    begin
      select col_elementid, col_type into v_elementid, v_type
      from tbl_processcache
      where col_elementid = v_eventtask and col_type in ('task', 'sla');
      exception
      when NO_DATA_FOUND then
      v_elementid := null;
      v_type := null;
      when TOO_MANY_ROWS then
      v_elementid := null;
      v_type := null;
    end;
    if v_type = 'task' then
      begin
        select col_tasktypecode
        into v_tasktype
        from tbl_processcache
        where col_elementid = v_eventtask and col_type = 'task';
        exception
        when NO_DATA_FOUND then
        v_tasktype := null;
        when TOO_MANY_ROWS then
        v_tasktype := null;
      end;
      begin
        select col_id, col_stateconfigtasksystype into v_taskTypeId, v_stateConfigId from tbl_dict_tasksystype where col_code = v_tasktype;
        exception
        when NO_DATA_FOUND then
        v_taskTypeId := null;
        v_stateConfigId := null;
        when TOO_MANY_ROWS then
        v_taskTypeId := null;
        v_stateConfigId := null;
      end;
      --Calculate task state machine configuration
      if v_stateConfigId is null then
        begin
          select col_id into v_stateConfigId from tbl_dict_stateconfig where col_isdefault = 1 and lower(col_type) = 'task';
          exception
          when NO_DATA_FOUND then
            v_stateConfigId := null;
          when TOO_MANY_ROWS then
            v_stateConfigId := null;
        end;
      end if;
    end if;
    v_eventtype := rec.EventType;
    v_subtype := rec.Subtype;
    if v_eventtype = 'priority' then
      v_priority := rec.PriorityCode;
    elsif (v_eventtype = 'close' and v_subtype = 'closecase') or (v_eventtype = 'resolve' and v_subtype = 'resolvecase') then
      v_resolutioncode := rec.ResolutionCode;
    elsif v_eventtype = 'mail' and v_subtype = 'email' then
      v_distributionchannel := rec.DistributionChannel;
      v_fromrule := rec.FromRule;
      v_torule := rec.ToRule;
      v_ccrule := rec.CcRule;
      v_bccrule := rec.BccRule;
      v_templaterule := rec.TemplateRule;
      v_template := rec.Template;
      v_attachmentsrule := rec.AttachmentRule;
      v_from := rec.FromParam;
      v_to := rec.ToParam;
      v_cc := rec.Cc;
      v_bcc := rec.Bcc;
    elsif v_eventtype = 'history' and v_subtype = 'history' then
      v_messagecode := rec.MessageCode;
    elsif v_eventtype = 'assignTask' and v_subtype = 'assignTask' then
      v_participantcode := rec.ParticipantCode;
      v_workbasketrule := rec.WorkbasketRule;
    elsif v_eventtype = 'assignCase' and v_subtype = 'assignCase' then
      v_participantcode := rec.ParticipantCode;
      v_workbasketrule := rec.WorkbasketRule;
    elsif v_eventtype = 'togenesys' and v_subtype = 'integration_genesys' then
      v_channel := rec.Channel;
      v_priority := rec.Priority;
      v_category := rec.Category;
      v_mediatype := rec.MediaType;
      v_pagesend1 := rec.PageSend1;
      v_pagesend2 := rec.PageSend2;
      v_pagesendparamsrule1 := rec.PageSendParamsRule1;
      v_pagesendparamsrule2 := rec.PageSendParamsRule2;
      v_customdatarule := rec.CustomDataRule;
    elsif v_eventtype = 'slack' and v_subtype = 'integration_slack' then
      v_channel := rec.Channel;
      v_messageslack := rec.MessageSlack;
    elsif v_eventtype = 'messageTxt' and v_subtype = 'integration_twilio' then
      v_messagecode := rec.MessageCode;
      v_fromrule := rec.FromRule;
      v_torule := rec.ToRule;
      v_messagerule := rec.MessageRule;
      v_from := rec.FromParam;
      v_to := rec.ToParam;
    elsif v_eventtype = 'close_task' then
      v_resolutioncode := rec.ResolutionCode;
    elsif v_eventtype = 'inject_procedure' then
      v_name := rec.Name;
      v_description := rec.Description;
      v_procedurecode := rec.ProcedureCode;
      v_inserttotask := rec.InsertToTask;
    elsif v_eventtype = 'inject_tasktype' then
      v_name := rec.Name;
      v_description := rec.Description;
      v_tasktype := rec.TaskTypeCode;
      v_participantcode := rec.ParticipantCode;
      v_inserttotask := rec.InsertToTask;
    end if;
    v_executionMoment := rec.ExecutionMoment;
    v_ruleCode := rec.RuleCode;
    if v_type = 'task' then
      begin
        select col_id into v_taskstateinitiationid
        from tbl_map_taskstateinitiation
        where col_map_taskstateinittasktmpl = (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid and col_id2 = v_eventtask)
                         and col_map_tskstinit_tskst =
            (case when lower(v_executionMoment) = 'closed' then (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                                                                 and col_activity = /*'root_TSK_Status_CLOSED'*/
                                                                 (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isfinish = 1))
                  when lower(v_executionMoment) = 'start' then (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                                                                and col_activity = /*'root_TSK_Status_STARTED'*/
                                                                (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isstart = 1))
                  when lower(v_executionMoment) = 'in_progress' then (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                                                                      and col_activity = /*'root_TSK_Status_IN_PROCESS'*/
                                                                     (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isdefaultoncreate2 = 1))
                  when lower(v_executionMoment) = 'assigned' then (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                                                                   and col_activity = /*'root_TSK_Status_ASSIGNED'*/
                                                                   (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isassign = 1))
                  when lower(v_executionMoment) = 'resolved' then (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                                                                   and col_activity = /*'root_TSK_Status_RESOLVED'*/
                                                                   (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isresolve = 1))
                  else (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                        and col_activity = /*'root_TSK_Status_CLOSED'*/
                        (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isfinish = 1))
             end
            );
        exception
        when NO_DATA_FOUND then
        v_taskstateinitiationid := null;
        when TOO_MANY_ROWS then
        v_taskstateinitiationid := null;
      end;
      begin
        select col_id into v_taskstateinittmplid
        from tbl_map_taskstateinittmpl
        where col_map_taskstinittpltasktpl = (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid and col_id2 = v_eventtask)
                         and col_map_tskstinittpl_tskst =
            (case when lower(v_executionMoment) = 'closed' then (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                                                                 and col_activity = /*'root_TSK_Status_CLOSED'*/
                                                                 (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isfinish = 1))
                  when lower(v_executionMoment) = 'start' then (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                                                                and col_activity = /*'root_TSK_Status_STARTED'*/
                                                                (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isstart = 1))
                  when lower(v_executionMoment) = 'in_progress' then (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                                                                      and col_activity = /*'root_TSK_Status_IN_PROCESS'*/
                                                                     (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isdefaultoncreate2 = 1))
                  when lower(v_executionMoment) = 'assigned' then (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                                                                   and col_activity = /*'root_TSK_Status_ASSIGNED'*/
                                                                   (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isassign = 1))
                  when lower(v_executionMoment) = 'resolved' then (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                                                                   and col_activity = /*'root_TSK_Status_RESOLVED'*/
                                                                   (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isresolve = 1))
                  else (select col_id from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0)
                        and col_activity = /*'root_TSK_Status_CLOSED'*/
                        (select col_activity from tbl_dict_taskstate where nvl(col_stateconfigtaskstate,0) = nvl(v_stateConfigId,0) and col_isfinish = 1))
             end
            );
        exception
        when NO_DATA_FOUND then
        v_taskstateinittmplid := null;
        when TOO_MANY_ROWS then
        v_taskstateinittmplid := null;
      end;
      insert into tbl_taskevent(col_id2, col_code, col_taskeventtaskstateinit, col_processorcode, col_taskeventmomenttaskevent, col_taskeventtypetaskevent, col_taskeventorder)
      values(rec.ElementId, sys_guid(), v_taskstateinitiationid, v_ruleCode,
            (select col_id from tbl_dict_taskeventmoment where col_code = 'AFTER'),
            (select col_id from tbl_dict_taskeventtype where col_code = 'ACTION'),
            (select nvl(max(col_taskeventorder), 0) + 1 from tbl_taskevent where col_taskeventtaskstateinit = v_taskstateinitiationid));
      select gen_tbl_taskevent.currval into v_taskEventId from dual;
      insert into tbl_taskeventtmpl(col_id2, col_code, col_taskeventtptaskstinittp, col_processorcode, col_taskeventmomnttaskeventtp, col_taskeventtypetaskeventtp, col_taskeventorder)
      values(rec.ElementId, sys_guid(), v_taskstateinittmplid, v_ruleCode,
            (select col_id from tbl_dict_taskeventmoment where col_code = 'AFTER'),
            (select col_id from tbl_dict_taskeventtype where col_code = 'ACTION'),
            (select nvl(max(col_taskeventorder), 0) + 1 from tbl_taskeventtmpl where col_taskeventtptaskstinittp = v_taskstateinittmplid));
      select gen_tbl_taskeventtmpl.currval into v_taskEventTmplId from dual;
      if v_eventtype = 'rule' and rec.ParamName is not null and rec.ParamValue is not null then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        if rec.ParamName is not null then
          for rec2 in (select s1.ParamName as ParamName, s2.ParamValue as ParamValue
                       from
                       (select column_value as ParamName, rownum as RowNumber from table(asf_splitclob(rec.ParamName,','))) s1
                        inner join
                       (select column_value as ParamValue, rownum as RowNumber from table(asf_splitclob(rec.ParamValue,','))) s2 on s1.RowNumber = s2.RowNumber)
          loop
            insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
            values(sys_guid(), v_taskEventId, v_taskstateinitiationid, rec2.ParamName, rec2.ParamValue);
            insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
            values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, rec2.ParamName, rec2.ParamValue);
          end loop;
        end if;
      elsif v_eventtype = 'priority' and v_priority is not null then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'priority', v_priority);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'priority', v_priority);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif (v_eventtype = 'close' and v_subtype = 'closecase') or (v_eventtype = 'resolve' and v_subtype = 'resolvecase') then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ResolutionCode', v_resolutioncode);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ResolutionCode', v_resolutioncode);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'mail' and v_subtype = 'email' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'DistributionChannel', v_distributionchannel);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'FromRule', v_fromrule);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ToRule', v_torule);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'CcRule', v_ccrule);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'BccRule', v_bccrule);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'TemplateRule', v_templaterule);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Template', v_template);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'AttachmentsRule', v_attachmentsrule);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'From', v_from);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'To', v_to);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Cc', v_cc);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Bcc', v_bcc);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'DistributionChannel', v_distributionchannel);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'FromRule', v_fromrule);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ToRule', v_torule);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'CcRule', v_ccrule);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'BccRule', v_bccrule);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'TemplateRule', v_templaterule);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Template', v_template);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'AttachmentsRule', v_attachmentsrule);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'From', v_from);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'To', v_to);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Cc', v_cc);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Bcc', v_bcc);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'history' and v_subtype = 'history' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'MessageCode', v_messagecode);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'MessageCode', v_messagecode);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'assignTask' and v_subtype = 'assignTask' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ParticipantCode', v_participantcode);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'WorkbasketRule', v_workbasketrule);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ParticipantCode', v_participantcode);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'WorkbasketRule', v_workbasketrule);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'assignCase' and v_subtype = 'assignCase' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ParticipantCode', v_participantcode);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'WorkbasketRule', v_workbasketrule);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ParticipantCode', v_participantcode);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'WorkbasketRule', v_workbasketrule);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'togenesys' and v_subtype = 'integration_genesys' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Channel', v_channel);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'priority', v_priority);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Category', v_category);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'MediaType', v_mediatype);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'PageSend1', v_pagesend1);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'PageSend2', v_pagesend2);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'PageSendParamsRule1', v_pagesendparamsrule1);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'PageSendParamsRule2', v_pagesendparamsrule2);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'CustomDataRule', v_customdatarule);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Channel', v_channel);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'priority', v_priority);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Category', v_category);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'MediaType', v_mediatype);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'PageSend1', v_pagesend1);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'PageSend2', v_pagesend2);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'PageSendParamsRule1', v_pagesendparamsrule1);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'PageSendParamsRule2', v_pagesendparamsrule2);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'CustomDataRule', v_customdatarule);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'slack' and v_subtype = 'integration_slack' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Channel', v_channel);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'MessageSlack', v_messageslack);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Channel', v_channel);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'MessageSlack', v_messageslack);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'messageTxt' and v_subtype = 'integration_twilio' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'MessageCode', v_messagecode);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'FromRule', v_fromrule);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ToRule', v_torule);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'MessageRule', v_messagerule);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'From', v_from);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'To', v_to);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'MessageCode', v_messagecode);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'FromRule', v_fromrule);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ToRule', v_torule);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'MessageRule', v_messagerule);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'From', v_from);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'To', v_to);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'case_in_process' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'case_new_state' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'close_task' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ResolutionCode', v_resolutioncode);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ResolutionCode', v_resolutioncode);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'task_in_process' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'task_new_state' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'inject_procedure' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Name', v_name);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Description', v_description);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ProcedureCode', v_procedurecode);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'InsertToTask', v_inserttotask);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Name', v_name);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Description', v_description);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ProcedureCode', v_procedurecode);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'InsertToTask', v_inserttotask);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      elsif v_eventtype = 'inject_tasktype' then
        select gen_tbl_taskevent.currval into v_taskEventId from dual;
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Name', v_name);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'Description', v_description);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'TaskTypeCode', v_tasktype);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'ParticipantCode', v_participantcode);
        insert into tbl_autoruleparameter(col_code, col_taskeventautoruleparam, col_ruleparam_taskstateinit, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventId, v_taskstateinitiationid, 'InsertToTask', v_inserttotask);
        update tbl_taskevent set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Name', v_name);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'Description', v_description);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'TaskTypeCode', v_tasktype);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'ParticipantCode', v_participantcode);
        insert into tbl_autoruleparamtmpl(col_code, col_taskeventtpautoruleparmtp, col_rulepartp_taskstateinittp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_taskEventTmplId, v_taskstateinittmplid, 'InsertToTask', v_inserttotask);
        update tbl_taskeventtmpl set col_processorcode = v_ruleCode where col_id = v_taskEventTmplId;
      end if;
    end if;
    if v_type = 'sla' then
      begin
        select col_id into v_slaeventid from tbl_slaevent where col_id2 = v_eventtask and col_slaeventtasktemplate in (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid);
        exception
        when NO_DATA_FOUND then
        v_slaeventid := null;
        when TOO_MANY_ROWS then
        v_slaeventid := null;
      end;
      begin
        select col_id into v_slaeventtmplid from tbl_slaeventtmpl where col_id2 = v_eventtask and col_slaeventtptasktemplate in (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid);
        exception
        when NO_DATA_FOUND then
        v_slaeventtmplid := null;
        when TOO_MANY_ROWS then
        v_slaeventtmplid := null;
      end;
      insert into tbl_slaaction(col_code, col_slaactionslaevent, col_processorcode, col_slaaction_slaeventlevel, col_actionorder)
      values(sys_guid(), v_slaeventid, v_ruleCode,
             null,
             (select nvl(max(col_actionorder), 0) + 1 from tbl_slaaction where col_slaactionslaevent = v_slaeventid));
      select gen_tbl_slaaction.currval into v_slaActionId from dual;
      insert into tbl_slaactiontmpl(col_code, col_slaactiontpslaeventtp, col_processorcode, col_slaactiontp_slaeventlevel, col_actionorder)
      values(sys_guid(), v_slaeventtmplid, v_ruleCode,
             null,
             (select nvl(max(col_actionorder), 0) + 1 from tbl_slaactiontmpl where col_slaactiontpslaeventtp = v_slaeventtmplid));
      select gen_tbl_slaactiontmpl.currval into v_slaActionTmplId from dual;
      if v_eventtype = 'rule' and rec.ParamName is not null and rec.ParamValue is not null then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        if rec.ParamName is not null then
          for rec2 in (select s1.ParamName as ParamName, s2.ParamValue as ParamValue
                       from
                       (select column_value as ParamName, rownum as RowNumber from table(asf_splitclob(rec.ParamName,','))) s1
                        inner join
                       (select column_value as ParamValue, rownum as RowNumber from table(asf_splitclob(rec.ParamValue,','))) s2 on s1.RowNumber = s2.RowNumber)
          loop
            insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
            values(sys_guid(), v_slaActionId, rec2.ParamName, rec2.ParamValue);
            insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
            values(sys_guid(), v_slaActionTmplId, rec2.ParamName, rec2.ParamValue);
          end loop;
        end if;
      elsif v_eventtype = 'priority' and v_priority is not null then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'priority', v_priority);
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'priority', v_priority);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif (v_eventtype = 'close' and v_subtype = 'closecase') or (v_eventtype = 'resolve' and v_subtype = 'resolvecase') then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'ResolutionCode', v_resolutioncode);
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_taskEventId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'ResolutionCode', v_resolutioncode);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'mail' and v_subtype = 'email' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'DistributionChannel', v_distributionchannel);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'FromRule', v_fromrule);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'ToRule', v_torule);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'CcRule', v_ccrule);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'BccRule', v_bccrule);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'TemplateRule', v_templaterule);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'Template', v_template);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'AttachmentsRule', v_attachmentsrule);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'From', v_from);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'To', v_to);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'Cc', v_cc);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'Bcc', v_bcc);
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'DistributionChannel', v_distributionchannel);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'FromRule', v_fromrule);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'ToRule', v_torule);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'CcRule', v_ccrule);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'BccRule', v_bccrule);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'TemplateRule', v_templaterule);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'Template', v_template);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'AttachmentsRule', v_attachmentsrule);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'From', v_from);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'To', v_to);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'Cc', v_cc);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'Bcc', v_bcc);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'history' and v_subtype = 'history' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'MessageCode', v_messagecode);
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'MessageCode', v_messagecode);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'togenesys' and v_subtype = 'integration_genesys' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'Channel', v_channel);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'priority', v_priority);
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'Channel', v_channel);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'priority', v_priority);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'slack' and v_subtype = 'integration_slack' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'Channel', v_channel);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'MessageSlack', v_messageslack);
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'Channel', v_channel);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'MessageSlack', v_messageslack);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'messageTxt' and v_subtype = 'integration_twilio' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'MessageCode', v_messagecode);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'FromRule', v_fromrule);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'ToRule', v_torule);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'MessageRule', v_messagerule);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'From', v_from);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'To', v_to);
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'MessageCode', v_messagecode);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'FromRule', v_fromrule);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'ToRule', v_torule);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'MessageRule', v_messagerule);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'From', v_from);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'To', v_to);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'case_in_process' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'case_new_state' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'close_task' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'ResolutionCode', v_resolutioncode);
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'ResolutionCode', v_resolutioncode);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'task_in_process' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'task_new_state' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'inject_procedure' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'Name', v_name);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'Description', v_description);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'ProcedureCode', v_procedurecode);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'InsertToTask', v_inserttotask);
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'Name', v_name);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'Description', v_description);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'ProcedureCode', v_procedurecode);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'InsertToTask', v_inserttotask);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      elsif v_eventtype = 'inject_tasktype' then
        select gen_tbl_slaaction.currval into v_slaActionId from dual;
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'Name', v_name);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'Description', v_description);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'TaskTypeCode', v_tasktype);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'ParticipantCode', v_participantcode);
        insert into tbl_autoruleparameter(col_code, col_autoruleparamslaaction, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionId, 'InsertToTask', v_inserttotask);
        update tbl_slaaction set col_processorcode = v_ruleCode where col_id = v_slaActionId;
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'Name', v_name);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'Description', v_description);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'TaskTypeCode', v_tasktype);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'ParticipantCode', v_participantcode);
        insert into tbl_autoruleparamtmpl(col_code, col_autorulepartpslaactiontp, col_paramcode, col_paramvalue)
        values(sys_guid(), v_slaActionTmplId, 'InsertToTask', v_inserttotask);
        update tbl_slaactiontmpl set col_processorcode = v_ruleCode where col_id = v_slaActionTmplId;
      end if;
    end if;
    v_count := v_count + 1;
  end loop;
  --End of events

return 0;

end;