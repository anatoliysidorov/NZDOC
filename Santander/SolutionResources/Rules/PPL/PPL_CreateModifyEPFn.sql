DECLARE
  --input
  v_extParty_id      NUMBER;
  v_name             NVARCHAR2(255);
  v_code             NVARCHAR2(255);
  v_partytypeid      NUMBER;
  v_partytypecode    NVARCHAR2(255);
  v_parentextpartyid NUMBER;
  v_userid           NUMBER;
  v_workbasketid     NUMBER;
  v_defaultteamid    NUMBER;
  v_email            NVARCHAR2(255);
  v_phone            NVARCHAR2(255);
  v_address          NVARCHAR2(255);
  v_externalid       NVARCHAR2(255);
  v_description      NCLOB;
  v_isdeleted        INT;
  v_wbId             NUMBER;
  v_firstname        NVARCHAR2(255);
  v_middlename       NVARCHAR2(255);
  v_lastname         NVARCHAR2(255);
  v_dob              DATE;
  v_prefix           NVARCHAR2(255);
  v_suffix           NVARCHAR2(255);
  v_partyorgtypeid   NUMBER;

  --custom data
  v_justcustomdata      INT;
  v_customdataprocessor NVARCHAR2(255);
  v_customdata          NCLOB;
  v_prevcustomdata      NCLOB;
  --other
  v_accesssubjectId NUMBER;
  v_res             NUMBER;
  v_uniquecode      NVARCHAR2(255);
  v_uniqueACCcode   NVARCHAR2(255);
  v_objectprefix    NVARCHAR2(255);
  v_count           INT;
  --standard
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);

