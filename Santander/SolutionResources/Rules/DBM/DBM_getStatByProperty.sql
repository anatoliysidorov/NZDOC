declare
  v_configid Integer;
  v_timeperiodcount Integer;
  v_timeperiodtype nvarchar2(255);
  v_result number;
  v_ITEMS sys_refcursor;
  v_TotalCount number;
  v_ErrorCode number;
  v_ErrorMessage nvarchar2(255);
begin
  v_configid := :ConfigId;
  v_timeperiodcount := :TimePeriodCount;
  v_timeperiodtype := :TimePeriodType;
  if v_timeperiodtype is null then
    v_timeperiodtype := 'MONTHLY';
  end if;
  if v_timeperiodcount is null then
    v_timeperiodcount := 1;
  end if;
  if v_timeperiodtype <> 'MONTHLY' and v_timeperiodtype <> 'DAYLY' and v_timeperiodtype <> 'WEEKLY' then
    :ErrorCode := 102;
    :ErrorMessage := 'Time period type must be one of the following: MONTHLY or DAYLY or WEEKLY';
    return -1;
  end if;
  v_result := f_DBM_getStatByPropertyFn(ConfigId => v_configid, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage, ITEMS => v_ITEMS, TimePeriodCount => v_timeperiodcount, TimePeriodType => v_timeperiodtype, TotalCount => v_TotalCount);
  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  :TotalCount := v_TotalCount;
  :ITEMS := v_ITEMS;
end;