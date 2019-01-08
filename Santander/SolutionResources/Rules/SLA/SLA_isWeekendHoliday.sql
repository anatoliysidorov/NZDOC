declare
  v_StartDate date;
  v_EndDate date;
  v_CurrDate date;
  v_result number;
begin
  v_CurrDate := :CurrDate;
  v_StartDate := :StartDate;
  v_EndDate := :EndDate;
  select
    case when to_char(v_CurrDate, 'D') in (1,7)
         or trunc(v_CurrDate) in (select trunc(col_holiday) from tbl_cal_holiday where to_char(col_holiday, 'D') not in (1,7) and trunc(col_holiday) between v_StartDate and v_EndDate)
         then 1
         else 0 end
         into v_result from dual;
  return v_result;
end;