BEGIN

  --input
  v_extParty_id      := nvl(:ID, 0);
  v_externalid       := TRIM(NVL(:EXTERNALID, :EXTSYSID));
  v_name             := :NAME;
  v_code             := UPPER(REPLACE(v_name, ' ', '_'));
  v_partytypecode    := :PARTYTYPE_CODE;
  v_partytypeid      := nvl(:PARTYTYPE_ID, f_util_getidbycode(code => lower(v_partytypecode), tablename => 'tbl_dict_partytype'));
  v_parentextpartyid := :PARENTEXTERNALPARTY_ID;
  v_userid           := :USERID;
  v_workbasketid     := :WORKBASKET_ID;
  v_defaultteamid    := :DEFAULTTEAM_ID;
  v_email            := :EMAIL;
  v_phone            := :PHONE;
  v_address          := :ADDRESS;
  v_description      := :DESCRIPTION;
  v_isdeleted        := :IsDeleted;
  v_customdata       := nvl(:CustomData, '<CustomData><Attributes></Attributes></CustomData>');
  v_objectprefix     := 'EXTERNALPARTY_';
  v_count            := 0;
  v_justcustomdata   := nvl(:JustCustomData, 0);
  v_uniquecode       := f_UTIL_calcUniqueCode(BaseCode => v_objectprefix || v_code, TableName => 'tbl_externalparty');
  v_firstname        := :FIRSTNAME;
  v_middlename       := :MIDDLENAME;
  v_lastname         := :LASTNAME;
  v_dob              := :DOB;
  v_prefix           := :PREFIX;
  v_suffix           := :SUFFIX;
  v_partyorgtypeid   := :PARTYORGTYPE_ID;

  --standard
  v_errorCode    := 0;
  v_errorMessage := '';

  -- Set Name
  IF v_firstname IS NOT NULL AND v_lastname IS NOT NULL THEN
    v_name := v_firstname || ' ' || v_lastname;
  END IF;

  BEGIN
    IF v_extParty_id = 0 THEN
    
      --check that the user id being associated with the external party is not used elsewhere 
      SELECT COUNT(1) INTO v_count FROM tbl_externalparty WHERE col_userid = v_userid;
      IF v_count > 1 THEN
        v_errorCode    := 121;
        v_errorMessage := 'The given user Id ' || v_userid || '  is associated with another External Party';
        GOTO cleanup;
      END IF;
    
      --check that external ID is unique
      v_count := 0;
      SELECT COUNT(1) INTO v_count FROM tbl_externalparty WHERE lower(col_extsysid) = lower(v_externalid);
      IF v_count > 0 THEN
        v_errorCode    := 125;
        v_errorMessage := 'The External ID must be empty or unique across all records';
        GOTO cleanup;
      END IF;
    
      --create external party record 
      INSERT INTO tbl_externalparty
        (col_name,
         col_code,
         col_isdeleted,
         col_externalpartypartytype,
         col_extpartyextparty,
         col_extsysid,
         col_description,
         col_userid,
         col_email,
         col_phone,
         col_address,
         col_defaultteam,
         col_externalpartyworkbasket,
         col_customdata,
         col_firstname,
         col_middlename,
         col_lastname,
         col_dob,
         col_prefix,
         col_suffix,
         col_extpartypartyorgtype)
      VALUES
        (v_name,
         v_uniquecode,
         v_isdeleted,
         v_partytypeid,
         v_parentextpartyid,
         v_externalid,
         v_description,
         v_userid,
         v_email,
         v_phone,
         v_address,
         v_defaultteamid,
         v_workbasketid,
         xmltype(v_customdata),
         v_firstname,
         v_middlename,
         v_lastname,
         v_dob,
         v_prefix,
         v_suffix,
         v_partyorgtypeid)
      RETURNING col_id INTO v_extParty_id;
    
      --create Access Subject record 
      v_uniqueACCcode := f_UTIL_calcUniqueCode(BaseCode => v_objectprefix || v_code, TableName => 'tbl_ac_accesssubject');
      INSERT INTO tbl_ac_accesssubject (col_type, col_code, col_name) VALUES ('EXTERNALPARTY', v_uniqueACCcode, v_name) RETURNING col_id INTO v_accesssubjectid;
    
      --update AccessObjectId
      UPDATE tbl_externalparty SET col_extpartyaccesssubject = v_accesssubjectid WHERE col_id = v_extParty_id;
    
    ELSE
      -- validation on Id is Exist
      IF v_extParty_id > 0 THEN
        v_res := f_UTIL_getId(errorcode => v_errorCode, errormessage => v_errorMessage, id => v_extParty_id, tablename => 'tbl_externalparty');
        IF v_errorCode > 0 THEN
          GOTO cleanup;
        END IF;
      END IF;
    
      -- get WorkBasketId
      BEGIN
        SELECT col_id INTO v_wbId FROM tbl_ppl_workbasket WHERE col_workbasketexternalparty = v_extParty_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    
      --merge custom data into one XML 
      v_prevcustomdata := f_ppl_getpartycustomdata(externalpartyid => v_extParty_id);
      v_customdata     := f_form_mergecustomdata(input => v_prevcustomdata, input2 => v_customdata);
    
      --update custom data column 
      UPDATE tbl_externalparty SET col_customdata = xmltype(v_customdata) WHERE col_id = v_extParty_id;
    
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
               col_externalpartyworkbasket = v_workbasketid,
               col_firstname               = v_firstname,
               col_middlename              = v_middlename,
               col_lastname                = v_lastname,
               col_dob                     = v_dob,
               col_prefix                  = v_prefix,
               col_suffix                  = v_suffix
         WHERE col_id = v_extParty_id;
      END IF;
    
      UPDATE tbl_ac_accesssubject SET col_name = v_name WHERE col_id IN (SELECT col_extpartyaccesssubject FROM tbl_externalparty WHERE col_id = v_extParty_id);
    END IF;
  
    --create/update Work Basket
    v_res := f_ppl_createmodifywbfn(caseworkerowner    => NULL,
                                    externalpartyowner => v_extParty_id,
                                    businessroleowner  => NULL,
                                    skillowner         => NULL,
                                    teamowner          => NULL,
                                    NAME               => v_name,
                                    code               => v_uniquecode,
                                    description        => 'Automatically created workbasket for the' || ' ''' || v_name || ''' External Party',
                                    isdefault          => 1,
                                    isprivate          => 1,
                                    workbaskettype     => 'PERSONAL',
                                    id                 => v_wbId,
                                    resultid           => v_wbId,
                                    errorcode          => v_errorCode,
                                    errormessage       => v_errorMessage);
  
    --calculate and invoke custom processor                                    
    BEGIN
      SELECT col_customdataprocessor INTO v_customdataprocessor FROM tbl_dict_partytype WHERE col_id IN (SELECT col_externalpartypartytype FROM tbl_externalparty WHERE col_id = v_extParty_id);
    EXCEPTION
      WHEN no_data_found THEN
        v_customdataprocessor := NULL;
    END;
    IF (v_customdataprocessor IS NOT NULL) THEN
      v_res := f_dcm_invokeepcustdataproc(extpartyid => v_extParty_id, input => v_customdata, processorname => v_customdataprocessor);
    END IF;
  
    RETURN v_extParty_id;
  EXCEPTION
    WHEN OTHERS THEN
      v_errorCode    := 102;
      v_errorMessage := Substr(SQLERRM, 1, 200);
  END;

  <<cleanup>>
  :errorCode    := v_errorCode;
  :errorMessage := v_errorMessage;
END;
