DECLARE
    v_result NUMBER;
BEGIN
    v_result := f_UTIL_addToQueueFn(RuleCode => :RuleCode,
                                    PARAMETERS => :PARAMETERS);
    return v_result;
END;