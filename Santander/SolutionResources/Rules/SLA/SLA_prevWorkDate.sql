declare
  v_CurrDate date;
  v_result date;
  v_count number;
  v_result1 number;
begin
  v_CurrDate := :CurrDate;
  v_count := 0;
  while (true)
  loop
    v_result := v_CurrDate - NUMTODSINTERVAL(v_count,'DAY');
    begin
      select 1 into v_result1 from dual where to_char(v_result, 'D') not in (1, 7)
        and (trunc(v_result) not in
         (select trunc(col_holiday) from tbl_cal_holiday where to_char(col_holiday, 'D') not in (1,7) and trunc(col_holiday) = trunc(v_result)));
      exception
      when NO_DATA_FOUND then
      v_result1 := 0;
    end;
    if (v_result1 = 1) then
      return v_result;
    end if;
    v_count := v_count + 1;
  end loop;
  return v_result;
end;