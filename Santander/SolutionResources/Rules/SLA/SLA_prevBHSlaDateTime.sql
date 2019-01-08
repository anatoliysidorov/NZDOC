declare
  v_IntervalDS nvarchar2(255);
  v_IntervalDSH nvarchar2(255);
  v_IntervalYM nvarchar2(255);
  v_StartDateEventValue date;
  v_AttemptCount Integer;
  v_TaskId Integer;
  v_result date;
begin
  v_AttemptCount := :AttemptCount;
  v_IntervalDS := :IntervalDS;
  v_IntervalYM := :IntervalYM;
  v_StartDateEventValue := :StartDateEventValue;
  v_StartDateEventValue := f_SLA_nextWorkDate(CurrDate => v_StartDateEventValue);
  v_TaskId := :TaskId;
  v_IntervalDSH := f_SLA_calcHold(TaskId => v_TaskId);
  v_IntervalDS := to_char(to_dsinterval(v_IntervalDS) + to_dsinterval(v_IntervalDSH));
  v_result := v_StartDateEventValue + 
        (case when v_IntervalDS is not null then to_dsinterval(f_SLA_getWorkInterval(IntervalDS => v_IntervalDS, StartDate => v_StartDateEventValue))
              else to_dsinterval('0 0' || ':' || '0' || ':' || '0') end) * (v_AttemptCount + 1) + 
        (case when v_IntervalYM is not null then to_yminterval(v_IntervalYM) else to_yminterval('0-0') end) * (v_AttemptCount + 1);
  v_result := f_SLA_nextWorkDate(CurrDate => v_result);
  return v_result;
end;