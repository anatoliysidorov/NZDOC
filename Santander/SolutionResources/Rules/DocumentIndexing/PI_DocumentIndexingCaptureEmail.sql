declare 
  v_containerId number;
  v_containerTypeId number;
  v_workbasketId number;
  v_stateId number;
  v_workitemId number;
  V_ERRORCODE NUMBER;
  V_ERRORMESSAGE NVARCHAR2(200);
  V_TARGET NVARCHAR2(200);  
  V_CREATED_ACTIVITY NVARCHAR2(200);  
  v_Return NUMBER;  
begin
	
	
	  select s.col_id,  s.col_activity, targetState.col_activity  into v_stateId, V_CREATED_ACTIVITY, v_target
	--, sc.col_id,s.col_code
	--  , sct.*, sc.col_code stateconfig_code, sc.col_id, s.col_code state_code, cs.col_code casestate_code, cs.*
	from tbl_dict_state s
	inner join tbl_dict_stateconfig sc on sc.col_id = s.COL_STATESTATECONFIG
	inner join tbl_dict_casestate cs on cs.col_id = s.COL_STATECASESTATE
	inner join tbl_dict_transition t on t.COL_SOURCETRANSITIONSTATE = s.col_id --and t.COL_ISNEXTDEFAULT =1
	inner join tbl_dict_state targetState on targetState.col_id = t.COL_TARGETTRANSITIONSTATE
	left join tbl_dict_stateconfigtype sct on sct.col_id = sc.COL_STATECONFSTATECONFTYPE
	where sct.col_code = 'DOCUMENT'
	/*and sc.col_code = 'DOCINDEXINGSTATES'*/ -- keep this condition commented
	and sc.col_iscurrent = 1 and cs.col_isstart = 1;

	  select col_id into v_containerTypeId   
	  from tbl_dict_containertype
	  where col_code = 'EMAIL';
	  
	  
	  select col_id into v_workbasketId 
	  from tbl_ppl_workbasket
	  where col_code = 'DOCUMENT_INDEXING_EMAIL';


	  insert into tbl_container ( COL_CREATEDBY, COL_CREATEDDATE, COL_MODIFIEDBY,COL_MODIFIEDDATE,COL_NAME, COL_CONTAINERCONTAINERTYPE, COL_CUSTOMDATA)
	  values (sys_context('CLIENTCONTEXT', 'AccessSubject'), sysdate,sys_context('CLIENTCONTEXT', 'AccessSubject'), sysdate, 'Test Email container', v_containerTypeId, XMLType('<?xml version="1.0" encoding="UTF-8"?>
	<CONTENT>
		<FROM>test@email.com</FROM>
		<TO>dcmtest1@regecell.com;</TO>
		<CC />
		<RECEIVEDATE>2018-01-12T14:17:54.000-08:00</RECEIVEDATE>
		<RECEIVETIME>14:17:54</RECEIVETIME>
		<SUBJECT>test email</SUBJECT>
		<ATTACHMENTS />
	</CONTENT>'));
		
	  select gen_tbl_container.currval into v_containerId from dual;
	  
	  
	  insert into tbl_pi_workitem (COL_PI_WORKITEMPPL_WORKBASKET, COL_PI_WORKITEMDICT_STATE, col_name, col_code, COL_CURRMSACTIVITY)
	  values (v_workbasketId, v_stateId, 'Test email capture workitem', 'Test workitem '||to_char(sysdate), V_CREATED_ACTIVITY);

	  select gen_tbl_pi_workitem.currval into v_workitemId from dual;

	  update tbl_pi_workitem set col_title = 'DOC-' || (SELECT TO_CHAR(TRUNC(SYSDATE, 'IW'), 'YYYY') FROM DUAL) || '-' || to_char(v_workitemId) where col_id = v_workitemId;

	  
	  insert into tbl_doc_document (COL_ISFOLDER, COL_URL, COL_NAME, COL_ISDELETED, COL_DESCRIPTION, COL_DOC_DOCUMENTCONTAINER, COL_DOC_DOCUMENTPI_WORKITEM, col_isprimary, col_doc_documentsystemtype)
	  values (0, 'test doc url', 'test doc url', 0, 'test description', v_containerId, v_workitemId, 1, (select col_id from TBL_DICT_SYSTEMTYPE where col_code = 'EMAIL_BODY'));
	  
	  
	  insert into tbl_doc_document (COL_ISFOLDER, COL_URL, COL_NAME, COL_ISDELETED, COL_DESCRIPTION, COL_DOC_DOCUMENTCONTAINER, COL_DOC_DOCUMENTPI_WORKITEM, col_isprimary, col_doc_documentsystemtype)
	  values (0, 'test doc url 2', 'test doc url 2', 0, 'test description 2', v_containerId, v_workitemId, null, (select col_id from TBL_DICT_SYSTEMTYPE where col_code = 'EMAIL_ATTACHMENT'));
	  
	  
	v_Return := F_PI_WORKITEMROUTEMANUALFN(
		ERRORCODE => V_ERRORCODE,
		ERRORMESSAGE => V_ERRORMESSAGE,
		TARGET => V_TARGET,
		WORKITEMID => V_WORKITEMID
	);
	  

	end;