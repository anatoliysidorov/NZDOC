DECLARE
  v_customdata      NCLOB;
  v_proccessorcode  NVARCHAR2(255);
  v_data            NCLOB;
  v_result          NUMBER;
  v_externalpartyid NUMBER;
BEGIN
  v_proccessorcode  := '';
  v_externalpartyid := :ExternalPartyId;

  BEGIN
    --get processor codes
    SELECT To_clob(ep.col_customdata),
           t.col_retcustdataprocessor
      INTO v_data,
           v_proccessorcode
      FROM tbl_externalparty ep
      LEFT JOIN tbl_dict_partytype t
        ON t.col_id = ep.col_externalpartypartytype
     WHERE ep.col_id = v_externalpartyid;
  
    --get custom data
    IF v_proccessorcode IS NULL THEN
      v_customdata := v_data;
    ELSE
      v_customdata := f_dcm_invokeEPCustDataRetPr(ExtPartyId => v_externalpartyid, processorname => v_proccessorcode);
    END IF;
  EXCEPTION
    WHEN no_data_found THEN
      NULL;
  END;

  --DBMS_OUTPUT.put_line(v_customdata); 
  RETURN dbms_xmlgen.convert(v_customdata, dbms_xmlgen.ENTITY_ENCODE);
END;