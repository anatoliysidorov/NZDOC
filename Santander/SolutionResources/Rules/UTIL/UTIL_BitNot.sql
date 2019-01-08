DECLARE

v_dec number;
v_res number;

BEGIN
	v_dec := :p_dec;
	v_res := -1 - v_dec;
	return v_res;
END;