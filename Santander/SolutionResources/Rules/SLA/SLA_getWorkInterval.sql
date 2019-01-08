declare
  v_StartDate date;
  v_CurrDate date;
  v_result nvarchar2(255);
  v_IntervalDS Interval Day To Second;
  v_IntervalDSExt Interval Day To Second;
  v_IntervalDSLeft Interval Day to Second;
  v_count number;
  v_result1 number;
begin
  v_StartDate := :StartDate;
  v_CurrDate := v_StartDate;
  v_IntervalDS := to_dsinterval(:IntervalDS);
  v_IntervalDSExt := v_IntervalDS;
  v_IntervalDSLeft := v_IntervalDS;
  v_count := 0;
  while (true)
  loop
    v_CurrDate := StartDate + NUMTODSINTERVAL(v_count,'DAY');
    begin
      select 1 into v_result1 from dual where to_char(v_CurrDate, 'D') in (1, 7)
        or (trunc(v_CurrDate) in
         (select trunc(col_holiday) from tbl_cal_holiday where to_char(col_holiday, 'D') not in (1,7) and trunc(col_holiday) = trunc(v_CurrDate)));
      exception
      when NO_DATA_FOUND then
      v_result1 := 0;
    end;
    if (v_result1 = 1) then
      v_IntervalDSExt := v_IntervalDSExt + NUMTODSINTERVAL(1, 'DAY');
    else
      v_IntervalDSLeft := v_IntervalDSLeft - NUMTODSINTERVAL(1, 'DAY');
    end if;
    if extract(DAY from v_IntervalDSLeft) < 1 then
      v_result := to_char(v_IntervalDSExt);
      return v_result;
    end if;
    v_count := v_count + 1;
  end loop;
  return v_result;
end;