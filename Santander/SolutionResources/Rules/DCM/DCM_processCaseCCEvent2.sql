--EVENTS LIKE BEFORE_ASSIGN ARE PROCESSED AND IsValid PROPERTY IS RETURNED
--IF EVENT PROCESSOR RETURNS TRUE, CASE CAN BE INITIALIZED
--THIS FUNCTION WILL BE CALLED BY RULE DCM_assignCase
declare
  v_CaseId Integer;
  v_result number;
  v_isValid number;
  v_EventType nvarchar2(255);
  v_EventState nvarchar2(255);
begin
  v_CaseId := :CaseId;
  v_EventType := :EventType;
  if v_EventType is null then
    v_EventType := 'before';
  end if;
  v_EventState := :EventState;
  v_isValid := 1;
  --FIND LIST OF EVENTS FOR THE CURRENT CASE
  --FIND LIST OF EVENT PROCESSORS (RULES DEPLOYED AS FUNCTIONS) ASSOCIATED WITH CURRENT CASE
  for rec in (select cs.col_id as col_id, ce.col_processorcode as col_processorcode,
                csi.col_map_casestateinitcccasecc as caseId,
                csi.col_casestateinitcc_initmtd as initmethod_id, csi.col_map_csstinitcc_csst as casestate_id,
                cst.col_code as casetype,
                tem.col_code as caseevent, tet.col_code as caseeventtype, im.col_code as caseinitmethod, css.col_code as caseinitstate
                --CURRENT TASK
                from tbl_casecc cs
                --JOIN CASE TO CASE SYSTEM TYPE, FOR EXAMPLE, "REVIEW"
                inner join tbl_dict_casesystype cst on cs.col_caseccdict_casesystype = cst.col_id
                --JOIN TO CASE INSTANTIATION
                inner join tbl_map_casestateinitcc csi on cs.col_id = csi.col_map_casestateinitcccasecc
                --JOIN TO CASE EVENT
                inner join tbl_caseeventcc ce on csi.col_id = ce.col_caseeventcccasestinitcc
                --JOIN TO CASE STATE DICTIONARY (EXAMPLE: "NEW")
                inner join tbl_dict_casestate css on csi.col_map_csstinitcc_csst = css.col_id
                --JOIN TO TASK/CASE EVENT TYPE DICTIONARY (EXAMPLE: "VALIDATION")
                inner join tbl_dict_taskeventtype tet on ce.col_taskeventtypecaseeventcc = tet.col_id
                --JOIN TO TASK/CASE EVENT MOMENT DICTIONARY (EXAMPLE: "BEFORE_ASSIGN")
                inner join tbl_dict_taskeventmoment tem on ce.col_taskeventmomntcaseeventcc = tem.col_id
                --JOIN INIT METHOD DICTIONARY (EXAMPLE: "MANUAL")
                inner join tbl_dict_initmethod im on csi.col_casestateinitcc_initmtd = im.col_id
                where cs.col_id = v_CaseId
                and lower(tem.col_code) = v_EventType
                and lower(css.col_code) = v_EventState
                and lower(tet.col_code) = 'validation')
  loop
    --CALL PROCESSOR FUNCTION HERE AND GET RETURN VALUE
    v_isValid := 1;
	v_result := f_DCM_invokeCaseEventProc(CaseId => rec.col_id,ProcessorName => rec.col_processorcode,validationresult => v_isValid);
    if v_isValid = 0 then
      exit;
    end if;
  end loop;
  :IsValid := v_isValid;
end;