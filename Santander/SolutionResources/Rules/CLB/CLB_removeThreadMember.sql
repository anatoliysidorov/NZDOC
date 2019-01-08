DECLARE
  v_Id                    NUMBER;
  v_Ids                   NVARCHAR2(32767);
  v_parentThreadId        NUMBER;
  v_mode                  NVARCHAR2(30);
  allowLeaveDiscussion    NVARCHAR2(30);
  allowRemovePeople       NVARCHAR2(30);
  allowCommentDiscussion  NVARCHAR2(30);
  v_currentUserCWID       NUMBER;
  v_count                 NUMBER;
  v_validationresult      NUMBER;
  v_Attributes            NVARCHAR2(4000);
  v_Attributes2           NVARCHAR2(4000);
  v_caseId                NUMBER;
  v_historymsg            NCLOB;
  v_errorcode             NUMBER;
  v_errormessage          NCLOB;
  v_result                NUMBER;
  v_outData CLOB;
  
  
begin
  :SuccessResponse  := '';
  :ErrorCode        := 0;
  :ErrorMessage     := '';
  v_Id              := :Id;
  v_Ids             := :Ids;
  v_parentThreadId := :ParentThreadId;
  v_mode          := :CurrentMode;
  
  allowLeaveDiscussion    := '';
  allowRemovePeople       := '';
  allowCommentDiscussion  := '';
  v_currentUserCWID       := 0;
  v_count                 := NULL;
  v_Attributes            := NULL;
  v_Attributes2           := NULL;
  v_caseId                := NULL;
  v_historymsg            :=NULL;
  v_errorcode             := 0;
  v_errormessage          := '';  
  v_outData      := NULL;
  
  begin
    SELECT COL_THREADCASE INTO v_caseId
    FROM TBL_THREAD 
    WHERE COL_ID = v_parentThreadId;
  exception
    when no_data_found then    
      v_caseId  := null;
  end;
  
  IF v_caseId IS NULL THEN
    :ErrorMessage := 'Case Id can not be empty';
    :ErrorCode    := 101;
    goto cleanup;
  END IF;
  
  
  begin
    select col_allowleavediscussion, col_allowremovepeople, col_allowcommentdiscussion
          into allowLeaveDiscussion, allowRemovePeople, allowCommentDiscussion
    from tbl_threadsetting
    where rownum = 1;
  exception
    when no_data_found then
      allowLeaveDiscussion := 'YES';
      allowRemovePeople := 'ANYONE';
      allowCommentDiscussion := 'ANYONE';
  end;

  if(allowCommentDiscussion = 'ANYONE') then
    :ErrorMessage := 'You don''t have permissions for this action';
    :ErrorCode := 101;
    goto cleanup;
  end if;

  begin
      select cw.col_id into v_currentUserCWID
      from vw_users usr
      inner join tbl_ppl_caseworker cw on cw.col_userid = usr.userid
      where usr.accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject'); 
    exception
      when no_data_found then
        :ErrorMessage := 'Case Worker is not found';
        :ErrorCode := 101;
        v_id := null;
        goto cleanup;
  end;
  
  v_Attributes:='<AllowLeaveDiscussion>'||TO_CHAR(allowLeaveDiscussion)||'</AllowLeaveDiscussion>'||
                '<AllowRemovePeople>'||TO_CHAR(allowRemovePeople)||'</AllowRemovePeople>'||
                '<AllowCommentDiscussion>'||TO_CHAR(allowCommentDiscussion)||'</AllowCommentDiscussion>'||
                '<MemberId>'||TO_CHAR(v_id)||'</MemberId>'||
                '<MemberIds>'||TO_CHAR(v_ids)||'</MemberIds>'||
                '<Mode>'||TO_CHAR(v_mode)||'</Mode>'||
                '<CurrentUserCWID>'||TO_CHAR(v_currentUserCWID)||'</CurrentUserCWID>'||
                '<ParentThreadId>'||TO_CHAR(v_parentThreadId)||'</ParentThreadId>';
  

  if(v_mode = 'LEAVE') THEN
    --Allow Leave to Discussion
    if (allowLeaveDiscussion = 'NO') then
        :ErrorMessage := 'You don''t have permissions for this action';
        :ErrorCode := 101;
        goto cleanup;
    end if;

    v_id := v_currentUserCWID;
  else 
      --Allow Remove Other people from Discussions/Thread
    if(allowRemovePeople = 'ONLY_CASE_OWNER') then
        select count(*) into v_count
        from tbl_thread t 
        inner join tbl_case c on c.col_id = t.col_threadcase
        inner join tbl_ppl_workbasket wb on wb.col_id = c.col_caseppl_workbasket 
        inner join tbl_ppl_caseworker cw on cw.col_id = wb.col_caseworkerworkbasket 
        inner join vw_users usr on usr.userid = cw.col_userid 
        where t.col_id = v_parentThreadId
              and usr.accesssubjectcode = sys_context('CLIENTCONTEXT', 'AccessSubject');
    elsif(allowRemovePeople = 'NOBODY') then 
        v_count := 0;
    end if;

    if(v_count = 0) then
        :ErrorMessage := 'You don''t have permissions for this action';
        :ErrorCode := 101;
        goto cleanup;
    end if;
  end if;

  IF (v_Id IS NULL AND v_Ids IS NULL) THEN
    :ErrorMessage := 'Id is required field';
    :ErrorCode := 101;
     goto cleanup;
  END IF;

  IF (v_Id IS NOT NULL) THEN
    v_Ids := TO_CHAR(v_Id);
  END IF;

  for mRec in (select column_value as id
                 from table (asf_split(v_Ids, ',')))
  loop
    if(allowLeaveDiscussion = 'NO') then
      if(v_currentUserCWID = mRec.id) then
        :ErrorMessage := 'You don''t have permissions to leave a thread themselves.';
        :ErrorCode := 101;
        continue;
      end if;
    end if;
    
    v_Attributes2:=v_Attributes||'<CaseWorkerId>'||TO_CHAR(mRec.id)||'</CaseWorkerId>';
  
    /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -VALIDATION- AND THE COMMON EVENT TYPE -THREAD_PEOPLE_REMOVED- AND*/
    /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
    v_validationresult := 1;      
    v_result := F_dcm_processcommonevent(InData           => NULL,
                                         OutData          => v_outData,
                                         Attributes       => v_Attributes2,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => NULL,
                                         commoneventtype  => 'THREAD_PEOPLE_REMOVED',
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

    IF NVL(v_validationresult, 0) = 0 THEN  GOTO nextIter; END IF;                            
        
    /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -THREAD_PEOPLE_REMOVED- AND*/
    /*--EVENT MOMENT -BEFORE- EXIST. IF THEY EXIST PROCESS THEM--*/
    v_validationresult := 1;

    v_result := F_dcm_processcommonevent(InData           => NULL,
                                         OutData          => v_outData,
                                         Attributes       => v_Attributes2,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => NULL,
                                         commoneventtype  => 'THREAD_PEOPLE_REMOVED',
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
    DELETE FROM TBL_THREADCASEWORKER
    WHERE COL_CASEWORKERID = mRec.id  AND COL_THREADID = v_parentThreadId;
          
    /*--CHECK IF COMMON EVENTS OF THE EVENT TYPE -ACTION- AND THE COMMON EVENT TYPE -THREAD_PEOPLE_REMOVED- AND*/
    /*--EVENT MOMENT -AFTER- EXIST. IF THEY EXIST PROCESS THEM--*/
    v_validationresult := 1;
    v_result := F_dcm_processcommonevent(InData           => NULL,
                                         OutData          => v_outData,
                                         Attributes       => v_Attributes2,
                                         code             => NULL,
                                         caseid           => v_caseid,
                                         casetypeid       => NULL,
                                         commoneventtype  => 'THREAD_PEOPLE_REMOVED',
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
    
    <<nextIter>>
    NULL;     
  end loop;  

  <<cleanup>>
    NULL;  

end;