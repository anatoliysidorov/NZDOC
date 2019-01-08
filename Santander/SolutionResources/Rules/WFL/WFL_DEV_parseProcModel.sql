declare
  v_input xmltype;
  v_output varchar2(32767);
  v_count Integer;
  v_count1 Integer;
  v_result nvarchar2(255);
  v_result2 nvarchar2(255);
  v_result3 nvarchar2(255);
  v_result4 number;
  v_id Integer;
  v_sourceid Integer;
  v_targetid Integer;
  v_name nvarchar2(255);
  v_description nclob;
  v_executiontypecode nvarchar2(255);
  v_executiontype nvarchar2(255);
  v_eventtype nvarchar2(255);
  v_type nvarchar2(255);
  v_subtype nvarchar2(255);
  v_dependencytype nvarchar2(255);
  v_dateeventtype nvarchar2(255);
  v_participantcode nvarchar2(255);
  v_connid Integer;
  v_connsourceid Integer;
  v_conntargetid Integer;
  v_connissource Integer;
  v_connistarget Integer;
  v_conngwtype nvarchar2(255);
  v_connelementid Integer;
  v_incomingcount Integer;
  v_gwelementid Integer;
  v_AdjDependencyId Integer;
  v_ResolutionCode nvarchar2(255);
  v_SourceElementId Integer;
  v_SourceElementName nvarchar2(255);
  v_SourceElementType nvarchar2(255);
  v_TargetElementId Integer;
  v_TargetElementName nvarchar2(255);
  v_TargetElementType nvarchar2(255);
  v_HierarchyLevel Integer;
  v_RowNumber Integer;
  v_RuleCode nvarchar2(255);
  v_AssignRuleCode nvarchar2(255);
  v_paramname nclob;  
  v_paramname1 nclob; 
  v_paramvalue nclob; 
  v_paramNamesCollectionFound INTEGER;
  v_intervalym nvarchar2(255);
  v_intervalds nvarchar2(255);
  v_channel nvarchar2(255);
  v_PageSend1 nvarchar2(255);
  v_PageSend2 nvarchar2(255);
  v_tasktypecode nvarchar2(255);
  v_XMLParameters NVARCHAR2(4000);  
  v_path nvarchar2(255);
