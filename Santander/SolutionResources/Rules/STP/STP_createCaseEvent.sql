DECLARE

  v_taskeventmoment NUMBER;
  v_taskeventtype   NUMBER;
  v_id              NUMBER;
  v_affectedrows    NUMBER;
  v_order           NUMBER;

  CURSOR c1 IS
    SELECT s1.name    AS vname,
           s1."LEVEL" AS vlevel,
           s2.name    AS cname,
           s2."LEVEL" AS clevel
      FROM (SELECT regexp_substr(:parametercodes_sv, '[^|||]+', 1, LEVEL) AS NAME,
                   LEVEL AS "LEVEL"
              FROM dual
             WHERE LEVEL BETWEEN 1 AND 100
            CONNECT BY regexp_substr(:parametercodes_sv, '[^|||]+', 1, LEVEL) IS NOT NULL) s1
     INNER JOIN (SELECT regexp_substr(:parametervalues_sv,
                                      '[^|||]+',
                                      1,
                                      LEVEL) AS NAME,
                        LEVEL AS "LEVEL"
                   FROM dual
                  WHERE LEVEL BETWEEN 1 AND 100
                 CONNECT BY regexp_substr(:parametervalues_sv,
                                          '[^|||]+',
                                          1,
                                          LEVEL) IS NOT NULL) s2
        ON s1."LEVEL" = s2."LEVEL"
     ORDER BY clevel, cname;

BEGIN

  BEGIN
    SELECT t1.col_id
      INTO v_taskeventmoment
      FROM tbl_dict_taskeventmoment t1
     WHERE t1.col_code = upper(:taskeventmoment_code);
    SELECT t1.col_id
      INTO v_taskeventtype
      FROM tbl_dict_taskeventtype t1
     WHERE t1.col_code = upper(:taskeventtype_code);
  
    SELECT nvl(MAX(col_caseeventorder), 0)
      INTO v_order
      FROM tbl_caseevent
     WHERE col_caseeventcasestateinit = :casestateinit_id
       AND col_taskeventmomentcaseevent = v_taskeventmoment
       AND col_taskeventtypecaseevent = v_taskeventtype;
  
    v_order := v_order + 1;
  
    INSERT INTO tbl_caseevent
      (col_code,
       col_processorcode,
       col_caseeventcasestateinit,
       col_taskeventmomentcaseevent,
       col_taskeventtypecaseevent,
       col_caseeventorder)
    VALUES
      (sys_guid(),
       :processorcode,
       :casestateinit_id,
       v_taskeventmoment,
       v_taskeventtype,
       v_order)
    RETURNING col_id INTO v_id;
  
    v_affectedrows := 1;
  
    IF :parametercodes_sv IS NOT NULL THEN
      FOR rec1 IN c1 LOOP
      
        INSERT INTO tbl_autoruleparameter
          (col_paramcode, col_paramvalue, col_caseeventautoruleparam, col_code)
        VALUES
          (rec1.vname, rec1.cname, v_id, sys_guid());
        v_affectedrows := v_affectedrows + 1;
      
      END LOOP;
    END IF;
  
    :recordid     := v_id;
    :affectedrows := v_affectedrows;
    :errorcode    := 0;
    :errormessage := 'Success';
  
  EXCEPTION
    WHEN no_data_found THEN
      :recordid     := 0;
      :affectedrows := 0;
      :errorcode    := 1;
      :errormessage := 'No data found';
    WHEN dup_val_on_index THEN
      :recordid     := 0;
      :affectedrows := 0;
      :errorcode    := 2;
      :errormessage := 'Dup val on index';
    WHEN OTHERS THEN
      :recordid     := 0;
      :affectedrows := 0;
      :errorcode    := 3;
      :errormessage := SQLERRM;
  END;

END;