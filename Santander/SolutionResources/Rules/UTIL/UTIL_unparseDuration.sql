-- converting duration in SEC to FORMAT="4w 3d 2h 17m"
declare
  v_durationsec number;
  v_durationstr  varchar2(30);
  v_week         integer;
  v_day          integer;
  v_hour         integer;
  v_min          integer;
begin
  begin
    v_durationsec := nvl(to_number(:duration), 0);
  
    select trunc(v_durationsec / (5 * 24 * 60 * 60)) into v_week from dual;
    v_durationsec := v_durationsec - v_week * 5 * 24 * 60 * 60;
  
    select trunc(v_durationsec / (24 * 60 * 60)) into v_day from dual;
    v_durationsec := v_durationsec - v_day * 24 * 60 * 60;
  
    select trunc(v_durationsec / (60 * 60)) into v_hour from dual;
    v_durationsec := v_durationsec - v_hour * 60 * 60;
  
    select round(v_durationsec / (60)) into v_min from dual;
  
    select decode(v_week, 0, '', v_week || 'w ') || decode(v_day, 0, '', v_day || 'd ') ||
           decode(v_hour, 0, '', v_hour || 'h ') || decode(v_min, 0, '', v_min || 'm')
      into v_durationstr
      from dual;
  
  exception
    when others then
      v_durationstr := null;
  end;

  return v_durationstr;
end;