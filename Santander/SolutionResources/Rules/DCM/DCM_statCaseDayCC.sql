declare
  v_CaseId Integer;
  v_count number;
  v_count2 number;
  v_MeetGoal number;
  v_NoMeetGoal number;
  v_MeetDeadline number;
  v_NoMeetDeadline number;
  v_CaseComplete number;
  v_Mins number;
  v_YearMonth nvarchar2(255);
  v_CaseSysType Integer;
  v_CaseworkerId Integer;
  v_id Integer;
  v_AvgInProcess number;
  v_TotalInProcess number;
  v_TotalClosed Integer;
  v_stateCaseComplete nvarchar2(255);
  v_stateNew nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateInProcess nvarchar2(255);
  v_stateFixed nvarchar2(255);
  v_stateResolved nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_SlaStartDateType nvarchar2(255);
  v_SlaEndDateType nvarchar2(255);
begin
  v_CaseId := :CaseId;
  v_stateNew := f_dcm_getCaseNewState();
  v_stateAssigned := f_dcm_getCaseAssignedState();
  v_stateInProcess := f_dcm_getCaseInProcessState();
  v_stateFixed := f_dcm_getCaseFixedState();
  v_stateResolved := f_dcm_getCaseResolvedState();
  v_stateClosed := f_dcm_getCaseClosedState2(f_dcm_getcaseconfigid(CaseId => v_CaseId));
  v_stateCaseComplete := v_stateClosed;
  v_SlaStartDateType := f_dcm_getSlaStartDateType();
  v_SlaEndDateType := f_dcm_getSlaEndDateType();
  
  --CHECK IF "GOAL" SLA EVENTS EXIST FOR CASE
  begin
    select count(*) into v_count from tbl_slaeventcc se
      inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id and setp.col_code = 'GOAL'
      inner join tbl_casecc cs on se.col_slaeventcccasecc = cs.col_id
      where se.col_slaeventcccasecc = v_CaseId
      and (cs.col_statupdated is null or cs.col_statupdated = 0);
      exception
        when NO_DATA_FOUND then
          v_count := 0;
          v_MeetGoal := 0;
          v_NoMeetGoal := 0;
  end;

  --CHECK "MEET GOAL" CONDITION
  if v_count > 0 then
    begin
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      --THOSE TASKS CAN BE COUNTED AS COMPLETED AND "MEET GOAL" IN STATISTICS
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      select count(*) into v_count2
        from tbl_casecc cse
        inner join tbl_cw_workitemcc cwi on cse.col_cw_workitemcccasecc = cwi.col_id
        inner join tbl_dict_casesystype cst on cse.col_caseccdict_casesystype = cst.col_id
        inner join tbl_dict_casestate cs on cwi.col_cw_workitemccdict_casest = cs.col_id
        --DATE WHEN SLA STARTED
        inner join tbl_dateeventcc des on cse.col_id = des.col_dateeventcccasecc
        inner join tbl_dict_dateeventtype dets on des.col_dateeventcc_dateeventtype = dets.col_id
        --DATE WHEN SLA ENDED
        inner join tbl_dateeventcc dee on cse.col_id = dee.col_dateeventcccasecc
        inner join tbl_dict_dateeventtype dete on dee.col_dateeventcc_dateeventtype = dete.col_id
        where cse.col_id = v_CaseId
        and (cse.col_statupdated is null or cse.col_statupdated = 0)
        and cs.col_activity = v_stateCaseComplete
        --EXCLUDE CASES THAT "DO NOT MEET AT LEAST ONE GOAL"
        and cse.col_id not in (select col_slaeventcccasecc
                                 from tbl_slaeventcc se
                                 inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id and setp.col_code = 'GOAL'
                                 where col_slaeventcccasecc = cse.col_id
                                 and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                        + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                        < dee.col_datevalue))
                                 --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                                 --                       + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                                 --                       < dee.col_datevalue))
        --INCLUDE ONLY STARTING DATE EVENT TYPES THAT SATISFY "MEET GOAL" CONDITION
        and dets.col_id in (select col_slaeventcc_dateeventtype
                              from tbl_slaeventcc se
                              inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id and setp.col_code = 'GOAL'
                              where col_slaeventcccasecc = cse.col_id
                              and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                     + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                     >= dee.col_datevalue))
                              --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                              --                       + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                              --                       >= dee.col_datevalue))
        and dete.col_code = v_SlaEndDateType
        and dee.col_datevalue between trunc(sysdate, 'DDD') and trunc(sysdate + interval '1' day, 'DDD');
      exception
        when NO_DATA_FOUND then
          v_count2 := 0;
    end;
  end if;

  if v_count2 > 0 then
    v_MeetGoal := 1;
  else
    v_MeetGoal := 0;
  end if;

  --CHECK "DOES NOT MEET GOAL" CONDITION
  if v_count > 0 then
    begin
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      --THOSE CASES CAN BE COUNTED AS COMPLETED AND "DO NOT MEET GOAL" IN STATISTICS
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      select count(*) into v_count2
        from tbl_casecc cse
        inner join tbl_cw_workitemcc cwi on cse.col_cw_workitemcccasecc = cwi.col_id
        inner join tbl_dict_casesystype cst on cse.col_caseccdict_casesystype = cst.col_id
        inner join tbl_dict_casestate cs on cwi.col_cw_workitemccdict_casest = cs.col_id
        --DATE WHEN SLA STARTED
        inner join tbl_dateeventcc des on cse.col_id = des.col_dateeventcccasecc
        inner join tbl_dict_dateeventtype dets on des.col_dateeventcc_dateeventtype = dets.col_id
        --DATE WHEN SLA ENDED
        inner join tbl_dateeventcc dee on cse.col_id = dee.col_dateeventcctaskcc
        inner join tbl_dict_dateeventtype dete on dee.col_dateeventcc_dateeventtype = dete.col_id
        where cse.col_id = v_CaseId
        and (cse.col_statupdated is null or cse.col_statupdated = 0)
        and cs.col_activity = v_stateCaseComplete
        --INCLUDE CASES THAT DO NOT MEET AT LEAST ONE GOAL
        and cse.col_id in (select col_slaeventcccasecc
                             from tbl_slaeventcc se
                             inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id and setp.col_code = 'GOAL'
                             where col_slaeventcccasecc = cse.col_id
                             and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                    + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                    <= dee.col_datevalue))
                             --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                             --                       + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                             --                       <= dee.col_datevalue))
        --INCLUDE ONLY STARTING DATE EVENT TYPES THAT SATISFY "DO NOT MEET GOAL" CONDITION
        and dets.col_id in (select col_slaeventcc_dateeventtype
                              from tbl_slaeventcc se
                              inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id and setp.col_code = 'GOAL'
                              where col_slaeventcccasecc = cse.col_id
                              and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                    + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                    <= dee.col_datevalue))
                              --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                              --                      + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                              --                      <= dee.col_datevalue))
                              and dete.col_code = v_SlaEndDateType
                              and dee.col_datevalue between trunc(sysdate, 'DDD') and trunc(sysdate + interval '1' day, 'DDD');
        exception
          when NO_DATA_FOUND then
            v_count2 := 0;
    end;
  end if;

  if v_count2 > 0 then
    v_NoMeetGoal := 1;
  else
    v_NoMeetGoal := 0;
  end if;

  --CHECK IF "DEADLINE" SLA EVENTS EXIST FOR TASK
  begin
    select count(*) into v_count from tbl_slaeventcc se
      inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'
      where col_slaeventcccasecc = v_CaseId;
      exception
        when NO_DATA_FOUND then
          v_count := 0;
          v_MeetDeadline := 0;
          v_NoMeetDeadline := 0;
  end;

  --CHECK "MEET DEADLINE" CONDITION
  if v_count > 0 then
    begin
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      --THOSE CASES CAN BE COUNTED AS COMPLETED AND "MEET DEADLINE" IN STATISTICS
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      select count(*) into v_count2
        from tbl_casecc cse
        inner join tbl_cw_workitemcc cwi on cse.col_cw_workitemcccasecc = cwi.col_id
        inner join tbl_dict_casesystype cst on cse.col_caseccdict_casesystype = cst.col_id
        inner join tbl_dict_casestate cs on cwi.col_cw_workitemccdict_casest = cs.col_id
        --DATE WHEN SLA STARTED
        inner join tbl_dateeventcc des on cse.col_id = des.col_dateeventcccasecc
        inner join tbl_dict_dateeventtype dets on des.col_dateeventcc_dateeventtype = dets.col_id
        --DATE WHEN SLA ENDED
        inner join tbl_dateeventcc dee on cse.col_id = dee.col_dateeventcccasecc
        inner join tbl_dict_dateeventtype dete on dee.col_dateeventcc_dateeventtype = dete.col_id
        where cse.col_id = v_CaseId
        and (cse.col_statupdated is null or cse.col_statupdated = 0)
        and cs.col_activity = v_stateCaseComplete
        --EXCLUDE CASES THAT "DO NOT MEET AT LEAST ONE DEADLINE"
        and cse.col_id not in (select col_slaeventcccasecc
                                 from tbl_slaeventcc se
                                 inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'
                                 where col_slaeventcccasecc = cse.col_id
                                 and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                        + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                        < dee.col_datevalue))
                                 --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                                 --                       + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                                 --                       < dee.col_datevalue))
        --INCLUDE ONLY STARTING DATE EVENT TYPES THAT SATISFY "MEET DEADLINE" CONDITION
        and dets.col_id in (select col_slaeventcc_dateeventtype
                              from tbl_slaeventcc se
                              inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'
                              where col_slaeventcccasecc = cse.col_id
                              and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                     + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                     >= dee.col_datevalue))
                              --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                              --                       + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                              --                       >= dee.col_datevalue))
        and dete.col_code = v_SlaEndDateType
        and dee.col_datevalue between trunc(sysdate, 'DDD') and trunc(sysdate + interval '1' day, 'DDD');
      exception
        when NO_DATA_FOUND then
          v_count2 := 0;
    end;
  end if;

  if v_count2 > 0 then
    v_MeetDeadline := 1;
  else
    v_MeetDeadline := 0;
  end if;

  --CHECK "DOES NOT MEET DEADLINE" CONDITION
  if v_count > 0 then
    begin
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      --THOSE CASES CAN BE COUNTED AS COMPLETED AND "DO NOT MEET DEADLINE" IN STATISTICS
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      select count(*) into v_count2
        from tbl_casecc cse
        inner join tbl_cw_workitemcc cwi on cse.col_cw_workitemcccasecc = cwi.col_id
        inner join tbl_dict_casesystype cst on cse.col_caseccdict_casesystype = cst.col_id
        inner join tbl_dict_casestate cs on cwi.col_cw_workitemccdict_casest = cs.col_id
        --DATE WHEN SLA STARTED
        inner join tbl_dateeventcc des on cse.col_id = des.col_dateeventcccasecc
        inner join tbl_dict_dateeventtype dets on des.col_dateeventcc_dateeventtype = dets.col_id
        --DATE WHEN SLA ENDED
        inner join tbl_dateeventcc dee on cse.col_id = dee.col_dateeventcccasecc
        inner join tbl_dict_dateeventtype dete on dee.col_dateeventcc_dateeventtype = dete.col_id
        where cse.col_id = v_CaseId
        and (cse.col_statupdated is null or cse.col_statupdated = 0)
        and cs.col_activity = v_stateCaseComplete
        --INCLUDE CASES THAT DO NOT MEET AT LEAST ONE GOAL
        and cse.col_id in (select col_slaeventcccasecc
                             from tbl_slaeventcc se
                             inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'
                             where col_slaeventcccasecc = cse.col_id
                             and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                    + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                    <= dee.col_datevalue))
                             --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                             --                       + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                             --                       <= dee.col_datevalue))
        --INCLUDE ONLY STARTING DATE EVENT TYPES THAT SATISFY "DO NOT MEET GOAL" CONDITION
        and dets.col_id in (select col_slaeventcc_dateeventtype
                              from tbl_slaeventcc se
                              inner join tbl_dict_slaeventtype setp on se.col_slaeventcc_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'
                              where col_slaeventcccasecc = cse.col_id
                              and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                    + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                    <= dee.col_datevalue))
                              --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                              --                      + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                              --                      <= dee.col_datevalue))
                              and dete.col_code = v_SlaEndDateType
                              and dee.col_datevalue between trunc(sysdate, 'DDD') and trunc(sysdate + interval '1' day, 'DDD');
        exception
          when NO_DATA_FOUND then
            v_count2 := 0;
    end;
  end if;

  if v_count2 > 0 then
    v_NoMeetDeadline := 1;
  else
    v_NoMeetDeadline := 0;
  end if;

  v_CaseComplete := 1;
  begin
    select cst.col_id, cwu.Id, to_char(trunc(dee.col_datevalue, 'DDD')), (dee.col_datevalue - des.col_datevalue) * 24 * 60
      into v_CaseSysType, v_CaseworkerId, v_YearMonth, v_Mins
      from tbl_casecc cse
      inner join tbl_cw_workitemcc cwi on cse.col_cw_workitemcccasecc = cwi.col_id
      inner join tbl_dict_casesystype cst on cse.col_caseccdict_casesystype = cst.col_id
      inner join tbl_dict_casestate cs on cwi.col_cw_workitemccdict_casest = cs.col_id
      inner join tbl_dateeventcc dee on cse.col_id = dee.col_dateeventcccasecc
      inner join tbl_dict_dateeventtype dete on dee.col_dateeventcc_dateeventtype = dete.col_id
      inner join tbl_dateeventcc des on cse.col_id = des.col_dateeventcccasecc
      inner join tbl_dict_dateeventtype dets on des.col_dateeventcc_dateeventtype = dets.col_id
      inner join vw_ppl_caseworkersusers cwu on dee.col_dateeventccppl_caseworker = cwu.Id
      where cse.col_id = v_CaseId
      and (cse.col_statupdated is null or cse.col_statupdated = 0)
      and cs.col_activity = v_stateCaseComplete
      and dete.col_code = v_SlaEndDateType
      and dets.col_code = v_SlaStartDateType
      and dee.col_datevalue between trunc(sysdate, 'DDD') and trunc(sysdate + interval '1' day, 'DDD');
    exception
      when NO_DATA_FOUND then
        v_CaseComplete := null;
        v_CaseSysType := null;
        v_CaseworkerId := null;
        v_YearMonth := null;
        v_Mins := null;
  end;

  if (v_CaseComplete is not null) and (v_CaseSysType is not null) and (v_CaseWorkerId is not null) and (v_YearMonth is not null) then
    begin
      select col_id into v_id
        from tbl_statcaseday
        where col_statcasedaycasesystype = v_CaseSysType
        and col_statcasedaycaseworker = v_Caseworkerid
        and col_yearmonth = v_YearMonth;
      exception
        when NO_DATA_FOUND then
          v_id := null;
    end;

    if v_id is not null then
      begin
        select col_avginprocess, col_totalinprocess, col_totalclosed into v_AvgInProcess, v_TotalInProcess, v_TotalClosed from tbl_statcaseday where col_id = v_id;
        exception
          when NO_DATA_FOUND then
            v_AvgInProcess := 0;
            v_TotalInProcess := 0;
      end;

      v_Mins := ((v_AvgInProcess * v_TotalClosed) + v_Mins) / (v_TotalClosed + 1);
      update tbl_statcaseday
        set col_totalclosed = col_totalclosed + 1,
            col_meetgoal = col_meetgoal + v_MeetGoal,
            col_nomeetgoal = col_nomeetgoal + v_NoMeetGoal,
            col_meetdeadline = col_meetdeadline + v_MeetDeadline,
            col_nomeetdeadline = col_nomeetdeadline + v_NoMeetDeadline,
            col_avginprocess = v_Mins,
            col_totalinprocess = nvl(col_totalinprocess, 0) + v_Mins
        where col_id = v_id;
    else
      insert into tbl_statcaseday(col_statcasedaycaseworker, col_statcasedaycasesystype, col_yearmonth, col_totalclosed, col_meetgoal, col_nomeetgoal, col_meetdeadline, col_nomeetdeadline, col_avginprocess, col_totalinprocess)
        values(v_CaseworkerId, v_CaseSysType, v_YearMonth, 1, v_MeetGoal, v_NoMeetGoal, v_MeetDeadline, v_NoMeetDeadline, v_Mins, v_Mins);
    end if;
  end if;  

end;