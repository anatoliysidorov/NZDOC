DECLARE
  --input 
  v_id               NUMBER;
  v_name             NVARCHAR2(255);
  v_userid           NUMBER;
  v_workbasketid     NUMBER;
  v_defaultteamid    NUMBER;
  v_email            NVARCHAR2(255);
  v_phone            NVARCHAR2(255);
  v_address          NVARCHAR2(255);
  v_externalid       NVARCHAR2(255);
  v_description      NCLOB;
  v_isdeleted        INT;
  v_partytypeid      NUMBER;
  v_partytypecode    NVARCHAR2(255);
  v_parentextpartyid NUMBER;
  --custom data 
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
  v_useridnumused   INT;
  v_count INT;
BEGIN
  --input 
  v_externalid       := TRIM(NVL(:EXTERNALID, :EXTSYSID));
  v_name             := :NAME;
  v_userid           := :USERID;
  v_workbasketid     := :WORKBASKET_ID;
  v_defaultteamid    := :DEFAULTTEAM_ID;
  v_email            := :EMAIL;
  v_phone            := :PHONE;
  v_address          := :ADDRESS;
  v_description      := :DESCRIPTION;
  v_isdeleted        := :IsDeleted;
  v_customdata       := :CustomData;
  v_partytypecode    := :PARTYTYPE_CODE;
  v_partytypeid      := Nvl(:PARTYTYPE_ID,
                            f_util_getidbycode(code      => lower(v_partytypecode),
                                               tablename => 'tbl_dict_partytype'));
  v_parentextpartyid := :PARENTEXTERNALPARTY_ID;
  v_guid             := sys_guid();
  v_count := 0;

  --standard 
  :affectedRows  := 0;
  v_errorcode    := 0;
  v_errormessage := '';
  :errorCode     := v_errorcode;
  :errorMessage  := v_errormessage;
  :RECORDID      := 0;

  BEGIN
    --check that the user id being associated with the external party is not used elsewhere 
    SELECT COUNT(1) INTO v_useridnumused FROM tbl_externalparty WHERE col_userid = v_userid;
  
    IF v_useridnumused > 1 THEN
      v_errorcode    := 121;
      v_errormessage := 'The given user Id ' || v_userid ||'  is associated with another External Party';
      GOTO cleanup;
    END IF;
	
	--check that external ID is unique
	v_count := 0;
	SELECT count(1)
	INTO v_count
	FROM tbl_externalparty
	WHERE lower(col_extsysid) = lower(v_externalid);
	
	IF v_count > 0 THEN
      v_errorcode    := 125;
      v_errormessage := 'The External ID must be empty or unique across all records';
      GOTO cleanup;
    END IF;
  
    --calculate the correct custom data
    IF v_customdata IS NULL THEN
      v_customdata := '<CustomData><Attributes></Attributes></CustomData>';
    END IF;
  
    --create external party record 
    INSERT INTO tbl_externalparty
      (col_code,
       col_isdeleted,
       col_externalpartypartytype,
       col_extpartyextparty,
       col_name,
       col_extsysid,
       col_description,
       col_userid,
       col_email,
       col_phone,
       col_address,
       col_defaultteam,
       col_externalpartyworkbasket,
       col_customdata)
    VALUES
      (v_guid,
       0,
       v_partytypeid,
       v_parentextpartyid,
       v_name,
       v_externalid,
       v_description,
       v_userid,
       v_email,
       v_phone,
       v_address,
       v_defaultteamid,
       v_workbasketid,
       Xmltype(v_customdata))
    RETURNING col_id INTO v_id;
    :RECORDID     := v_id;
    :AFFECTEDROWS := 1;
  
    --create Access Subject record 
    INSERT INTO tbl_ac_accesssubject
      (col_type, col_code, col_name)
    VALUES
      ('EXTERNALPARTY', 'EXTERNALPARTY_' || v_id, v_name)
    RETURNING col_id INTO v_accesssubjectid;
  
    --update AccessObjectId
    UPDATE tbl_externalparty SET col_extpartyaccesssubject = v_accesssubjectid WHERE col_id = v_id;
  
    --create workbasket
    v_res := f_ppl_createmodifywbfn(caseworkerowner    => NULL,
                                    externalpartyowner => v_id,
                                    businessroleowner  => NULL,
                                    skillowner         => NULL,
                                    teamowner          => NULL,
                                    NAME               => '(External Party) ' || v_guid,
                                    code               => v_guid,
                                    description        => 'Automatically created workbasket for the external party ' ||
                                                          v_guid,
                                    isdefault          => 1,
                                    isprivate          => 1,
                                    workbaskettype     => 'PERSONAL',
                                    id                 => NULL,
                                    resultid           => v_res,
                                    errorcode          => v_errorcode,
                                    errormessage       => v_errormessage);
  
    --calculate and invoke custom processor                                    
    BEGIN
      SELECT col_customdataprocessor
        INTO v_customdataprocessor
        FROM tbl_dict_partytype
       WHERE col_id IN
             (SELECT col_externalpartypartytype FROM tbl_externalparty WHERE col_id = v_id);
    EXCEPTION
      WHEN no_data_found THEN
        v_customdataprocessor := NULL;
    END;
    IF (v_customdataprocessor IS NOT NULL) THEN
      v_idext := F_dcm_invokeepcustdataproc(extpartyid    => v_id,
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