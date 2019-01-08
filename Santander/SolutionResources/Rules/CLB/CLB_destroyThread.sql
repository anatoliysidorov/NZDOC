DECLARE
  v_id                      NUMBER;
  v_errorcode               NUMBER;
  v_errormessage            NCLOB;
  allowDeleteDiscussion     NVARCHAR2(30);
  parentThreadId            NUMBER;
  v_count                   NUMBER;
  allowDeleteComment        NVARCHAR2(30);
  v_validationresult        NUMBER;
  v_Attributes              NVARCHAR2(4000);
  v_commonEventType         NVARCHAR2(255);
  v_caseId                  NUMBER;
  v_historymsg              NCLOB;
  v_result                  NUMBER;
  v_outData CLOB;
  
BEGIN
  v_errorcode           := 0;
  v_errormessage        := '';
  :affectedRows         := 0;
  v_id                  := :Id;
  allowDeleteDiscussion := '';
  parentThreadId      := 0;
  v_count             := 0;
  allowDeleteComment  := '';
  v_Attributes        :=NULL;
  v_commonEventType   :=NULL;
  v_caseId            :=NULL;
  v_historymsg        :=NULL;
  v_outData      := NULL;

  IF v_id IS NULL THEN
    v_errormessage := 'Id can not be empty';
    v_errorcode    := 101;
    goto cleanup;
  END IF;
  
  begin
    SELECT COL_PARENTMESSAGEID, COL_THREADCASE INTO parentThreadId, v_caseId
    FROM TBL_THREAD 
    WHERE COL_ID = v_id;
  exception
    when no_data_found then
      parentThreadId := null;
      v_caseId  := null;
  end;
  
  IF v_caseId IS NULL THEN
    v_errormessage := 'Case Id can not be empty';
    v_errorcode    := 101;
    goto cleanup;
  END IF;  

  if(parentThreadId is null) then
    --Allow Delete Discussions/Thread
    begin
      select col_allowdeletediscussion into allowDeleteDiscussion 
      from tbl_threadsetting
      where rownum = 1;
    exception
      when no_data_found then
        allowDeleteDiscussion := 'ONLY_THREAD_CREATOR';
    end;

    if (allowDeleteDiscussion = 'ONLY_THREAD_CREATOR') then
        select count(*) into v_count
        from tbl_thread 
        where col_id = v_id
              and col_createdby = '@TOKEN_USERACCESSSUBJECT@';
    elsif(allowDeleteDiscussion = 'ONLY_CASE_OWNER') then
        select count(*) into v_count
        from tbl_thread t 
        inner join tbl_case c on c.col_id = t.col_threadcase
        inner join tbl_ppl_workbasket wb on wb.col_id = c.col_caseppl_workbasket 
        inner join tbl_ppl_caseworker cw on cw.col_id = wb.col_caseworkerworkbasket 
        inner join vw_users usr on usr.userid = cw.col_userid 
        where t.col_id = v_id
              and usr.accesssubjectcode = '@TOKEN_USERACCESSSUBJECT@';
    elsif(allowDeleteDiscussion = 'NOBODY') then 
        v_count := 0;
    end if;

    if(v_count = 0) then
        v_errorcode := 101;
        v_errormessage := 'You don''t have permissions for this action';
        goto cleanup;
    end if;
  else
      --Allow Delete Comment
      begin
        select col_allowdeletecomment into allowDeleteComment 
        from tbl_threadsetting
        where rownum = 1;
      exception
        when no_data_found then
          allowDeleteComment := 'ONLY_CREATOR';
      end;

      if(allowDeleteComment = 'ONLY_CREATOR') then
          select count(*) into v_count
          from tbl_thread t 
          where t.col_id = v_id
                and t.col_createdby = '@TOKEN_USERACCESSSUBJECT@';
      elsif(allowDeleteComment = 'NOBODY') then
          v_count := 0;
      end if;  

      if(v_count = 0) then
          v_errorcode := 101;
          v_errormessage := 'You don''t have permissions for this action';
          goto cleanup;
      end if;
  end if;
    
  v_Attributes:='<AllowDeleteDiscussion>'||TO_CHAR(allowDeleteDiscussion)||'</AllowDeleteDiscussion>'||  
                '<AllowDeleteComment>'||TO_CHAR(allowDeleteComment)||'</AllowDeleteComment>'||
                '<ThreadId>'||TO_CHAR(v_id)||'</ThreadId>'||
                '<ParentThreadId>'||TO_CHAR(parentThreadId)||'</ParentThreadId>';

  delete from tbl_threadcaseworker 
  where col_threadid in (select col_id from tbl_thread 
                        where col_id in (select col_id
                                        from tbl_thread
                                        connect by prior col_id = col_parentmessageid
                                        start with col_id = v_id));     
                                        
                                        
  IF parentThreadId IS NULL THEN v_commonEventType :='THREAD_DELETED'; END IF;
  IF parentThreadId IS NOT NULL THEN v_commonEventType :='THREAD_COMMENT_DELETED'; END IF;
    
  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -v_commonEventType- AND*/
  /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
  v_validationresult := 1;      
  v_result := F_dcm_processcommonevent(InData           => NULL,
                                       OutData          => v_outData, 
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => v_commonEventType,
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

  IF NVL(v_validationresult, 0) = 0 THEN  GOTO cleanup; END IF;                            
      
  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -v_commonEventType- AND*/
  /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
  v_validationresult := 1;

  v_result := F_dcm_processcommonevent(InData           => NULL,
                                       OutData          => v_outData, 
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => v_commonEventType,
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
  DELETE FROM TBL_THREAD 
  WHERE COL_ID IN (SELECT col_id
                   FROM TBL_THREAD
                   CONNECT BY PRIOR COL_ID = col_parentmessageid
                   START WITH COL_ID = v_id);
                   
                   
  /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -v_commonEventType- AND*/
  /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
  v_validationresult := 1;
  v_result := F_dcm_processcommonevent(InData           => NULL,
                                       OutData          => v_outData, 
                                       Attributes       => v_Attributes,
                                       code             => NULL,
                                       caseid           => v_caseid,
                                       casetypeid       => NULL,
                                       commoneventtype  => v_commonEventType,
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
                                                        
  /*if(parentThreadId is null) then
    -- COMMON EVENT THREAD_DELETED
  else
    -- COMMON EVENT THREAD_COMMENT_DELETED
  end if;*/                  

  :affectedRows := SQL%ROWCOUNT;

  <<cleanup>>
  :ErrorMessage := v_ErrorMessage;
  :ErrorCode    := v_ErrorCode;
END;