begin
  v_input := xmltype(Input);
  delete from tbl_processcache;
  v_count := 1;  
  while (true)
  loop
    v_XMLParameters :=NULL;    
    v_result :=  f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@id');
    if v_result is null then
      exit;
    end if;
    begin
      v_id := to_number(v_result);
      exception
      when VALUE_ERROR then
      v_count := v_count + 1;
      continue;
    end;
    v_type := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@type');
    if v_type = 'connection' then
      v_type := 'dependency';
    end if;
    if v_type = 'service' then
      v_type := 'sla';
    end if;
    v_paramname := null;
    v_paramvalue := null;
    v_paramname1 := null;    
    v_name := null;
    v_intervalym := null;
    v_intervalds := null;
    if v_type = 'root' then
      v_name := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@name');
    elsif v_type = 'task' then
      v_name := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@name');
    elsif v_type = 'gateway' then
      v_name := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@name');
    elsif v_type = 'event' then      
      v_name := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@NAME');     

      --get /Object/Object parameters collection  
      v_paramname := NULL;
      v_paramvalue := NULL;
      v_paramname := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/Object/@paramNames');    
      if v_paramname is not null THEN
        for rec in (select column_value as ParamName from table(asf_splitclob(v_paramname,',')))
        LOOP          
          if v_paramvalue is null then
            v_paramvalue := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/Object/@' || rec.ParamName);
          else
            v_paramvalue := v_paramvalue || ',' || f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/Object/@' || rec.ParamName);
          end if;          
        end loop;          
      end if;


      --get global Object for XML collection      
      v_path:='/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object';
      IF  v_input.existsnode(v_path) = 1 THEN
        v_paramname1 := substr(v_input.extract(v_path).getStringval(), 1, 32767);
      ELSE
        v_paramname1 := NULL;
      END IF;
            
      v_XMLParameters :='<Parameters>'; 
      v_paramNamesCollectionFound :=NULL;
      if v_paramname1 is not null THEN             
        for recXML IN (SELECT dbms_lob.substr(substr1, 4000, 1 ) AS substr2 FROM
            (
            SELECT REGEXP_SUBSTR(str1, '\w+=\"[^\"]+\"', 1, LEVEL) AS substr1
            FROM (SELECT v_paramname1 AS str1 FROM DUAL)
            CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(str1, '\w+=\"[^\"]+\"')) + 1
            )
            WHERE substr1 IS NOT NULL
        )LOOP                        
            IF  recXML.substr2 IS NOT NULL  OR recXML.substr2<>'' THEN
              IF SUBSTR(recXML.substr2, 1, INSTR(recXML.substr2, '=', 1)-1)='paramNames' THEN
                v_paramNamesCollectionFound:=1;
              END IF;
             
              --do mark a "already exists in collection" (exists inside a v_paramvalue) parameter as !_ || recXML.substr2 
              IF (v_paramname IS NOT NULL) AND (v_paramNamesCollectionFound=1) THEN
                FOR recCheck IN (SELECT column_value as ParamName FROM TABLE(asf_splitclob(v_paramname,',')))
                LOOP 
                  IF SUBSTR(recXML.substr2, 1, INSTR(recXML.substr2, '=', 1)-1)=recCheck.ParamName THEN
                    recXML.substr2:='!_'||recXML.substr2;
                  END IF;
                END LOOP;
              END IF; 
              v_XMLParameters:=v_XMLParameters||'<Parameter name="';
              v_XMLParameters:=v_XMLParameters||REGEXP_REPLACE(recXML.substr2, '=', '" value=',1,1);
              v_XMLParameters:=v_XMLParameters||'/> ';
            END IF;            
         END LOOP;  
         IF v_paramname IS NOT NULL THEN 
          v_XMLParameters:=v_XMLParameters||'<Parameter name="paramValues" value="'||v_paramvalue||'"/> ';              
         END IF;
      end if;
      v_XMLParameters:=v_XMLParameters||'</Parameters>';

      v_channel := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@channel');
      if v_channel is null then
        v_channel := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@Channel');
      end if;--events

      
    ELSIF v_type = 'sla' THEN
      v_intervalym := '00-' || nvl(f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@MONTHS'),'00');
      v_intervalds := nvl(f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@DAYS'),'00') || ' ' ||
                      nvl(f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@HOURS'),'00') || ':' ||
                      nvl(f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@MINUTES'),'00') || ':' ||
                      nvl(f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@SECONDS'),'00');

      v_XMLParameters :='<Parameters>'; 
      IF v_intervalym IS NOT NULL THEN 
       v_XMLParameters:=v_XMLParameters||'<Parameter name="IntervalYM" value="'||v_intervalym||'"/> ';              
      END IF;

      IF v_intervalds IS NOT NULL THEN 
       v_XMLParameters:=v_XMLParameters||'<Parameter name="IntervalDS" value="'||v_intervalds||'"/> ';              
      END IF;
      
      --get global Object for XML collection            
      v_path:='/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object';
      IF  v_input.existsnode(v_path) = 1 THEN
        v_paramname1 := substr(v_input.extract(v_path).getStringval(), 1, 32767);
      ELSE
        v_paramname1 := NULL;
      END IF;            
      
      IF v_paramname1 is not null THEN             
        for recXML IN (SELECT dbms_lob.substr(substr1, 4000, 1 ) AS substr2 FROM
            (
            SELECT REGEXP_SUBSTR(str1, '\w+=\"[^\"]+\"', 1, LEVEL) AS substr1
            FROM (SELECT v_paramname1 AS str1 FROM DUAL)
            CONNECT BY LEVEL <= LENGTH(REGEXP_REPLACE(str1, '\w+=\"[^\"]+\"')) + 1
            )
            WHERE substr1 IS NOT NULL
        )LOOP                        
            IF  recXML.substr2 IS NOT NULL  OR recXML.substr2<>'' THEN 
              v_XMLParameters:=v_XMLParameters||'<Parameter name="';
              v_XMLParameters:=v_XMLParameters||REGEXP_REPLACE(recXML.substr2, '=', '" value=',1,1);
              v_XMLParameters:=v_XMLParameters||'/> ';
            END IF;            
         END LOOP;  
      END IF;      
                
      v_XMLParameters:=v_XMLParameters||'</Parameters>';            
    END IF;--sla
    
    v_executiontypecode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@execution_type_code');
    v_executiontype := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@executionType');
    
    if v_type = 'task' then
      v_executiontype := v_executiontypecode;
    end if;
    v_dependencytype := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@dependency_type');
    v_eventtype := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@eventType');
    if v_type = 'sla' then
      v_subtype := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@serviceType');
      v_dateeventtype := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@COUNT_FROM');
    else
      v_subtype := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@subtype');
      v_dateeventtype := null;
    end if;
    v_RuleCode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@rule_code');
    v_AssignRuleCode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@AUTO_ASSIGN');
    if (v_eventtype = 'priority' or (v_eventtype = 'close' and v_subtype = 'closecase')
                                 or (v_eventtype = 'resolve' and v_subtype = 'resolvecase')
                                 or (lower(v_eventtype) = 'assigntask' and lower(v_subtype) = 'assigntask')
                                 or (lower(v_eventtype) = 'assigncase' and lower(v_subtype) = 'assigncase')
                                 or (v_eventtype = 'mail' and v_subtype = 'email')
                                 or (v_eventtype = 'history' and v_subtype = 'history')
                                 or (v_eventtype = 'togenesys' and v_subtype = 'integration_genesys')
                                 or (v_eventtype = 'slack' and v_subtype = 'integration_slack')
                                 or (v_eventtype = 'messageTxt' and v_subtype = 'integration_twilio')
                                 or v_eventtype = 'case_in_process'
                                 or v_eventtype = 'case_new_state'
                                 or v_eventtype = 'close_task'
                                 or v_eventtype = 'task_in_process'
                                 or v_eventtype = 'task_new_state'
                                 or v_eventtype = 'inject_procedure'
                                 or v_eventtype = 'inject_tasktype'
       ) and v_RuleCode is null then
      begin
        select col_processorcode into v_RuleCode from tbl_dict_actiontype where lower(col_code) = lower(v_eventtype);
        exception
        when NO_DATA_FOUND then
        v_RuleCode := null;
      end;
    end if;
    if v_eventtype = 'togenesys' and v_subtype = 'integration_genesys' then
      v_PageSend1 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PageSend1');
      v_PageSend2 := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PageSend2');
      if v_PageSend1 is null and v_PageSend2 is not null then
        v_PageSend1 := v_PageSend2;
      end if;
    end if;
    v_description := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@description');
    if v_description is null then
      v_description := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@DESCRIPTION');
    end if;
    v_participantcode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PARTICIPANT_CODE');
    if v_participantcode is null then
      v_participantcode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PARTICIPANT');
    end if;
    v_tasktypecode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@task_type_code');
    if v_tasktypecode is null then
      v_tasktypecode := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@TASKTYPE');
    end if;
    insert into tbl_processcache(col_elementid,col_type,col_subtype,col_procedureid,col_name,col_code,col_value,col_tasktypecode,col_executiontypecode,col_description,col_inputsubtype,col_outputsubtype,
    col_executiontype,col_source,col_target,col_fromrule,col_fromparam,col_torule,col_toparam,col_templaterule,col_template,col_rulecode,col_autoassignrule,col_resolutioncode,col_prioritycode,col_priority,
    col_messageslack,col_messagerule,col_messagecode,col_executionmoment,col_eventtype,col_distributionchannel,col_dependencytype,col_conditiontype,col_channel,
    col_ccrule,col_cc,col_bccrule,col_bcc,col_attachmentrule,col_participantcode,col_workbasketrule,col_paramname,col_paramvalue,col_intervalym,col_intervalds,col_dateeventtype,
    col_category,col_mediatype,col_pagesend1,col_pagesend2,col_pagesendparamsrule1,col_pagesendparamsrule2,col_customdatarule,col_procedurecode,col_inserttotask,col_defaultstate,
    col_parameters)
    values(v_id,
           v_type,
           v_subtype,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@PROCEDURE_ID'),
           v_name,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@code'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@value'),
           v_tasktypecode,
           v_executiontypecode,
           v_description,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@inputSubType'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@outputSubType'),
           v_executiontype,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@source'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/@target'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@FROM_RULE'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@FROM'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@TO_RULE'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@TO'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@TEMPLATE_RULE'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@TEMPLATE'),
           v_RuleCode,
           v_AssignRuleCode,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@RESOLUTION_CODE'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PRIORITY_CODE'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@priority'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@messageSlack'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@MESSAGE_RULE'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@MESSAGE_CODE'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@execution_moment'),
           v_eventtype,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@DistributionChannel'),
           v_dependencytype,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@condition_type'),
           v_channel,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@CC_RULE'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@CC'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@BCC_RULE'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@BCC'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@ATTACHMENTS_RULE'),
           v_participantcode,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@WORKBASKET_RULE'),
           v_paramname,
           v_paramvalue,
           v_intervalym,
           v_intervalds,
           v_dateeventtype,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@Category'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@MediaType'),
           v_PageSend1,
           v_PageSend2,
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PageSendParamsRule1'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PageSendParamsRule2'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@CustomDataRule'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@PROCEDURE_CODE'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@INSERT_TO_TASK'),
           f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/@DEFAULTSTATE'),
           v_XMLParameters
           );
    if v_type = 'gateway' then
      begin
        select count(*) as IncomingCount, pc.col_elementid as GatewayId
        into v_incomingcount, v_gwelementid
        from tbl_processcache pc
        inner join tbl_processcache pc2 on pc.col_elementid = pc2.col_target
        where pc.col_type = 'gateway'
        and pc.col_elementid = v_id
        group by pc.col_elementid;
        exception
        when NO_DATA_FOUND then
        v_incomingcount := 1;
        v_gwelementid := v_id;
      end;
      if v_incomingcount = 1 then
        update tbl_processcache
        set col_istask = 0
        where col_elementid = v_id;
      elsif v_incomingcount > 1 then
        update tbl_processcache
        set col_istask = 1
        where col_elementid = v_id;
      end if;
    end if;
    if v_type = 'dependency' then
      v_count1 := 1;
      v_ResolutionCode := null;
      while (true)
      loop
        v_result := f_UTIL_extract_value_xml(Input => v_input, Path => '/mxGraphModel/root/mxCell[' || to_char(v_count) || ']/Object/Array/add[' || to_char(v_count1) || ']/@value');
        if v_result is null then
          exit;
        end if;
        if v_ResolutionCode is null then
          v_ResolutionCode := v_result;
        else
          v_ResolutionCode := v_ResolutionCode || ',' || v_result;
        end if;
        v_count1 := v_count1 + 1;
      end loop;
      if v_dependencytype is null then
        begin
          select s.Id, s.ElementId, s.SourceId, s.TargetId, s.IsSource, s.IsTarget, s.GWType
          into v_connid, v_connelementid, v_connsourceid, v_conntargetid, v_connissource, v_connistarget, v_conngwtype
          from
          (select pc.col_id as Id, pc.col_elementid as ElementId, pc.col_source as SourceId, pc.col_target as TargetId, 1 as IsSource, 0 as IsTarget, pc2.col_outputsubtype as GWType
          from tbl_processcache pc
          inner join tbl_processcache pc2 on pc2.col_elementid = pc.col_source and pc2.col_type = 'gateway'
          where pc.col_elementid = v_id
          and pc.col_type = 'dependency'
          union
          select pc.col_id as Id, pc.col_elementid as ElementId, pc.col_source as SourceId, pc.col_target as TargetId, 0 as IsSource, 1 as IsTarget, pc2.col_inputsubtype as GWType
          from tbl_processcache pc
          inner join tbl_processcache pc2 on pc2.col_elementid = pc.col_target and pc2.col_type = 'gateway'
          where pc.col_elementid = v_id
          and pc.col_type = 'dependency'
          ) s;
          exception
          when NO_DATA_FOUND then
          v_conngwtype := null;
        end;
        v_dependencytype := v_conngwtype;
      end if;
      update tbl_processcache
      set col_resolutioncode = v_ResolutionCode,
      col_dependencytype = v_dependencytype
      where col_elementid = v_id;
    end if;
    v_count := v_count + 1;
  end loop;
  for rec in (select pc.col_elementid as ElementId, pc2.col_type as SourceType from tbl_processcache pc
              inner join tbl_processcache pc2 on pc.col_source = pc2.col_elementid
              where pc.col_type = 'gateway')
  loop
    begin
      select count(*) as IncomingCount, pc.col_elementid as GatewayId
      into v_incomingcount, v_gwelementid
      from tbl_processcache pc
      inner join tbl_processcache pc2 on pc.col_elementid = pc2.col_target
      where pc.col_type = 'gateway'
      and pc.col_elementid = v_id
      group by pc.col_elementid;
      exception
      when NO_DATA_FOUND then
      v_incomingcount := 1;
      v_gwelementid := v_id;
    end;
    if v_incomingcount = 1 then
      update tbl_processcache
      set col_istask = 0
      where col_elementid = v_id;
    elsif v_incomingcount > 1 then
      update tbl_processcache
      set col_istask = 1
      where col_elementid = v_id;
    end if;
  end loop;
  for rec in (select pc.col_elementid as ElementId, pc2.col_type as SourceType from tbl_processcache pc
              inner join tbl_processcache pc2 on pc.col_source = pc2.col_elementid
              where pc.col_type = 'dependency')
  loop
    if rec.SourceType = 'task' then
      v_SourceElementId := 0;
    elsif rec.SourceType <> 'task' and rec.SourceType <> 'gateway' then
      v_SourceElementId := 0;
    else
      begin
        for rec2 in
        (
        select AdjDependencyId, ResolutionCode, SourceElementId, SourceElementName, SourceElementType, TargetElementId, TargetElementName, TargetElementType, HierarchyLevel, RowNumber
        from
        (select s2.AdjDependencyId, s2.ResolutionCode,
        s2.SourceElementId, s2.SourceElementName, s2.SourceElementType, s2.TargetElementId, s2.TargetElementName, s2.TargetElementType, s2.HierarchyLevel, row_number() over (order by HierarchyLevel asc) as RowNumber
        from
        (select s1.AdjDependencyId, s1.ResolutionCode,
        s1.SourceElementId, s1.SourceElementName, s1.SourceElementType, s1.TargetElementId, s1.TargetElementName, s1.TargetElementType, level as HierarchyLevel
        from
        (select  pc.col_elementid as AdjDependencyId, pc.col_resolutioncode as ResolutionCode,
        pc2.col_elementid as SourceElementId, pc2.col_name as SourceElementName, pc2.col_type as SourceElementType,
        pc3.col_elementid as TargetElementId, pc3.col_name as TargetElementName, pc3.col_type as TargetElementType
        from tbl_processcache pc
        inner join tbl_processcache pc2 on pc.col_source = pc2.col_elementid and pc2.col_type in ('task','gateway')
        inner join tbl_processcache pc3 on pc.col_target = pc3.col_elementid and pc3.col_type in ('task','gateway')
        where pc.col_type = 'dependency') s1
        connect by prior s1.SourceElementId = s1.TargetElementId and s1.SourceElementType = 'task'
        start with s1.AdjDependencyId = rec.ElementId) s2)
        order by RowNumber
        )
        loop
        if rec2.SourceElementType = 'task' then
          v_SourceElementId := rec2.SourceElementId;
          exit;
        end if;
        end loop;
      end;
        update tbl_processcache
        set col_source2 = v_SourceElementId
        where col_elementid = rec.ElementId;
    end if;
  end loop;
  for rec in (select col_elementid as ElementId from tbl_processcache where col_type in ('event', 'sla'))
  loop
    v_id := null;
    begin
      select pc.col_target
      into v_id
      from tbl_processcache pc
      inner join tbl_processcache pc2 on pc.col_target = pc2.col_elementid
      where pc.col_type = 'eventConnection'
      and pc.col_source = rec.ElementId
      and pc2.col_type in ('task', 'sla');
      exception
      when NO_DATA_FOUND then
      v_id := null;
      when TOO_MANY_ROWS then
      v_id := null;
    end;
    if v_id is null then
      begin
        select pc.col_source
        into v_id
        from tbl_processcache pc
        inner join tbl_processcache pc2 on pc.col_source = pc2.col_elementid
        where pc.col_type = 'eventConnection'
        and pc.col_target = rec.ElementId
        and pc2.col_type in ('task', 'sla');
        exception
        when NO_DATA_FOUND then
        v_id := null;
        when TOO_MANY_ROWS then
        v_id := null;
      end;
    end if;
    if v_id is not null then
      update tbl_processcache set col_eventtask = v_id where col_elementid = rec.ElementId;
    end if;
  end loop;

  return null;

end;