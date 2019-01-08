DECLARE
v_result INT;

BEGIN

v_result := f_UTIL_createSysLogFn(:INPUT || to_char(:TaskId));

RETURN 0;

END;