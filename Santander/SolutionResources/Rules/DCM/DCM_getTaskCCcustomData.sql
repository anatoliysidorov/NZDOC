DECLARE
  v_customdata NCLOB;
  v_proccessorcode NVARCHAR2(255);
  v_taskdata CLOB;
  v_tasktypedata NCLOB;
  v_result number;
  v_taskid number;
BEGIN
  v_proccessorcode := '';
  v_taskid := :TaskId;
  BEGIN
    SELECT t.col_customdata.getClobVal(),
      tt.COL_RETCUSTDATAPROCESSOR
    INTO v_taskdata,
      v_proccessorcode
    FROM tbl_taskcc t
    LEFT JOIN tbl_dict_tasksystype tt
    ON tt.col_id   = t.col_taskccdict_tasksystype
    WHERE t.col_id = v_taskid;
  IF v_proccessorcode IS NULL THEN
    v_customdata := cast(v_taskdata as nvarchar2);
  ELSE
     v_result := f_dcm_invoketaskcusdataproc2( taskid => v_taskid, output => v_customdata, processorname => v_proccessorcode); 
  END IF;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  END;
  --DBMS_OUTPUT.put_line(v_customdata);
  return v_customdata;
END;