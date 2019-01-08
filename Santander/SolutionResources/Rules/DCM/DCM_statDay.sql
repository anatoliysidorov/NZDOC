declare
  v_TaskId Integer;
  v_count number;
  v_count2 number;
  v_MeetGoal number;
  v_NoMeetGoal number;
  v_MeetDeadline number;
  v_NoMeetDeadline number;
  v_TaskComplete number;
  v_Mins number;
  v_YearMonth nvarchar2(255);
  v_TaskSysType Integer;
  v_CaseworkerId Integer;
  v_id Integer;
  v_AvgInProcess number;
  v_TotalInProcess number;
  v_TotalClosed Integer;
  v_stateTaskComplete nvarchar2(255);
  v_stateClosed nvarchar2(255);
  v_stateAssigned nvarchar2(255);
  v_stateInProcess nvarchar2(255);
  v_stateResolved nvarchar2(255);
  v_stateNew nvarchar2(255);
  v_stateStarted nvarchar2(255);
  v_SlaStartDateType nvarchar2(255);
  v_SlaEndDateType nvarchar2(255);
  v_StateConfigId Integer;
begin
  v_TaskId := :TaskId;
  begin
    select nvl(tst.col_stateconfigtasksystype,0) into v_StateConfigId
      from tbl_dict_tasksystype tst
      inner join tbl_task tsk on tst.col_id = tsk.col_taskdict_tasksystype
      where tsk.col_id = v_TaskId;
    exception
    when NO_DATA_FOUND then
    v_StateConfigId := null;
  end;
  v_stateNew := f_dcm_getTaskNewState();
  v_stateStarted := f_dcm_getTaskStartedState();
  v_stateAssigned := f_dcm_getTaskAssignedState();
  v_stateInProcess := f_dcm_getTaskInProcessState();
  v_stateResolved := f_dcm_getTaskResolvedState();
  v_stateClosed := f_dcm_getTaskClosedState2(StateConfigId => v_StateConfigId);
  v_stateTaskComplete := v_stateClosed;
  v_SlaStartDateType := f_dcm_getSlaStartDateType();
  v_SlaEndDateType := f_dcm_getSlaEndDateType();
  --CHECK IF "GOAL" SLA EVENTS EXIST FOR TASK
  begin
    select count(*) into v_count from tbl_slaevent se
      inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'GOAL'
      inner join tbl_task tsk on se.col_slaeventtask = tsk.col_id
      where se.col_slaeventtask = v_TaskId
      and (tsk.col_statupdated is null or tsk.col_statupdated = 0);
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
        from tbl_task tsk
        inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
        inner join tbl_dict_tasksystype tst on tsk.col_taskdict_tasksystype = tst.col_id
        inner join tbl_dict_taskstate ts on twi.col_tw_workitemdict_taskstate = ts.col_id
        --DATE WHEN SLA STARTED
        inner join tbl_dateevent des on tsk.col_id = des.col_dateeventtask
        inner join tbl_dict_dateeventtype dets on des.col_dateevent_dateeventtype = dets.col_id
        --DATE WHEN SLA ENDED
        inner join tbl_dateevent dee on tsk.col_id = dee.col_dateeventtask
        inner join tbl_dict_dateeventtype dete on dee.col_dateevent_dateeventtype = dete.col_id
        where tsk.col_id = v_TaskId
        and (tsk.col_statupdated is null or tsk.col_statupdated = 0)
        and ts.col_activity = v_stateTaskComplete
        --EXCLUDE TASKS THAT "DO NOT MEET AT LEAST ONE GOAL"
        and tsk.col_id not in (select col_slaeventtask
                                 from tbl_slaevent se
                                 inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'GOAL'
                                 where col_slaeventtask = tsk.col_id
                                 and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                        + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                        < dee.col_datevalue))
                                 --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                                 --                       + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                                 --                       < dee.col_datevalue))
        --INCLUDE ONLY STARTING DATE EVENT TYPES THAT SATISFY "MEET GOAL" CONDITION
        and dets.col_id in (select col_slaevent_dateeventtype
                              from tbl_slaevent se
                              inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'GOAL'
                              where col_slaeventtask = tsk.col_id
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
      --THOSE TASKS CAN BE COUNTED AS COMPLETED AND "DO NOT MEET GOAL" IN STATISTICS
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      select count(*) into v_count2
        from tbl_task tsk
        inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
        inner join tbl_dict_tasksystype tst on tsk.col_taskdict_tasksystype = tst.col_id
        inner join tbl_dict_taskstate ts on twi.col_tw_workitemdict_taskstate = ts.col_id
        --DATE WHEN SLA STARTED
        inner join tbl_dateevent des on tsk.col_id = des.col_dateeventtask
        inner join tbl_dict_dateeventtype dets on des.col_dateevent_dateeventtype = dets.col_id
        --DATE WHEN SLA ENDED
        inner join tbl_dateevent dee on tsk.col_id = dee.col_dateeventtask
        inner join tbl_dict_dateeventtype dete on dee.col_dateevent_dateeventtype = dete.col_id
        where tsk.col_id = v_TaskId
        and (tsk.col_statupdated is null or tsk.col_statupdated = 0)
        and ts.col_activity = v_stateTaskComplete
        --INCLUDE TASKS THAT DO NOT MEET AT LEAST ONE GOAL
        and tsk.col_id in (select col_slaeventtask
                             from tbl_slaevent se
                             inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'GOAL'
                             where col_slaeventtask = tsk.col_id
                             and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                    + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                    <= dee.col_datevalue))
                             --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                             --                       + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                             --                       <= dee.col_datevalue))
        --INCLUDE ONLY STARTING DATE EVENT TYPES THAT SATISFY "DO NOT MEET GOAL" CONDITION
        and dets.col_id in (select col_slaevent_dateeventtype
                              from tbl_slaevent se
                              inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'GOAL'
                              where col_slaeventtask = tsk.col_id
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
    select count(*) into v_count from tbl_slaevent se
      inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'
      where col_slaeventtask = v_TaskId;
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
      --THOSE TASKS CAN BE COUNTED AS COMPLETED AND "MEET DEADLINE" IN STATISTICS
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      select count(*) into v_count2
        from tbl_task tsk
        inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
        inner join tbl_dict_tasksystype tst on tsk.col_taskdict_tasksystype = tst.col_id
        inner join tbl_dict_taskstate ts on twi.col_tw_workitemdict_taskstate = ts.col_id
        --DATE WHEN SLA STARTED
        inner join tbl_dateevent des on tsk.col_id = des.col_dateeventtask
        inner join tbl_dict_dateeventtype dets on des.col_dateevent_dateeventtype = dets.col_id
        --DATE WHEN SLA ENDED
        inner join tbl_dateevent dee on tsk.col_id = dee.col_dateeventtask
        inner join tbl_dict_dateeventtype dete on dee.col_dateevent_dateeventtype = dete.col_id
        where tsk.col_id = v_TaskId
        and (tsk.col_statupdated is null or tsk.col_statupdated = 0)
        and ts.col_activity = v_stateTaskComplete
        --EXCLUDE TASKS THAT "DO NOT MEET AT LEAST ONE DEADLINE"
        and tsk.col_id not in (select col_slaeventtask
                                 from tbl_slaevent se
                                 inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'
                                 where col_slaeventtask = tsk.col_id
                                 and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                        + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                        < dee.col_datevalue))
                                 --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                                 --                       + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                                 --                       < dee.col_datevalue))
        --INCLUDE ONLY STARTING DATE EVENT TYPES THAT SATISFY "MEET DEADLINE" CONDITION
        and dets.col_id in (select col_slaevent_dateeventtype
                              from tbl_slaevent se
                              inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'
                              where col_slaeventtask = tsk.col_id
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
      --THOSE TASKS CAN BE COUNTED AS COMPLETED AND "DO NOT MEET DEADLINE" IN STATISTICS
      -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
      select count(*) into v_count2
        from tbl_task tsk
        inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
        inner join tbl_dict_tasksystype tst on tsk.col_taskdict_tasksystype = tst.col_id
        inner join tbl_dict_taskstate ts on twi.col_tw_workitemdict_taskstate = ts.col_id
        --DATE WHEN SLA STARTED
        inner join tbl_dateevent des on tsk.col_id = des.col_dateeventtask
        inner join tbl_dict_dateeventtype dets on des.col_dateevent_dateeventtype = dets.col_id
        --DATE WHEN SLA ENDED
        inner join tbl_dateevent dee on tsk.col_id = dee.col_dateeventtask
        inner join tbl_dict_dateeventtype dete on dee.col_dateevent_dateeventtype = dete.col_id
        where tsk.col_id = v_TaskId
        and (tsk.col_statupdated is null or tsk.col_statupdated = 0)
        and ts.col_activity = v_stateTaskComplete
        --INCLUDE TASKS THAT DO NOT MEET AT LEAST ONE GOAL
        and tsk.col_id in (select col_slaeventtask
                             from tbl_slaevent se
                             inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'
                             where col_slaeventtask = tsk.col_id
                             and (des.col_datevalue + (case when se.col_intervalds is not null then to_dsinterval(se.col_intervalds) else interval '0' day end)
                                                    + (case when se.col_intervalym is not null then to_yminterval(se.col_intervalym) else interval '0' year end)
                                                    <= dee.col_datevalue))
                             --and (des.col_datevalue + (case when setp.col_intervalds is not null then to_dsinterval(setp.col_intervalds) else interval '0' day end)
                             --                       + (case when setp.col_intervalym is not null then to_yminterval(setp.col_intervalym) else interval '0' year end)
                             --                       <= dee.col_datevalue))
        --INCLUDE ONLY STARTING DATE EVENT TYPES THAT SATISFY "DO NOT MEET GOAL" CONDITION
        and dets.col_id in (select col_slaevent_dateeventtype
                              from tbl_slaevent se
                              inner join tbl_dict_slaeventtype setp on se.col_slaeventdict_slaeventtype = setp.col_id and setp.col_code = 'DEADLINE'
                              where col_slaeventtask = tsk.col_id
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
  v_TaskComplete := 1;
  begin
    select tst.col_id, cwu.Id, to_char(trunc(dee.col_datevalue, 'DDD')), (dee.col_datevalue - des.col_datevalue) * 24 * 60
      into v_TaskSysType, v_CaseworkerId, v_YearMonth, v_Mins
      from tbl_task tsk
      inner join tbl_tw_workitem twi on tsk.col_tw_workitemtask = twi.col_id
      inner join tbl_dict_tasksystype tst on tsk.col_taskdict_tasksystype = tst.col_id
      inner join tbl_dict_taskstate ts on twi.col_tw_workitemdict_taskstate = ts.col_id
      inner join tbl_dateevent dee on tsk.col_id = dee.col_dateeventtask
      inner join tbl_dict_dateeventtype dete on dee.col_dateevent_dateeventtype = dete.col_id
      inner join tbl_dateevent des on tsk.col_id = des.col_dateeventtask
      inner join tbl_dict_dateeventtype dets on des.col_dateevent_dateeventtype = dets.col_id
      inner join vw_ppl_caseworkersusers cwu on dee.col_dateeventppl_caseworker = cwu.Id
      where tsk.col_id = v_TaskId
      and (tsk.col_statupdated is null or tsk.col_statupdated = 0)
      and ts.col_activity = v_stateTaskComplete
      and dete.col_code = v_SlaEndDateType
      and dets.col_code = v_SlaStartDateType
      and dee.col_datevalue between trunc(sysdate, 'DDD') and trunc(sysdate + interval '1' day, 'DDD')
      and des.col_datevalue = (select min(des2.col_datevalue)
                                      from tbl_dateevent des2
                                      inner join tbl_dict_dateeventtype dets2 on des2.col_dateevent_dateeventtype = dets2.col_id
                                      where des2.col_dateeventtask = v_TaskId
                                      and dets2.col_code = v_SlaStartDateType);
    exception
      when NO_DATA_FOUND then
        v_TaskComplete := null;
        v_TaskSysType := null;
        v_CaseworkerId := null;
        v_YearMonth := null;
        v_Mins := null;
      when TOO_MANY_ROWS then
        v_TaskComplete := null;
        v_TaskSysType := null;
        v_CaseworkerId := null;
        v_YearMonth := null;
        v_Mins := null;
  end;
  if (v_TaskComplete is not null) and (v_TaskSysType is not null) and (v_CaseWorkerId is not null) and (v_YearMonth is not null) then
    begin
      select col_id into v_id
        from tbl_statday
        where col_statdaydict_tasksystype = v_TaskSysType
        and col_statdayppl_caseworker = v_Caseworkerid
        and col_yearmonth = v_YearMonth;
      exception
        when NO_DATA_FOUND then
          v_id := null;
    end;
    if v_id is not null then
      begin
        select col_avginprocess, col_totalinprocess, col_totalclosed into v_AvgInProcess, v_TotalInProcess, v_TotalClosed from tbl_statday where col_id = v_id;
        exception
          when NO_DATA_FOUND then
            v_AvgInProcess := 0;
            v_TotalInProcess := 0;
      end;
      v_Mins := ((v_AvgInProcess * v_TotalClosed) + v_Mins) / (v_TotalClosed + 1);
      update tbl_statday
        set col_totalclosed = col_totalclosed + 1,
            col_meetgoal = col_meetgoal + v_MeetGoal,
            col_nomeetgoal = col_nomeetgoal + v_NoMeetGoal,
            col_meetdeadline = col_meetdeadline + v_MeetDeadline,
            col_nomeetdeadline = col_nomeetdeadline + v_NoMeetDeadline,
            col_avginprocess = v_Mins,
            col_totalinprocess = nvl(col_totalinprocess, 0) + v_Mins
        where col_id = v_id;
    else
      insert into tbl_statday(col_statdayppl_caseworker, col_statdaydict_tasksystype, col_yearmonth, col_totalclosed, col_meetgoal, col_nomeetgoal, col_meetdeadline, col_nomeetdeadline, col_avginprocess, col_totalinprocess)
        values(v_CaseworkerId, v_TaskSysType, v_YearMonth, 1, v_MeetGoal, v_NoMeetGoal, v_MeetDeadline, v_NoMeetDeadline, v_Mins, v_Mins);
    end if;
    --update tbl_task set col_statupdated = 1 where col_id = v_TaskId;
  end if;
end;