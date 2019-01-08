DECLARE

    --MAIN VARIABLES  
    v_Id               INTEGER;
    v_note             NCLOB;
    v_notename         NVARCHAR2(255);
    v_case_Id          INTEGER;
    v_task_Id          INTEGER;
    v_ExternalParty_Id INTEGER;
    v_CaseWorker_Id    INTEGER;
    v_Document_Id      INTEGER;
v_result INT;
	v_TargetID INT;
	v_TargetType NVARCHAR2(30);

    --DEFAULT
    v_errorcode      NUMBER;
    v_errormessage   NVARCHAR2(255);

    --ADDITIONAL VARIABLES  
    v_nowdatetime DATE;
    v_user        NVARCHAR2(255);

BEGIN

    --SET MAIN VARIABLES  
    v_notename         := 'Untitled';
    v_Id               := :Id;
    v_note             := :Note;
    v_case_Id          := :Case_Id;
    v_task_Id          := :Task_Id;
    v_ExternalParty_Id := :ExternalParty_Id;
    v_CaseWorker_Id    := :CaseWorker_Id;
    v_Document_Id      := :Document_Id;

    --DEFAULT
    v_errorcode    := 0;
    v_errormessage := '';

    --SET ADDITIONAL VARIABLES  
    :affectedRows := 0;
    :recordId     := 0;
    v_nowdatetime := SYSDATE;
    v_user        := '@TOKEN_USERACCESSSUBJECT@';

  --DETERMINE CASE ID IF IT'S EMPTY
    IF v_task_Id IS NOT NULL THEN

        BEGIN
            SELECT COL_CASETASK INTO v_case_Id FROM TBL_TASK tsk WHERE tsk.COL_ID = v_task_Id;
        EXCEPTION
            WHEN no_data_found THEN
                v_case_Id := NULL;
        END;

    END IF;

    IF v_Document_Id IS NOT NULL AND v_Document_Id = 0 THEN
		v_Document_Id := null;
/*		
        :affectedRows  := 0;
        v_errorcode    := 2;
        v_errormessage := 'Document id cannot be empty for this operation';
        GOTO cleanup;
*/		
    END IF;

    IF v_Id IS NULL AND v_case_Id IS NULL AND v_task_Id IS NULL AND v_ExternalParty_Id IS NULL AND v_CaseWorker_Id IS NULL AND v_Document_Id IS NULL  THEN
        :affectedRows  := 0;
        v_errorcode    := 2;
        v_errormessage := 'ID or Case_Id or Task_Id or ExternalParty_Id or CaseWorker_Id or Document_Id cannot be empty for this operation';
        GOTO cleanup;
    END IF;

    BEGIN
        IF (v_Id IS NOT NULL) THEN
            BEGIN
                UPDATE TBL_NOTE tn SET tn.COL_NOTE = v_note WHERE tn.COL_ID = v_Id;
            END;
        ELSE

            BEGIN
                --ELSE MAKE A NEW ONE  
                INSERT INTO TBL_NOTE
                    (COL_NOTENAME,
                    COL_NOTE,
                    COL_CREATEDBY,
                    COL_CREATEDDATE,
                    COL_MODIFIEDBY,
                    COL_MODIFIEDDATE,
                    COL_OWNER,
                    COL_VERSION,
                    COL_CASENOTE,
                    COL_TASKNOTE,
                    COL_EXTERNALPARTYNOTE,
                    COL_NOTEPPL_CASEWORKER,
                    COL_NOTEDOCUMENT)
                VALUES
                    (v_notename,
                    v_note,
                    v_user,
                    v_nowdatetime,
                    v_user,
                    v_nowdatetime,
                    v_user,
                    1,
                    v_case_Id,
                    v_task_Id,
                    v_ExternalParty_Id,
                    v_CaseWorker_Id,
                    v_Document_Id);

                SELECT GEN_TBL_NOTE.CURRVAL INTO :recordId FROM DUAL;
				
				IF v_task_Id > 0 THEN
					v_TargetID := v_task_Id ;
					v_TargetType := 'TASK';
				ELSIF v_case_Id > 0 THEN
					v_TargetID := v_case_Id ;
					v_TargetType := 'CASE';
				END IF;
				
				IF v_TargetID > 0 THEN
					v_result := f_HIST_createHistoryFn(
						AdditionalInfo => NULL,  
						IsSystem=>0, 
						Message=> NULL,
						MessageCode => 'NoteCreated', 
						TargetID => v_TargetID, 
						TargetType=>v_TargetType
					);				
				END IF;
				
                :affectedRows := 1;
            END;

        END IF;

        EXCEPTION
            WHEN OTHERS THEN
                :affectedRows  := 0;
                v_errorcode    := 1;
                v_errormessage := 'There was an error creating a note';
                GOTO cleanup;
    END;

    <<cleanup>>
        :errorCode    := v_errorcode;
        :errorMessage := v_errormessage;
END;