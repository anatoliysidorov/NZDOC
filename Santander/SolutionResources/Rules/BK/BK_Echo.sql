DECLARE
  v_input     nVARCHAR2(255);
  
BEGIN
  v_input := :Input;
  :Output := v_input;
END;