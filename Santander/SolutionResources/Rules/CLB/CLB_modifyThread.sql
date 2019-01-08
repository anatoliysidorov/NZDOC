DECLARE
  v_id                   NUMBER;
  v_code                 NVARCHAR2(255);
  v_status               NVARCHAR2(255);
  v_message              NCLOB;
  v_caseId               NUMBER;
  v_parentThreadId       NUMBER;
  v_errorcode            NUMBER;
  v_errormessage         NCLOB;
  v_TargetID             INT;
  v_TargetType           NVARCHAR2(30);
  v_result               INT;
  v_workbasketId         INT;
  allowCreateDiscussion  NVARCHAR2(30);
  allowCommentDiscussion NVARCHAR2(30);
  v_count                NUMBER;
  allowEditComment       NVARCHAR2(30);
  v_res                  NUMBER;
  v_tmp_successResponse  NVARCHAR2(255);
  v_validationresult     NUMBER;
  v_Attributes           NVARCHAR2(4000);
  v_AttributesDefault    NVARCHAR2(4000);
  v_historymsg           NCLOB;
  v_outData CLOB;

BEGIN
  --input/output
  v_id             := :Id;
  v_code           := :Code;
  v_status         := Nvl(:Status, 'ACTIVE');
  v_message        := :Message;
  v_parentThreadId := :ParentThread;
  v_workbasketId   := NULL;
  v_caseId         := :Case_Id;
  :affectedRows    := 0;

  --init
  v_errorcode            := 0;
  v_errormessage         := '';
  allowCreateDiscussion  := '';
  allowCommentDiscussion := '';
  v_count                := 0;
  allowEditComment       := '';
  v_Attributes           := NULL;
  v_historymsg           := NULL;
  v_AttributesDefault    := NULL;
  v_outData      := NULL;

  --set success message
  IF v_id IS NOT NULL THEN
    :SuccessResponse := 'Updated';
  ELSE
    :SuccessResponse := 'Created';
  END IF;

  :SuccessResponse := :SuccessResponse || ' thread';

  BEGIN
    SELECT col_allowcommentdiscussion,
           col_allowcreatediscussion,
           col_alloweditcomment
      INTO allowCommentDiscussion,
           allowCreateDiscussion,
           allowEditComment
      FROM tbl_threadsetting
     WHERE rownum = 1;
  EXCEPTION
    WHEN no_data_found THEN
      allowCommentDiscussion := 'ANYONE';
      allowCreateDiscussion  := 'ANYONE';
      allowEditComment       := 'ONLY_CREATOR';
  END;

  v_AttributesDefault := '<AllowCommentDiscussion>' || TO_CHAR(allowCommentDiscussion) || '</AllowCommentDiscussion>' || '<AllowCreateDiscussion>' ||
                         TO_CHAR(allowCreateDiscussion) || '</AllowCreateDiscussion>' || '<AllowEditComment>' || TO_CHAR(allowEditComment) ||
                         '</AllowEditComment>' || '<ParentThreadId>' || TO_CHAR(v_parentThreadId) || '</ParentThreadId>';

  v_Attributes := v_AttributesDefault || '<ThreadId>' || TO_CHAR(v_id) || '</ThreadId>' || '<ThreadCode>' || TO_CHAR(v_code) || '</ThreadCode>' ||
                  '<ThreadStatus>' || TO_CHAR(v_status) || '</ThreadStatus>';

  BEGIN
    IF v_id IS NULL THEN
      IF (v_parentThreadId IS NOT NULL) THEN
        --Allow Comment Discussion
        IF (allowCommentDiscussion = 'ONLY_PART') THEN
          SELECT COUNT(*)
            INTO v_count
            FROM tbl_thread t
           INNER JOIN tbl_threadcaseworker tcw
              ON tcw.col_threadid = t.col_id
           INNER JOIN tbl_ppl_caseworker cw
              ON cw.col_id = tcw.col_caseworkerid
           INNER JOIN vw_users usr
              ON usr.userid = cw.col_userid
           WHERE t.col_id = v_parentThreadId
             AND usr.accesssubjectcode = '@TOKEN_USERACCESSSUBJECT@';

          IF (v_count = 0) THEN
            v_errorcode    := 101;
            v_errormessage := 'You don''t have permissions for this action';
            GOTO cleanup;
          END IF;
        END IF;

        BEGIN
          SELECT wb.col_id
            INTO v_workbasketId
            FROM vw_ppl_activecaseworkersusers cwu
           INNER JOIN tbl_ppl_workbasket wb
              ON cwu.id = wb.col_caseworkerworkbasket
           INNER JOIN tbl_dict_workbaskettype wbt
              ON wbt.col_id = wb.col_workbasketworkbaskettype
             AND wbt.col_code = 'PERSONAL'
           WHERE cwu.accode = sys_context('CLIENTCONTEXT', 'accesssubject')
             AND wb.col_isdefault = 1;
        EXCEPTION
          WHEN no_data_found THEN
            v_workbasketId := NULL;
        END;

        /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -THREAD_COMMENT_CREATED- AND*/
        /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
        v_validationresult := 1;
        v_result           := F_dcm_processcommonevent(InData           => NULL,
                                                       OutData          => v_outData, 
                                                       Attributes       => v_Attributes,
                                                       code             => NULL,
                                                       caseid           => v_caseid,
                                                       casetypeid       => NULL,
                                                       commoneventtype  => 'THREAD_COMMENT_CREATED',
                                                       errorcode        => v_errorcode,
                                                       errormessage     => v_errormessage,
                                                       eventmoment      => 'BEFORE',
                                                       eventtype        => 'VALIDATION',
                                                       historymessage   => v_historymsg,
                                                       procedureid      => NULL,
                                                       taskid           => NULL,
                                                       tasktypeid       => NULL,
                                                       validationresult => v_validationresult);

        /*--write to history*/
        IF v_historymsg IS NOT NULL THEN
          v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                             issystem       => 0,
                                             MESSAGE        => 'Validation Common event(s)',
                                             messagecode    => 'CommonEvent',
                                             targetid       => v_caseid,
                                             targettype     => 'CASE');
        END IF;

        IF NVL(v_validationresult, 0) = 0 THEN
          GOTO cleanup;
        END IF;

        /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -THREAD_COMMENT_CREATED- AND*/
        /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
        v_validationresult := 1;

        v_result := F_dcm_processcommonevent(InData           => NULL,
                                             OutData          => v_outData,
                                             Attributes       => v_Attributes,
                                             code             => NULL,
                                             caseid           => v_caseid,
                                             casetypeid       => NULL,
                                             commoneventtype  => 'THREAD_COMMENT_CREATED',
                                             errorcode        => v_errorcode,
                                             errormessage     => v_errormessage,
                                             eventmoment      => 'BEFORE',
                                             eventtype        => 'ACTION',
                                             historymessage   => v_historymsg,
                                             procedureid      => NULL,
                                             taskid           => NULL,
                                             tasktypeid       => NULL,
                                             validationresult => v_validationresult);

        /*--write to history*/
        IF v_historymsg IS NOT NULL THEN
          v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                             issystem       => 0,
                                             MESSAGE        => 'Action Common event(s)',
                                             messagecode    => 'CommonEvent',
                                             targetid       => v_caseid,
                                             targettype     => 'CASE');
        END IF;

        --MAIN ACTION
        INSERT INTO tbl_thread
          (col_code,
           col_datestarted,
           col_threadsourcetask,
           col_threadtargettask,
           col_message,
           col_datemessage,
           col_messageworkbasket,
           col_threadworkbasket,
           col_status,
           col_parentmessageid,
           col_threadcase)
          SELECT col_code,
                 col_datestarted,
                 col_threadsourcetask,
                 col_threadtargettask,
                 v_message,
                 SYSDATE,
                 v_workbasketId,
                 v_workbasketId,
                 col_status,
                 v_parentThreadId,
                 col_threadcase
            FROM tbl_thread
           WHERE col_id = v_parentThreadId;

        SELECT gen_tbl_thread.currval INTO v_id FROM dual;

        -- reinit thread data after create it
        v_Attributes := v_AttributesDefault || '<ThreadId>' || TO_CHAR(v_id) || '</ThreadId>' || '<ThreadCode>' || TO_CHAR(v_code) || '</ThreadCode>' ||
                        '<ThreadStatus>' || TO_CHAR(v_status) || '</ThreadStatus>';

        /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -THREAD_COMMENT_CREATED- AND*/
        /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
        v_validationresult := 1;
        v_result           := F_dcm_processcommonevent(InData           => NULL,
                                                       OutData          => v_outData,
                                                       Attributes       => v_Attributes,
                                                       code             => NULL,
                                                       caseid           => v_caseid,
                                                       casetypeid       => NULL,
                                                       commoneventtype  => 'THREAD_COMMENT_CREATED',
                                                       errorcode        => v_errorcode,
                                                       errormessage     => v_errormessage,
                                                       eventmoment      => 'AFTER',
                                                       eventtype        => 'ACTION',
                                                       historymessage   => v_historymsg,
                                                       procedureid      => NULL,
                                                       taskid           => NULL,
                                                       tasktypeid       => NULL,
                                                       validationresult => v_validationresult);

        /*--write to history*/
        IF v_historymsg IS NOT NULL THEN
          v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                             issystem       => 0,
                                             MESSAGE        => 'Action Common event(s)',
                                             messagecode    => 'CommonEvent',
                                             targetid       => v_caseid,
                                             targettype     => 'CASE');
        END IF;

      ELSE

        --Allow Create Discussion
        IF (allowCreateDiscussion = 'ONLY_CASE_OWNER') THEN
          SELECT COUNT(*)
            INTO v_count
            FROM tbl_case c
           INNER JOIN tbl_ppl_workbasket wb
              ON wb.col_id = c.col_caseppl_workbasket
           INNER JOIN tbl_ppl_caseworker cw
              ON cw.col_id = wb.col_caseworkerworkbasket
           INNER JOIN vw_users usr
              ON usr.userid = cw.col_userid
           WHERE c.col_id = v_caseId
             AND usr.accesssubjectcode = '@TOKEN_USERACCESSSUBJECT@';

          IF (v_count = 0) THEN
            v_errorcode    := 101;
            v_errormessage := 'You don''t have permissions for this action';
            GOTO cleanup;
          END IF;
        END IF;

        /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -THREAD_CREATED- AND*/
        /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
        v_validationresult := 1;

        v_result := F_dcm_processcommonevent(InData           => NULL,
                                             OutData          => v_outData,
                                             Attributes       => v_Attributes,
                                             code             => NULL,
                                             caseid           => v_caseid,
                                             casetypeid       => NULL,
                                             commoneventtype  => 'THREAD_CREATED',
                                             errorcode        => v_errorcode,
                                             errormessage     => v_errormessage,
                                             eventmoment      => 'BEFORE',
                                             eventtype        => 'VALIDATION',
                                             historymessage   => v_historymsg,
                                             procedureid      => NULL,
                                             taskid           => NULL,
                                             tasktypeid       => NULL,
                                             validationresult => v_validationresult);

        /*--write to history*/
        IF v_historymsg IS NOT NULL THEN
          v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                             issystem       => 0,
                                             MESSAGE        => 'Validation Common event(s)',
                                             messagecode    => 'CommonEvent',
                                             targetid       => v_caseid,
                                             targettype     => 'CASE');
        END IF;

        IF NVL(v_validationresult, 0) = 0 THEN
          GOTO cleanup;
        END IF;

        /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -THREAD_CREATED- AND*/
        /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
        v_validationresult := 1;

        v_result := F_dcm_processcommonevent(InData           => NULL,
                                             OutData          => v_outData,
                                             Attributes       => v_Attributes,
                                             code             => NULL,
                                             caseid           => v_caseid,
                                             casetypeid       => NULL,
                                             commoneventtype  => 'THREAD_CREATED',
                                             errorcode        => v_errorcode,
                                             errormessage     => v_errormessage,
                                             eventmoment      => 'BEFORE',
                                             eventtype        => 'ACTION',
                                             historymessage   => v_historymsg,
                                             procedureid      => NULL,
                                             taskid           => NULL,
                                             tasktypeid       => NULL,
                                             validationresult => v_validationresult);

        /*--write to history*/
        IF v_historymsg IS NOT NULL THEN
          v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                             issystem       => 0,
                                             MESSAGE        => 'Action Common event(s)',
                                             messagecode    => 'CommonEvent',
                                             targetid       => v_caseid,
                                             targettype     => 'CASE');
        END IF;

        --MAIN ACTION
        INSERT INTO TBL_THREAD
          (col_code, col_threadcase, col_parentmessageid, col_message, col_status)
        VALUES
          (v_code, v_caseId, v_parentThreadId, v_message, 'ACTIVE')
        RETURNING col_id INTO v_id;

        -- reinit thread data after create
        v_Attributes := v_AttributesDefault || '<ThreadId>' || TO_CHAR(v_id) || '</ThreadId>' || '<ThreadCode>' || TO_CHAR(v_code) || '</ThreadCode>' ||
                        '<ThreadStatus>' || TO_CHAR(v_status) || '</ThreadStatus>';

        /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -THREAD_CREATED- AND*/
        /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
        v_validationresult := 1;
        v_result           := F_dcm_processcommonevent(InData           => NULL,
                                                       OutData          => v_outData,
                                                       Attributes       => v_Attributes,
                                                       code             => NULL,
                                                       caseid           => v_caseid,
                                                       casetypeid       => NULL,
                                                       commoneventtype  => 'THREAD_CREATED',
                                                       errorcode        => v_errorcode,
                                                       errormessage     => v_errormessage,
                                                       eventmoment      => 'AFTER',
                                                       eventtype        => 'ACTION',
                                                       historymessage   => v_historymsg,
                                                       procedureid      => NULL,
                                                       taskid           => NULL,
                                                       tasktypeid       => NULL,
                                                       validationresult => v_validationresult);

        /*--write to history*/
        IF v_historymsg IS NOT NULL THEN
          v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                             issystem       => 0,
                                             MESSAGE        => 'Action Common event(s)',
                                             messagecode    => 'CommonEvent',
                                             targetid       => v_caseid,
                                             targettype     => 'CASE');
        END IF;

        /*The creator of the Discussion Thread should automatically join the Discussion People if it's the  "Only people who are part of the discussion" mode.*/
        IF (allowCommentDiscussion = 'ONLY_PART') THEN
          v_res := f_CLB_addThreadMember(CurrentMode    => 'JOIN',
                                         Id             => NULL,
                                         Ids            => NULL,
                                         ParentThreadId => v_id,
                                         ErrorCode      => v_errorcode,
                                         ErrorMessage   => v_errormessage);

          IF NVL(v_errorcode, 0) <> 0 THEN
            GOTO cleanup;
          END IF;
        END IF;

        IF v_caseId > 0 THEN
          v_TargetID   := v_caseId;
          v_TargetType := 'CASE';
        END IF;

        IF v_TargetID > 0 THEN
          v_result := f_HIST_createHistoryFn(AdditionalInfo => NULL,
                                             IsSystem       => 0,
                                             Message        => NULL,
                                             MessageCode    => 'ThreadCreated',
                                             TargetID       => v_TargetID,
                                             TargetType     => v_TargetType);
        END IF;
      END IF;

    ELSE

      IF (v_parentThreadId IS NOT NULL) THEN
        --Allow Edit Comment
        IF (allowEditComment = 'ONLY_CREATOR') THEN
          SELECT COUNT(*)
            INTO v_count
            FROM tbl_thread t
           WHERE t.col_id = v_id
             AND t.col_createdby = '@TOKEN_USERACCESSSUBJECT@';
        ELSIF (allowEditComment = 'NOBODY') THEN
          v_count := 0;
        END IF;

        IF (v_count = 0) THEN
          v_errorcode    := 101;
          v_errormessage := 'You don''t have permissions for this action';
          GOTO cleanup;
        END IF;

        /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -THREAD_COMMENT_MODIFIED- AND*/
        /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
        v_validationresult := 1;
        v_result           := F_dcm_processcommonevent(InData           => NULL,
                                                       OutData          => v_outData,
                                                       Attributes       => v_Attributes,
                                                       code             => NULL,
                                                       caseid           => v_caseid,
                                                       casetypeid       => NULL,
                                                       commoneventtype  => 'THREAD_COMMENT_MODIFIED',
                                                       errorcode        => v_errorcode,
                                                       errormessage     => v_errormessage,
                                                       eventmoment      => 'BEFORE',
                                                       eventtype        => 'VALIDATION',
                                                       historymessage   => v_historymsg,
                                                       procedureid      => NULL,
                                                       taskid           => NULL,
                                                       tasktypeid       => NULL,
                                                       validationresult => v_validationresult);

        /*--write to history*/
        IF v_historymsg IS NOT NULL THEN
          v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                             issystem       => 0,
                                             MESSAGE        => 'Validation Common event(s)',
                                             messagecode    => 'CommonEvent',
                                             targetid       => v_caseid,
                                             targettype     => 'CASE');
        END IF;

        IF NVL(v_validationresult, 0) = 0 THEN
          GOTO cleanup;
        END IF;

        /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -THREAD_COMMENT_MODIFIED- AND*/
        /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
        v_validationresult := 1;

        v_result := F_dcm_processcommonevent(InData           => NULL,
                                             OutData          => v_outData,
                                             Attributes       => v_Attributes,
                                             code             => NULL,
                                             caseid           => v_caseid,
                                             casetypeid       => NULL,
                                             commoneventtype  => 'THREAD_COMMENT_MODIFIED',
                                             errorcode        => v_errorcode,
                                             errormessage     => v_errormessage,
                                             eventmoment      => 'BEFORE',
                                             eventtype        => 'ACTION',
                                             historymessage   => v_historymsg,
                                             procedureid      => NULL,
                                             taskid           => NULL,
                                             tasktypeid       => NULL,
                                             validationresult => v_validationresult);

        /*--write to history*/
        IF v_historymsg IS NOT NULL THEN
          v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                             issystem       => 0,
                                             MESSAGE        => 'Action Common event(s)',
                                             messagecode    => 'CommonEvent',
                                             targetid       => v_caseid,
                                             targettype     => 'CASE');
        END IF;

        --MAIN ACTION
        UPDATE TBL_THREAD SET col_message = v_message WHERE COL_ID = v_id;

        /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -THREAD_COMMENT_MODIFIED- AND*/
        /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
        v_validationresult := 1;

        v_result := F_dcm_processcommonevent(InData           => NULL,
                                             OutData          => v_outData,
                                             Attributes       => v_Attributes,
                                             code             => NULL,
                                             caseid           => v_caseid,
                                             casetypeid       => NULL,
                                             commoneventtype  => 'THREAD_COMMENT_MODIFIED',
                                             errorcode        => v_errorcode,
                                             errormessage     => v_errormessage,
                                             eventmoment      => 'AFTER',
                                             eventtype        => 'ACTION',
                                             historymessage   => v_historymsg,
                                             procedureid      => NULL,
                                             taskid           => NULL,
                                             tasktypeid       => NULL,
                                             validationresult => v_validationresult);

        /*--write to history*/
        IF v_historymsg IS NOT NULL THEN
          v_result := F_hist_createhistoryfn(additionalinfo => v_historymsg,
                                             issystem       => 0,
                                             MESSAGE        => 'Action Common event(s)',
                                             messagecode    => 'CommonEvent',
                                             targetid       => v_caseid,
                                             targettype     => 'CASE');
        END IF;
      ELSE
        -- Edit Thread
        UPDATE TBL_THREAD SET col_message = v_message WHERE COL_ID = v_id;
      END IF;

    END IF;

    :affectedRows := 1;
    :recordId     := v_id;
    RETURN;

    <<cleanup>>
    :ErrorCode    := v_errorcode;
    :ErrorMessage := v_errormessage;
    RETURN;

  EXCEPTION
    WHEN OTHERS THEN
      :affectedRows    := 0;
      v_errorcode      := 101;
      v_errormessage   := substr(SQLERRM, 1, 200);
      :SuccessResponse := '';
  END;

END;