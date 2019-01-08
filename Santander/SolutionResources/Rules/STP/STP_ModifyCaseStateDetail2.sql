    DECLARE 
    v_CaseSysTypeId   NUMBER;
    v_Input           CLOB; 
    v_SuccessResponse CLOB;    
    v_iconcode        NVARCHAR2(255);
    v_name            NVARCHAR2(255);
    v_code           NVARCHAR2(255);
    
    --temp variables 
    v_Result        NUMBER;

    --errors variables
    v_errorCode     NUMBER;
    v_errorMessage  NVARCHAR2(255);
    v_stateConfigId NUMBER;

  BEGIN
    --init
    v_CaseSysTypeId := :CaseSysTypeId;
    v_Input         := :Input;
    v_name          := :Name;
    v_code          := :Code;
    v_iconcode      := :IconCode;
    
    v_SuccessResponse :=EMPTY_CLOB();
    v_Result        := NULL;
    v_stateConfigId := NULL; 

    --validation on Id is Exist
    IF NVL(v_CaseSysTypeId, 0) > 0 THEN
      v_Result := f_UTIL_getId(ERRORCODE => v_errorcode, 
                               ERRORMESSAGE => v_errormessage, 
                               ID => v_casesystypeid, 
                               TABLENAME => 'TBL_DICT_CASESYSTYPE');
      IF v_errorcode > 0 THEN
        :SuccessResponse := '';
        :ErrorCode := v_errorCode;
        :ErrorMessage := v_errorMessage;  
        :NEW_STATECONFIGID := 0; 
      END IF;
    END IF;
        
    --this func has a CreationMode parameter what define a 
    --creation of version
    --please use a  SINGLE_VER for operate only one version 
    --and MULTIPLE_VER for create a many versions of milestone
    --DCM-5483  
    --(ask VV)
    v_Result := f_STP_ModifyCaseStateDetailFn(SUCCESSRESPONSE=>v_SuccessResponse,
                                              CASESYSTYPEID  =>v_CaseSysTypeId, 
                                              CODE           =>v_code, 
                                              ERRORCODE      =>v_errorCode, 
                                              ERRORMESSAGE   =>v_errorMessage, 
                                              ICONCODE       =>v_iconcode, 
                                              INPUT          =>v_Input, 
                                              NAME           =>v_name,
                                              NEW_STATECONFIGID =>v_stateConfigId,
                                              CREATIONMODE   => 'MULTIPLE_VER');
  
    :SuccessResponse := v_SuccessResponse;
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;
    :NEW_STATECONFIGID := v_stateConfigId;
     
  END;