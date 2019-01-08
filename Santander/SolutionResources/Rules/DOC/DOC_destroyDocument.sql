DECLARE
  v_res          NUMBER;
  workitemId     NUMBER;
  v_errorCode    NUMBER;
  v_errorMessage NVARCHAR2(255);

  v_message NCLOB;
  v_title   NVARCHAR2(255);
  v_wiids   NVARCHAR2(255);
BEGIN

  v_wiids        := '';
  v_errorMessage := '';
  v_errorCode    := 0;
  :ErrorCode     := 0;
  :ErrorMessage  := '';
  :ExecutionLog  := '';

  FOR rec IN (SELECT to_number(column_value) AS id FROM TABLE(asf_split(:IDS, ','))) LOOP
    SELECT col_doc_documentpi_workitem INTO workitemId FROM tbl_doc_document WHERE col_id = rec.id;
    IF (workitemId IS NULL) THEN
      v_res := f_doc_destroydocumentfn(case_id                 => NULL,
                                       casetype_id             => NULL,
                                       caseworker_id           => NULL,
                                       errorcode               => v_errorCode,
                                       errormessage            => v_errorMessage,
                                       extparty_id             => NULL,
                                       ids                     => to_char(rec.id),
                                       task_id                 => NULL,
                                       team_id                 => NULL,
                                       token_domain            => f_UTIL_getDomainFn(),
                                       token_useraccesssubject => '@TOKEN_USERACCESSSUBJECT@');
    
      IF (v_errorCode > 0) THEN
        SELECT col_name INTO v_title FROM tbl_doc_document WHERE col_id = rec.id;
        v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => v_title || ': ' || v_errorMessage);
      END IF;
    
    ELSE
    
      v_wiids := v_wiids || ',' || TO_CHAR(workitemId);
    
    END IF;
  END LOOP;

  IF (LENGTH(v_wiids) > 0) THEN
    v_wiids := SUBSTR(v_wiids, 2, LENGTH(v_wiids));
    FOR rec IN (SELECT DISTINCT to_number(column_value) AS workitemId FROM TABLE(asf_split(v_wiids, ','))) LOOP
      v_res := f_PI_allowAction(WorkitemId      => rec.workitemId,
                                ActionCode      => 'PERMANENT_DELETE',
                                CurrentActivity => 'root_CS_STATUS_DOCINDEXINGSTATES_REVIEWED',
                                ErrorCode       => v_errorCode,
                                ErrorMessage    => v_errorMessage);
    
      IF (v_errorCode > 0) THEN
        BEGIN
          SELECT col_title INTO v_title FROM tbl_pi_workitem WHERE col_id = rec.workitemId;
        EXCEPTION
          WHEN no_data_found THEN
            v_title := '';
        END;
        v_message := f_UTIL_addToMessage(originalMsg => v_message, newMsg => v_title || ': ' || v_errorMessage);
        CONTINUE;
      END IF;
    
      v_res := f_pi_permanentdeletefn(WorkitemId         => rec.workitemId,
                                      ErrorMessage       => v_errorMessage,
                                      ErrorCode          => v_errorCode,
                                      TokenDomain        => f_UTIL_getDomainFn(),
                                      TokenAccessSubject => '@TOKEN_USERACCESSSUBJECT@');
    END LOOP;
  END IF;

  IF (v_message IS NOT NULL) THEN
    :ErrorCode    := 101;
    :ErrorMessage := 'There was an error deleting folder/document(s)';
    :ExecutionLog := v_message;
  END IF;
END;
