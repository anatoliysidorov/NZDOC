  --start of rule  
  
  --this rule has a CreationMode parameter what define a 
  --creation of version
  --please use a  SINGLE_VER for operate only one version 
  --and MULTIPLE_VER for create a many versions of milestone
  --DCM-5483
  
  DECLARE 
    v_CaseSysTypeId    NUMBER;
    v_Input            CLOB;
    v_count            NUMBER;
    v_iconcode         NVARCHAR2(255);
    v_name             NVARCHAR2(255);
    v_code             NVARCHAR2(255);    
    v_stateConfigId    NUMBER;
    v_stateConfigIdNew NUMBER;
    v_StateId          NUMBER;
    v_Revision         INTEGER;
    v_versionId        NUMBER; 
    v_CreationMode     NVARCHAR2(255);

    --temp variables 
    v_tempErrMsg    NCLOB; 
    v_tempErrCd     INTEGER;
    v_Result        NUMBER;

    --errors variables
    v_errorCode     NUMBER;
    v_errorMessage  NVARCHAR2(255);

  BEGIN
    --init
    v_CaseSysTypeId := :CaseSysTypeId;
    v_Input         := :Input;
    v_name          := :Name;
    v_code          := :Code;
    v_iconcode      := :IconCode;
    v_CreationMode  := NVL(:CreationMode, 'SINGLE_VER'); --STRONG MUST BE IN 'SINGLE_VER' or 'MULTIPLE_VER'
    
    SuccessResponse := EMPTY_CLOB();
        
    v_count             := NULL;
    v_stateConfigId     := NULL;
    v_stateConfigIdNew  := NULL;
    v_Result        := NULL;
    v_versionId     := NULL; 


    IF (v_CreationMode NOT IN ('SINGLE_VER', 'MULTIPLE_VER')) THEN
      v_errorCode :=101;
      v_errorMessage :='CreationMode value is incorrect. Strong must be in ''SINGLE_VER'' or ''MULTIPLE_VER''';
      GOTO cleanup;
    END IF;
         
    IF (v_code IS NULL) THEN
      v_errorCode :=101;
      v_errorMessage :='Milestone code cannot be NULL';
      GOTO cleanup;
    END IF;
  
    IF (v_name IS NULL) THEN
      v_errorCode :=101;
      v_errorMessage :='Milestone name cannot be NULL';
      GOTO cleanup;
    END IF;

    --check input data
    IF (v_CaseSysTypeId IS NULL) THEN
      v_errorCode :=101;
      v_errorMessage :='Case Type Id cannot be NULL';
      GOTO cleanup;
    END IF;
    
    --validate a model
    v_Result := f_STP_ValidateCaseCustomData(ERRORCODE    =>v_tempErrCd, 
                                             ERRORMESSAGE =>v_tempErrMsg, 
                                             INPUT        =>v_Input, 
                                             STATECONFIG  =>NULL--preserve for a future
                                             );
    IF NVL(v_tempErrCd, 0) <>0 THEN
      v_errorCode :=v_tempErrCd;
      v_errorMessage :=v_tempErrMsg;
      GOTO cleanup;
    END IF;    
    
    --define if custom state machine is exists
    BEGIN
      SELECT  COUNT(1) INTO v_count
      FROM TBL_DICT_STATECONFIG
      WHERE COL_CASESYSTYPESTATECONFIG=v_CaseSysTypeId AND COL_ISCURRENT=1;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      v_count :=0;
    END; 


    --create a new records
    IF v_count=0 THEN  

      --version record of state config
      INSERT INTO TBL_DICT_VERSION(COL_NAME, COL_CODE) VALUES(v_name, v_code)
      RETURNING col_id INTO v_versionId;
    
      --new state config record
      INSERT INTO TBL_DICT_STATECONFIG(COL_CONFIG, COL_TYPE, COL_NAME, COL_ICONCODE, COL_CODE,
                  COL_STATECONFSTATECONFTYPE, 
                  COL_CASESYSTYPESTATECONFIG, COL_ISCURRENT,COL_REVISION, COL_STATECONFIGVERSION)
      VALUES(v_Input, 'MILESTONE', v_name,  v_iconcode, v_code, 
            (SELECT col_id FROM TBL_DICT_STATECONFIGTYPE WHERE COL_CODE='MILESTONE'),
            v_CaseSysTypeId,1,1, v_versionId)
      RETURNING col_id INTO v_stateConfigIdNew;
      
      --link with casesystype via "version"
      UPDATE TBL_DICT_CASESYSTYPE 
      SET
       COL_DICTVERCASESYSTYPE=v_versionId
      WHERE COl_ID=v_CaseSysTypeId;      
           
    END IF;--create a new records


    --update existing record
    IF v_count=1 THEN 
      IF v_CreationMode = 'MULTIPLE_VER' THEN
        --define an existing state config data
        BEGIN
          SELECT COL_ID,  COL_NAME, COL_REVISION
          INTO v_stateConfigId, v_name, v_Revision
          FROM TBL_DICT_STATECONFIG
          WHERE COL_CASESYSTYPESTATECONFIG=v_CaseSysTypeId AND COL_ISCURRENT=1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
          v_errorCode := 102;
          v_errorMessage :='A State Config record not found';
          GOTO cleanup;
        WHEN TOO_MANY_ROWS THEN
          v_errorCode := 102;
          v_errorMessage :='Cant define a State Config record';
          GOTO cleanup;
        END; 
      
        BEGIN
          SELECT COL_CODE INTO v_code
          FROM TBL_DICT_STATECONFIG
          WHERE COL_CASESYSTYPESTATECONFIG=v_CaseSysTypeId AND COL_REVISION=1;
        EXCEPTION       
          WHEN OTHERS THEN NULL;
        END; 

        v_Revision :=v_Revision+1;
        v_code := v_code||'V'||TO_CHAR(v_Revision);
              
        --create a new record
        FOR rec IN 
          (SELECT sc.COL_CONFIG, sc.COL_TYPE, sc.COL_NAME, sc.COL_ICONCODE, sc.COL_REVISION, 
                  sc.COL_STATECONFSTATECONFTYPE, sc.COL_CASESYSTYPESTATECONFIG, sc.COL_STATECONFIGVERSION
          FROM TBL_DICT_STATECONFIG sc
          WHERE sc.COL_ID=v_stateConfigId)
          LOOP
            INSERT INTO TBL_DICT_STATECONFIG(COL_CONFIG, COL_TYPE, COL_NAME, COL_ICONCODE, 
                        COL_STATECONFSTATECONFTYPE, COL_CODE, 
                        COL_CASESYSTYPESTATECONFIG, COL_ISCURRENT,COL_REVISION, COL_STATECONFIGVERSION)
            VALUES(v_Input, rec.COL_TYPE, v_name, v_iconcode,
                   rec.COL_STATECONFSTATECONFTYPE, v_code, 
                   rec.COL_CASESYSTYPESTATECONFIG, 1, v_Revision, rec.COL_STATECONFIGVERSION)
  
             RETURNING COL_ID INTO v_stateConfigIdNew;
        END LOOP;
  
        --update old state config record
        UPDATE TBL_DICT_STATECONFIG
        SET COL_ISCURRENT =0
        WHERE COL_ID=v_stateConfigId; 
      END IF; --'MULTIPLE_VER'


      IF v_CreationMode = 'SINGLE_VER' THEN
        --define an existing state config data
        BEGIN
          SELECT COL_ID
          INTO v_stateConfigId
          FROM TBL_DICT_STATECONFIG
          WHERE COL_CASESYSTYPESTATECONFIG=v_CaseSysTypeId AND COL_ISCURRENT=1;
        EXCEPTION WHEN NO_DATA_FOUND THEN
          v_errorCode := 102;
          v_errorMessage :='A State Config record not found';
          GOTO cleanup;
        WHEN TOO_MANY_ROWS THEN
          v_errorCode := 102;
          v_errorMessage :='Cant define a State Config record';
          GOTO cleanup;
        END;

        v_stateConfigIdNew:=v_stateConfigId;

        UPDATE TBL_DICT_STATECONFIG         
        SET  COL_NAME     =v_name,
            COL_ICONCODE  =v_iconcode,
            COL_CONFIG    =v_Input
        WHERE COL_ID=v_stateConfigIdNew;
      END IF;--'SINGLE_VER'
    END IF;--update existing record

    
    IF (v_count IN (0, 1)) AND (v_Input IS NOT NULL)  THEN      
      --create a custom data
      v_Result := f_STP_CreateCaseCustomData(ERRORCODE    =>v_tempErrCd, 
                                             ERRORMESSAGE =>v_tempErrMsg, 
                                             INPUT        =>v_Input, 
                                             STATECONFIG  =>v_stateConfigIdNew,
                                             CREATIONMODE =>v_CreationMode);
      IF NVL(v_tempErrCd, 0) <>0 THEN
        v_errorCode :=v_tempErrCd;
        v_errorMessage :=v_tempErrMsg;
        GOTO cleanup;
      END IF;
    END IF;
    
    IF v_count NOT IN (0, 1)  THEN
        v_errorCode := 102;
        v_errorMessage :='Cant define a StateConfig record with code "'||v_code||'"';
        GOTO cleanup;    
    END IF;
        
    --exit block           
    v_errorCode :=NULL;
    v_errorMessage :='Milestone "'||v_name||'" was successfully modified';

    :SuccessResponse := v_errorMessage; 
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;
    :NEW_STATECONFIGID := v_stateConfigIdNew;  
    RETURN 0;
  
  
    --error block
    <<cleanup>>
    :SuccessResponse := '';
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;  
    :NEW_STATECONFIGID := v_stateConfigIdNew;  
    RETURN -1;  

  END;--eof rule