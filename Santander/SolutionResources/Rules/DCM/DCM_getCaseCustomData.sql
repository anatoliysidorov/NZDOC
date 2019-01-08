DECLARE
  v_customdata     NCLOB;
  v_proccessorcode NVARCHAR2(255);
  v_casedata       CLOB;
  v_casetypedata   NCLOB;
  v_result         NUMBER;
  v_caseid         NUMBER;
BEGIN
  v_proccessorcode := '';
  v_caseid         := :CaseId;
  BEGIN
    SELECT ce.col_customdata.getClobVal(),
           Ct.COL_RETCUSTDATAPROCESSOR
      INTO v_casedata,
           v_proccessorcode
      FROM tbl_case c
     INNER JOIN tbl_caseext ce
        ON c.col_id = ce.col_caseextcase
      LEFT JOIN tbl_dict_casesystype ct
        ON ct.col_id = c.col_casedict_casesystype
     WHERE c.col_id = v_caseid;
  
    IF v_proccessorcode IS NULL THEN
      --v_customdata := cast(v_casedata as nvarchar2);
      v_customdata := dbms_xmlgen.convert(v_casedata, dbms_xmlgen.ENTITY_DECODE);
    ELSE
      v_result := f_dcm_invokecasecusdataproc2(caseid => v_caseid, output => v_customdata, processorname => v_proccessorcode);
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END;
  --DBMS_OUTPUT.put_line(v_customdata);
  RETURN dbms_xmlgen.convert(v_customdata, dbms_xmlgen.ENTITY_ENCODE);
END;