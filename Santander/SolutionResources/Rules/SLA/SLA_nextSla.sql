declare
  v_IntervalDS nvarchar2(255);
  v_IntervalYM nvarchar2(255);
  v_StartDateEventValue date;
  v_EndDateEventValue date;
  v_AttemptCount Integer;
  v_dateFrom date;
  v_dateTo date;
  v_result number;
begin
  v_AttemptCount := :AttemptCount;
  v_EndDateEventValue := :EndDateEventValue;
  v_IntervalDS := :IntervalDS;
  v_IntervalYM := :IntervalYM;
  v_StartDateEventValue := :StartDateEventValue;
  v_dateFrom := v_StartDateEventValue + 
        (case when v_IntervalDS is not null then to_dsinterval(v_IntervalDS) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (v_AttemptCount + 1) + 
        (case when v_IntervalYM is not null then to_yminterval(v_IntervalYM) else to_yminterval('0-0') end) * (v_AttemptCount + 1);
  v_dateTo := v_EndDateEventValue;
  if v_dateFrom > v_dateTo then
    v_result := v_dateFrom - v_dateTo;
  else
    v_result := 999999;
  end if;
  return v_result;
end;