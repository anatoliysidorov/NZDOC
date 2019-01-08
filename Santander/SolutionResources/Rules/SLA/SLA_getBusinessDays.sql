declare
  v_StartDate date;
  v_EndDate date;
  v_CurrDate date;
  v_IntervalDS Interval DAY to SECOND;
  v_result nvarchar2(255);
  v_count number;
  v_result1 number;
begin
  v_StartDate := :StartDate;
  v_EndDate := :EndDate;
  v_CurrDate := v_StartDate;
  v_IntervalDS := NUMTODSINTERVAL(0,'DAY');
  v_count := 0;
  while (true)
  loop
    v_CurrDate := v_StartDate + NUMTODSINTERVAL(v_count,'DAY');
    begin
      select 1 into v_result1 from dual where to_char(v_CurrDate, 'D') not in (1, 7)
        and (trunc(v_CurrDate) not in
         (select trunc(col_holiday) from tbl_cal_holiday where to_char(col_holiday, 'D') not in (1,7) and trunc(col_holiday) = trunc(v_CurrDate)));
      exception
      when NO_DATA_FOUND then
      v_result1 := 0;
    end;
    if (v_result1 = 1 and v_CurrDate <= v_EndDate) then
      v_IntervalDS := v_IntervalDS + NUMTODSINTERVAL(1, 'DAY');
    elsif (v_result1 = 1 and v_CurrDate > v_EndDate) then
      v_IntervalDS := v_IntervalDS + NUMTODSINTERVAL((v_EndDate - (v_CurrDate - 1)), 'DAY');
      return to_char(v_IntervalDS);
    elsif (v_CurrDate > v_EndDate) then
      return to_char(v_IntervalDS);
    end if;
    v_count := v_count + 1;
  end loop;
  return v_result;
end;