DECLARE
  v_groupid              INTEGER;
  v_objectid             INTEGER;
  v_objecttype           NVARCHAR2(255);
  v_objecttypename       NVARCHAR2(255);
  v_name                 NVARCHAR2(255);
  v_code                 NVARCHAR2(255);
  v_description          NVARCHAR2(4000);
  v_owner                INTEGER;
  v_count                INTEGER;
  v_workbasket_type_code INTEGER;
  v_lastID               INTEGER;
  v_lastIdWB             INTEGER;
  v_taskPullerFn         NVARCHAR2(255);
  v_casePullerFn         NVARCHAR2(255);
  v_caseTaskPullerFn     NVARCHAR2(255);
  v_roleId               NUMBER;
  v_res                  NUMBER;
  v_errorCode            NUMBER;
  v_errorMessage         NVARCHAR2(255);

  v_WBCaseWorkerOwner    NUMBER;
  v_WBExternalPartyOwner NUMBER;
  v_WBBusinessRoleOwner  NUMBER;
  v_WBSkillOwner         NUMBER;
  v_WBTeamOwner          NUMBER;
  v_WBname               NVARCHAR2(255);
  v_WBcode               NVARCHAR2(255);
  v_WBDescription        NVARCHAR2(4000);
  v_WBisDefault          INTEGER;
  v_WBisPrivate          INTEGER;
  v_WBWorkBasketType     NVARCHAR2(255);
  v_WBid                 NUMBER;
  v_WBlastID             NUMBER;
