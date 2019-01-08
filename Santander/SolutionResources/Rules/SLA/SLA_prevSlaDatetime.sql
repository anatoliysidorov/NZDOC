declare
  v_IntervalDS nvarchar2(255);
  v_IntervalYM nvarchar2(255);
  v_StartDateEventValue date;
  v_AttemptCount Integer;
  v_result date;
begin
  v_AttemptCount := :AttemptCount;
  v_IntervalDS := :IntervalDS;
  v_IntervalYM := :IntervalYM;
  v_StartDateEventValue := :StartDateEventValue;
  v_result := v_StartDateEventValue + 
        (case when v_IntervalDS is not null then to_dsinterval(v_IntervalDS) else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (v_AttemptCount + 1) + 
        (case when v_IntervalYM is not null then to_yminterval(v_IntervalYM) else to_yminterval('0-0') end) * (v_AttemptCount + 1);
  return v_result;
end;