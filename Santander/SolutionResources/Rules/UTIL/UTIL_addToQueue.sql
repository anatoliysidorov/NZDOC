DECLARE
    v_result NUMBER;
BEGIN
    :ErrorCode := 0;
    :ErrorMessage := '';
    :RecordId := NULL;
    v_result := f_UTIL_addToQueueFn(RuleCode => :RuleCode,
                                    PARAMETERS => :PARAMETERS);
    :recordId := v_result;
END;