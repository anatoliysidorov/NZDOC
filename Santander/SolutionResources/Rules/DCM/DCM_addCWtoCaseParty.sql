declare 
    v_count number;
    v_caseid number;
    v_caseWorkerId number;
    v_purpose nvarchar2(255);
    v_partyTypeId number;
begin

	v_purpose := :Purpose;
	v_caseWorkerId := :CaseWorkerId;
	v_caseid := :CaseId;

	if(v_caseid is null) then
		:ErrorMessage := 'CaseId is required';
		:ErrorCode := 101;
		return null;
	end if;

	if(v_caseWorkerId is null) then
		:ErrorMessage := 'CaseWorkerId is required';
		:ErrorCode := 101;
		return null;
	end if;

	select count(*) into v_count
	from tbl_caseparty
	where col_casepartyppl_caseworker = v_caseWorkerId 
			and col_casepartycase = v_caseid;
	
	if(v_count = 0) then
		v_partyTypeId := f_UTIL_getIdByCode(
			Code => 'CASEWORKER', 
			TableName => 'tbl_dict_participantunittype'
		);

		insert into tbl_caseparty
		(
			col_allowdelete, 
			col_casepartycase, 
			col_casepartydict_unittype,
			col_name,
			col_casepartyppl_caseworker
		)
		values
		(
			0, 
			v_caseid, 
			v_partyTypeId,
			v_purpose,
			v_caseWorkerId
		);
	end if;
end;