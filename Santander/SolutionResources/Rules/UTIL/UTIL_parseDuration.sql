--ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '. ';
DECLARE
v_str VARCHAR2(30) := lower(:duration);
isCorrectRow INTEGER := 0;
v_week FLOAT; 
v_day FLOAT; 
v_hour FLOAT; 
v_min FLOAT; 
pos_w INTEGER;
pos_d INTEGER;
pos_h INTEGER;
pos_m INTEGER;
interval_DS INTEGER;
BEGIN
  BEGIN
    -- 1 - is Correct format
    SELECT NVL2(v_str,decode(ltrim(translate(v_str, 'wdhm0123456789.', ' ')), NULL, 1, 0), 0) INTO isCorrectRow 
    FROM dual;  
    
    IF (isCorrectRow > 0) THEN 
      SELECT instr(v_str, 'w') INTO pos_w FROM dual;
      IF (pos_w > 0) THEN 
        SELECT to_number(substr(v_str, 1, pos_w-1)) INTO v_week FROM dual;
        v_str := ltrim(substr(v_str, pos_w+1));
      END IF;  
      
      SELECT instr(v_str, 'd') INTO pos_d FROM dual;
      IF (pos_d > 0) THEN 
        SELECT to_number(substr(v_str, 1, pos_d-1)) INTO v_day FROM dual;
        v_str := ltrim(substr(v_str, pos_d+1));
      END IF;  
      
      SELECT instr(v_str, 'h') INTO pos_h FROM dual;
      IF (pos_h > 0) THEN 
        SELECT to_number(substr(v_str, 1, pos_h-1)) INTO v_hour FROM dual;
        v_str := ltrim(substr(v_str, pos_h+1));
      END IF;  
      
      SELECT instr(v_str, 'm') INTO pos_m FROM dual;
      IF (pos_m > 0) THEN 
        SELECT to_number(substr(v_str, 1, pos_m-1)) INTO v_min FROM dual;
      END IF;  
      
      interval_DS :=  NVL(v_week*5*24*60*60, 0) + NVL(v_day*24*60*60, 0) + NVL(v_hour*60*60, 0) + NVL(v_min*60, 0);

    ELSE interval_DS := NULL;  
    END IF;

    --dbms_output.put_line(to_char(interval_DS));
    
  EXCEPTION 
  WHEN OTHERS THEN interval_DS := NULL;
  END;
RETURN interval_DS;
END;