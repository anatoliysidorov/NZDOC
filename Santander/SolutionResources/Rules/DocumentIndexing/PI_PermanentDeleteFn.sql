DECLARE
    v_workitemId NUMBER;
    v_docIds NVARCHAR2(32767);
    v_res NUMBER;
BEGIN

    v_workitemId := :WorkitemId;

    SELECT 
        listagg(to_char(col_id), ',') WITHIN GROUP (ORDER BY col_id)  into v_docIds
    FROM tbl_doc_document 
    WHERE COL_DOC_DOCUMENTPI_WORKITEM = v_workitemId;

    IF(v_docIds IS NOT NULL) THEN
        v_res := f_doc_destroydocumentfn(case_id                => NULL,
                                        casetype_id             => NULL,
                                        caseworker_id           => NULL,
                                        errorcode               => :ErrorCode,
                                        errormessage            => :ErrorMessage,
                                        extparty_id             => NULL,
                                        ids                     => v_docIds,
                                        task_id                 => NULL,
                                        team_id                 => NULL,
                                        token_domain            => :TokenDomain,
                                        token_useraccesssubject => :TokenAccessSubject);
    END IF;

END;