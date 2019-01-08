DECLARE
    --INTERNAL
    v_caseid Integer;
BEGIN
    --preset
	:IsInCache := 0; --for future needs if we ever decide to move this to cache
	
	--determine what this sla ms event is tied to (case, task, document, ...). RIght now, only Case is supported
    SELECT    s.COL_STATECASESTATE
    INTO      v_caseid
    FROM      tbl_dict_stateSlaEvent sle
    LEFT JOIN tbl_dict_state s ON sle.COL_STATESLAEVENTDICT_STATE = s.col_id
	WHERE sle.col_id = :StateSLAEventId;
    
	--determine context
	IF v_caseid > 0 THEN
        :TargetId := v_caseid;
        :TargetType := 'CASE';
    ELSE
        :TargetId := NULL;
        :TargetType := NULL;
    END IF;
EXCEPTION
WHEN OTHERS THEN
    :TargetId := NULL;
    :TargetType := NULL;
END;