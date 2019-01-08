declare
  v_result interval day to second;
  v_StartDate date;
  v_EndDate date;
  v_CurrDate date;
  v_result2 number;
  v_Deduction interval day to second;
  v_count Integer;
begin
  v_StartDate := :StartDate;
  v_EndDate := :EndDate;
  v_Count := 0;
  v_CurrDate := v_StartDate;
  v_result := to_dsinterval('0 0' || ':' || '0' || ':' || '0');
  v_Deduction := to_dsinterval('0 0' || ':' || '0' || ':' || '0');
  while (v_CurrDate < v_EndDate)
  loop
    v_result2 := f_SLA_isWeekendHoliday(CurrDate => v_CurrDate, EndDate => v_EndDate, StartDate => v_StartDate);
    if v_result2 = 1 then
      v_Deduction := v_Deduction + numtodsinterval(1, 'DAY');
    end if;
    v_count := v_count + 1;
    v_CurrDate := v_StartDate + NUMTODSINTERVAL(v_count,'DAY');
  end loop;
  v_result2 := f_SLA_isWeekendHoliday(CurrDate => v_EndDate, EndDate => v_EndDate, StartDate => v_StartDate);
  if v_result2 = 1 then
    v_Deduction := v_Deduction + numtodsinterval(v_EndDate - trunc(v_EndDate), 'DAY');
  end if;
  v_result := v_deduction;
  return to_char(v_result);
end;