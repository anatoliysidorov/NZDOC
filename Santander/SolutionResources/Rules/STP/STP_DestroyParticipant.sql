DECLARE
  v_id    NUMBER;
  v_count NUMBER;

  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);
  v_caseTypeId NUMBER;
  v_procedureId NUMBER;
  v_participantCode NVARCHAR2(255); 
BEGIN
  v_id := :Id;

  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';
  v_caseTypeId := null;
  v_procedureId := null;
  v_count := 0;

  --Input params check 
  IF v_id IS NULL THEN
    v_errormessage := 'Id can not be empty';
    v_errorcode    := 101;
    GOTO cleanup;
  END IF;

  begin
    select 
      col_participantcasesystype, col_code, col_participantprocedure into 
      v_caseTypeId, v_participantCode, v_procedureId 
    from tbl_participant where  col_id = v_id;
  exception
    when no_data_found then
      v_caseTypeId := null;
      v_participantCode := null;
      v_procedureId := null;
  end;

  if nvl(v_caseTypeId, 0) <> 0 then

      -- Events that are linked with milestone
      select count(*) into v_count 
      from tbl_autoruleparamtmpl arp
      inner join tbl_dict_stateevent se on arp.col_autorulepartmplstateevent = se.col_id
      inner join tbl_dict_state st on se.col_stateeventstate=st.col_id 
      inner join tbl_dict_stateconfig sc on st.col_statestateconfig=sc.col_id
      where sc.col_casesystypestateconfig= v_caseTypeId
          and arp.col_paramcode = 'PARTICIPANT_CODE'
          and arp.col_paramvalue = v_participantCode; 
      if(v_count > 0) then 
          v_errormessage := 'This participant is linked with state config';
          v_errorcode    := 101;
          goto cleanup;
      end if;   

      -- Events that are linked with sla  
      select count(*) into v_count 
      from tbl_autoruleparamtmpl arp
      inner join tbl_dict_stateslaaction slaAct on slaAct.col_id = arp.col_dict_stateslaactionarp
      inner join tbl_dict_stateslaevent slaEvent on slaEvent.col_id = slaAct.col_stateslaactnstateslaevnt
      inner join tbl_dict_state st on st.col_id = slaEvent.col_stateslaeventdict_state 
      inner join tbl_dict_stateconfig sc on st.col_statestateconfig=sc.col_id
      where sc.col_casesystypestateconfig= v_caseTypeId
          and arp.col_paramcode = 'PARTICIPANT_CODE'
          and arp.col_paramvalue = v_participantCode; 

      if(v_count > 0) then 
          v_errormessage := 'This participant is linked with state config';
          v_errorcode    := 101;
          goto cleanup;
      end if;   

      
  elsif nvl(v_procedureId, 0) <> 0 then 

      -- Events that are linked with task
      select count(*) into v_count 
      from tbl_autoruleparamtmpl arp
      inner join tbl_taskeventtmpl tetmpl on tetmpl.col_id = arp.col_taskeventtpautoruleparmtp
      inner join tbl_map_taskstateinittmpl mtstmpl on mtstmpl.col_id = tetmpl.col_taskeventtptaskstinittp
      inner join tbl_tasktemplate ttmpl on ttmpl.col_id = mtstmpl.col_map_taskstinittpltasktpl 
      where arp.col_paramcode = 'ParticipantCode'
            and ttmpl.col_proceduretasktemplate = v_procedureId 
            and arp.col_paramvalue = v_participantCode;   
      if(v_count > 0) then 
          v_errormessage := 'This participant is linked with procedure';
          v_errorcode    := 101;
          goto cleanup;
      end if;   

      -- Events that are linked with sla
      select count(*) into v_count 
      from tbl_autoruleparamtmpl arp
      inner join tbl_slaactiontmpl slaActTmp on slaActTmp.col_id = arp.col_autorulepartpslaactiontp
      inner join tbl_slaeventtmpl slaEventTmp on slaEventTmp.col_id = slaActTmp.col_slaactiontpslaeventtp
      inner join tbl_tasktemplate ttmpl on ttmpl.col_id = slaEventTmp.col_slaeventtptasktemplate
      where arp.col_paramcode = 'ParticipantCode'
            and ttmpl.col_proceduretasktemplate = v_procedureId   
            and arp.col_paramvalue = v_participantCode;   
      if(v_count > 0) then 
          v_errormessage := 'This participant is linked with procedure';
          v_errorcode    := 101;
          goto cleanup;
      end if;  
  end if;

  DELETE TBL_PARTICIPANT WHERE col_id = v_id;
  :affectedRows := SQL%ROWCOUNT;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;