DECLARE
  v_extParty_id  NUMBER;
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);
BEGIN
  :ErrorCode    := 0;
  :ErrorMessage := '';
  :recordId     := 0;

  v_extParty_id := f_ppl_createmodifyepfn(address                => :address,
                                          customdata             => :customdata,
                                          defaultteam_id         => :defaultteam_id,
                                          description            => :description,
                                          email                  => :email,
                                          errorcode              => v_errorCode,
                                          errormessage           => v_errorMessage,
                                          externalid             => :externalid,
                                          extsysid               => :extsysid,
                                          id                     => :id,
                                          isdeleted              => :isdeleted,
                                          justcustomdata         => :justcustomdata,
                                          NAME                   => :NAME,
                                          parentexternalparty_id => :parentexternalparty_id,
                                          partytype_code         => :partytype_code,
                                          partytype_id           => :partytype_id,
                                          phone                  => :phone,
                                          userid                 => :userid,
                                          workbasket_id          => :workbasket_id,
                                          firstname              => :firstname,
                                          middlename             => :middlename,
                                          lastname               => :lastname,
                                          dob                    => :dob,
                                          prefix                 => :prefix,
                                          suffix                 => :suffix,
                                          partyorgtype_id        => :partyorgtype_id);

  IF v_errorCode <> 0 THEN
    :ErrorCode    := v_errorCode;
    :ErrorMessage := v_errorMessage;
    ROLLBACK;
  ELSE
    :recordId := v_extParty_id;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    :recordId     := NULL;
    :ErrorCode    := 101;
    :ErrorMessage := SQLERRM;
    ROLLBACK;
END;
