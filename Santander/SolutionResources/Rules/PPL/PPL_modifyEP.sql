DECLARE
  --input 
  v_id            NUMBER;
  v_name          NVARCHAR2(255);
  v_userid        NUMBER;
  v_workbasketid  NUMBER;
  v_defaultteamid NUMBER;
  v_email         NVARCHAR2(255);
  v_phone         NVARCHAR2(255);
  v_address       NVARCHAR2(255);
  v_externalid    NVARCHAR2(255);
  v_description   NCLOB;
  v_isdeleted     INT;

  --custom data 
  v_justcustomdata      INTEGER;
  v_customdataprocessor NVARCHAR2(255);
  v_customdata          NCLOB;
  v_prevcustomdata      NCLOB;

  --standard 
  v_errorcode    NUMBER;
  v_errormessage NVARCHAR2(255);

  --other 
  v_accesssubjectid NUMBER;
  v_idext           NUMBER;
  v_guid            NVARCHAR2(255);
  v_res             NUMBER;

BEGIN
  --input 
  v_id            := :ID;
  v_externalid    := NVL(:EXTERNALID, :EXTSYSID);
  v_name          := :NAME;
  v_userid        := :USERID;
  v_workbasketid  := :WORKBASKET_ID;
  v_defaultteamid := :DEFAULTTEAM_ID;
  v_email         := :EMAIL;
  v_phone         := :PHONE;
  v_address       := :ADDRESS;
  v_description   := :DESCRIPTION;
  v_isdeleted     := :IsDeleted;
  v_customdata    := :CustomData;
  --custom data 
  v_justcustomdata := Nvl(:JustCustomData, 0);
  IF v_customdata IS NULL THEN
    v_customdata := '<CustomData><Attributes></Attributes></CustomData>';
  END IF;
  --standard 
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';
  :errorCode     := v_errorcode;
  :errorMessage  := v_errormessage;

  BEGIN
    -- Validation Input parameters
    IF v_id IS NULL THEN
      v_errormessage := 'Id can not be empty';
      v_errorcode    := 101;
      GOTO cleanup;
    END IF;
  
    --merge custom data into one XML 
    v_prevcustomdata := F_ppl_getpartycustomdata(externalpartyid => v_id);
    v_customdata     := F_form_mergecustomdata(input => v_prevcustomdata, input2 => v_customdata);
  
    --update custom data column 
    UPDATE tbl_externalparty SET col_customdata = Xmltype(v_customdata) WHERE col_id = v_id;
  
    --update other fields if not just submitting custom data 
    IF v_justcustomdata = 0 THEN
      UPDATE tbl_externalparty
         SET col_name                    = v_name,
             col_extsysid                = v_externalid,
             col_description             = v_description,
             col_userid                  = v_userid,
             col_email                   = v_email,
             col_phone                   = v_phone,
             col_address                 = v_address,
             col_isdeleted               = v_isdeleted,
             col_defaultteam             = v_defaultteamid,
             col_externalpartyworkbasket = v_workbasketid
       WHERE col_id = v_id;
    END IF;
    :affectedRows := 1;
  
    --calculate and invoke custom processor                                    
    BEGIN
      SELECT col_updatecustdataprocessor
        INTO v_customdataprocessor
        FROM tbl_dict_partytype
       WHERE col_id IN
             (SELECT col_externalpartypartytype FROM tbl_externalparty WHERE col_id = v_id);
    EXCEPTION
      WHEN no_data_found THEN
        v_customdataprocessor := NULL;
    END;
    IF (v_customdataprocessor IS NOT NULL) THEN
      v_idext := f_dcm_invokeepcustdataproc(extpartyid    => v_id,
                                            input         => v_customdata,
                                            processorname => v_customdataprocessor);
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      :affectedRows  := 0;
      v_errorcode    := 102;
      v_errormessage := Substr(SQLERRM, 1, 200);
      :errorCode     := v_errorcode;
      :errorMessage  := v_errormessage;
  END;

  <<cleanup>>
  :errorCode    := v_errorcode;
  :errorMessage := v_errormessage;
END;