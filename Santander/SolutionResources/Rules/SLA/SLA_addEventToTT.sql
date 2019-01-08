DECLARE
	v_ErrorCode			NUMBER;
	v_createddate   	DATE;
	v_createdby     	NVARCHAR2(255);
	v_owner         	NVARCHAR2(255);

	v_AttemptCount 		NUMBER;
	v_MaxAttempts 		NUMBER;

	v_CaseId			NUMBER;
	v_EventTypeId		NUMBER;
	v_TaskId			NUMBER;
	v_DateEventTypeId	NUMBER;
	v_EventLevelId		NUMBER;
	v_TaskTemplateId	NUMBER;
	v_SlaEventOrder		Integer;

BEGIN
	:affectedRows := 0;
	:recordId := 0;

	v_createdby 		:= '@TOKEN_USERACCESSSUBJECT@';
	v_createddate 		:= sysdate;
	v_owner 			:= v_createdby;
	v_AttemptCount 		:= :AttemptCount;
	v_MaxAttempts 		:= :MaxAttempts;
	v_CaseId			:= :CaseId;
	v_EventTypeId		:= :EventTypeId;
	v_TaskId			:= :TaskId;
	v_DateEventTypeId	:= :DateEventTypeId;
	v_EventLevelId		:= :EventLevelId;
	v_TaskTemplateId	:= :TaskTemplateId;

 BEGIN

    begin
      if v_TaskTemplateId is not null then
        select nvl(max(col_slaeventorder),0) + 1 into v_SlaEventOrder from tbl_slaevent where col_slaeventtasktemplate = v_TaskTemplateId;
      elsif v_TaskId is not null then
        select nvl(max(col_slaeventorder),0) + 1 into v_SlaEventOrder from tbl_slaevent where col_slaeventtask = v_TaskId;
      end if;
      exception
      when NO_DATA_FOUND then
      v_SlaEventOrder := 1;
    end;

	INSERT INTO tbl_SLAEvent(
		col_code,
		col_AttemptCount,
 		col_CreatedBy,
 		col_CreatedDate,
 		col_MaxAttempts,
		col_slaeventcase,
		col_slaeventdict_slaeventtype,
		col_slaeventtask,
		col_slaevent_dateeventtype,
		col_slaevent_slaeventlevel,
		col_slaeventtasktemplate,
		col_slaeventorder
	)VALUES(
		sys_guid(),
		v_AttemptCount,
		v_CreatedBy,
		v_CreatedDate,
		v_MaxAttempts,
		v_CaseId,		
		v_EventTypeId,	
		v_TaskId,		
		v_DateEventTypeId,	
		v_EventLevelId,		
		v_TaskTemplateId,
		v_SlaEventOrder
	);

    SELECT gen_tbl_SLAEvent.currval INTO :recordId FROM DUAL;

    :affectedRows := 1;
  EXCEPTION 
    WHEN NO_DATA_FOUND THEN
     :affectedRows := 0;   
    WHEN DUP_VAL_ON_INDEX  THEN
     :affectedRows := 0;   
  END;

  return;
      
END;