BEGIN
  :affectedRows    := 0;
  v_errorCode      := 0;
  v_errorMessage   := '';
  :SuccessResponse := EMPTY_CLOB();

  v_objectid         := :ID;
  v_objecttype       := UPPER(:OBJECTTYPE);
  v_groupid          := :GROUPID;
  v_name             := :NAME;
  v_code             := UPPER(:CODE);
  v_description      := :DESCRIPTION;
  v_owner            := :OWNER;
  v_taskPullerFn     := :TASKPULLERFN;
  v_casePullerFn     := :CASEPULLERFN;
  v_caseTaskPullerFn := :CASETASKPULLERFN;
  v_roleId           := :ROLEID;
  :accessSubjectId   := NULL;

  v_WBCaseWorkerOwner    := NULL;
  v_WBExternalPartyOwner := NULL;
  v_WBBusinessRoleOwner  := NULL;
  v_WBSkillOwner         := NULL;
  v_WBTeamOwner          := NULL;
  v_WBisDefault          := 1;
  v_WBisPrivate          := 1;
  v_WBWorkBasketType     := 'PERSONAL';
  v_WBid                 := NULL;

  -- Parameters validation
  IF (v_name = '' OR v_name IS NULL) THEN
    v_errorMessage := 'Name could not be empty';
    v_errorCode    := 1;
    GOTO cleanup;
  END IF;

  IF (v_code = '' OR v_code IS NULL) THEN
    v_errorMessage := 'CODE can not be empty';
    v_errorCode    := 2;
    GOTO cleanup;
  END IF;

  IF (v_objecttype = '' OR v_objecttype IS NULL) THEN
    BEGIN
      v_errorMessage := 'Object Type could not be empty';
      v_errorCode    := 3;
      GOTO cleanup;
    END;
  END IF;

  -- get correct Object Type Name
  CASE v_objecttype
    WHEN 'TEAM' THEN
      v_objecttypename := 'Team';
    WHEN 'SKILL' THEN
      v_objecttypename := 'Skill';
    WHEN 'BUSINESSROLE' THEN
      v_objecttypename := 'Business Role';
    WHEN 'WORKBASKET' THEN
      v_objecttypename := 'Workbasket';
    ELSE
      :SuccessResponse := '';
      v_errorMessage   := 'Object Type {{MESS_OBJECTTYPE}} is not recognized!';
      v_res            := LOC_i18n(MessageText   => v_errormessage,
                                   MessageResult => v_errormessage,
                                   MessageParams => NES_TABLE(Key_Value('MESS_OBJECTTYPE', v_objecttype)));
      v_errorCode      := 4;
      GOTO cleanup;
  END CASE;

  v_WBDescription := 'Automatically created default personal Workbasket for the' || ' ''' || v_name || ''' ' || v_objecttypename;

  --set success message
  IF v_objectid IS NOT NULL THEN
    v_res := LOC_i18n(MessageText   => 'Updated {{MESS_NAME}} {{MESS_OBJECTTYPE}}',
                      MessageResult => :SuccessResponse,
                      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_name), Key_Value('MESS_OBJECTTYPE', v_objecttypename)));
  ELSE
    v_res := LOC_i18n(MessageText   => 'Created {{MESS_NAME}} {{MESS_OBJECTTYPE}}',
                      MessageResult => :SuccessResponse,
                      MessageParams => NES_TABLE(Key_Value('MESS_NAME', v_name), Key_Value('MESS_OBJECTTYPE', v_objecttypename)));
  END IF;

  BEGIN
    --add new record or update existing one
    CASE v_objecttype
      WHEN 'TEAM' THEN
        BEGIN
          v_res := f_PPL_CreateModifyTeamFn(AppBaseGroup => v_groupid,
                                            NAME         => v_name,
                                            Code         => v_code,
                                            Description  => v_description,
                                            Id           => v_objectid,
                                            ResultId     => v_lastID,
                                            ErrorCode    => v_errorCode,
                                            ErrorMessage => v_errorMessage);
          IF (v_errorCode = 0) THEN
            v_WBTeamOwner := v_lastID;
            v_WBname      := v_name;
            v_WBcode      := f_UTIL_calcUniqueCode(BaseCode => 'TEAM' || '_' || v_code, TableName => 'TBL_PPL_WORKBASKET');
          
            IF (v_objectid IS NOT NULL) THEN
              BEGIN
                SELECT col_id INTO v_WBid FROM tbl_ppl_workbasket WHERE col_workbasketteam = v_objectid;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  NULL;
              END;
            END IF;
          ELSE
            ROLLBACK;
            :SuccessResponse := '';
            GOTO cleanup;
          END IF;
          :recordId := v_lastID;
        END;
      WHEN 'SKILL' THEN
        BEGIN
          v_res := f_PPL_CreateModifySkillFn(NAME         => v_name,
                                             Code         => v_code,
                                             Description  => v_description,
                                             Id           => v_objectid,
                                             ResultId     => v_lastID,
                                             ErrorCode    => v_errorCode,
                                             ErrorMessage => v_errorMessage);
          IF (v_errorCode = 0) THEN
            v_WBSkillOwner := v_lastID;
            v_WBname       := v_name;
            v_WBcode       := f_UTIL_calcUniqueCode(BaseCode => 'SKILL' || '_' || v_code, TableName => 'TBL_PPL_WORKBASKET');
            IF (v_objectid IS NOT NULL) THEN
              BEGIN
                SELECT col_id INTO v_WBid FROM tbl_ppl_workbasket WHERE col_workbasketskill = v_objectid;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  NULL;
              END;
            END IF;
          ELSE
            ROLLBACK;
            :SuccessResponse := '';
            GOTO cleanup;
          END IF;
          :recordId := v_lastID;
        END;
      WHEN 'BUSINESSROLE' THEN
        BEGIN
          v_res := f_PPL_CreateModifyBRFn(AppBaseRole  => v_roleid,
                                          NAME         => v_name,
                                          Code         => v_code,
                                          Description  => v_description,
                                          Id           => v_objectid,
                                          ResultId     => v_lastID,
                                          ErrorCode    => v_errorCode,
                                          ErrorMessage => v_errorMessage);
          IF (v_errorCode = 0) THEN
            v_WBBusinessRoleOwner := v_lastID;
            v_WBname              := v_name;
            v_WBcode              := f_UTIL_calcUniqueCode(BaseCode => 'BUSINESSROLE' || '_' || v_code, TableName => 'TBL_PPL_WORKBASKET');
            IF (v_objectid IS NOT NULL) THEN
              BEGIN
                SELECT col_id INTO v_WBid FROM tbl_ppl_workbasket WHERE col_workbasketbusinessrole = v_objectid;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  NULL;
              END;
            END IF;
          ELSE
            ROLLBACK;
            :SuccessResponse := '';
            GOTO cleanup;
          END IF;
          :recordId := v_lastID;
        END;
      WHEN 'WORKBASKET' THEN
        BEGIN
          v_WBname            := v_name;
          v_WBcode            := v_code;
          v_WBDescription     := v_description;
          v_WBisDefault       := 0;
          v_WBisPrivate       := 0;
          v_WBWorkBasketType  := 'GROUP';
          v_WBid              := v_objectid;
          v_WBCaseWorkerOwner := v_owner;
        END;
      ELSE
        :SuccessResponse := '';
        GOTO cleanup;
    END CASE;
  
    --create/update Work Basket
    v_res := f_PPL_CreateModifyWBFn(CaseWorkerOwner    => v_WBCaseWorkerOwner,
                                    ExternalPartyOwner => v_WBExternalPartyOwner,
                                    BusinessRoleOwner  => v_WBBusinessRoleOwner,
                                    SkillOwner         => v_WBSkillOwner,
                                    TeamOwner          => v_WBTeamOwner,
                                    NAME               => v_WBname,
                                    Code               => v_WBcode,
                                    Description        => v_WBDescription,
                                    IsDefault          => v_WBisDefault,
                                    IsPrivate          => v_WBisPrivate,
                                    WorkBasketType     => v_WBWorkBasketType,
                                    Id                 => v_WBid,
                                    ResultId           => v_WBlastID,
                                    ErrorCode          => v_errorCode,
                                    ErrorMessage       => v_errorMessage,
                                    TASKPULLERFN       => v_taskPullerFn,
                                    CASEPULLERFN       => v_casePullerFn,
                                    CASETASKCOUNTERFN  => v_caseTaskPullerFn);
  
    IF (v_errorCode <> 0) THEN
      ROLLBACK;
      :SuccessResponse := '';
      GOTO cleanup;
    END IF;
  
    IF (v_objecttype = 'WORKBASKET') THEN
      :recordId := v_WBlastID;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errorMessage   := SQLERRM;
      v_errorCode      := SQLCODE;
      :SuccessResponse := '';
  END;

  <<cleanup>>
  :errorMessage := v_errorMessage;
  :errorCode    := v_errorCode;
END;