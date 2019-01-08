declare
  v_CaseId Integer;
  v_state nvarchar2(255);
  v_result number;
  v_target Integer;
  v_finishdateeventvalue date;
  v_slaeventdate date;
  v_startdateeventby nvarchar2(255);
  v_startdateeventvalue date;
begin
  v_CaseId := :CaseId;
  for rec in
  (select cs.col_id as CaseStateId, cs.col_code as CaseStateCode, cs.col_name as CaseStateName, cs.col_activity as CaseStateActivity,
       det.col_id as DateEventTypeId, det.col_code as DateEventTypeCode, det.col_name as DateEventTypeName
   from tbl_dict_casestate cs
   inner join tbl_dict_csest_dtevtp csdet on cs.col_id = csdet.col_csest_dtevtpcasestate
   inner join tbl_dict_dateeventtype det on csdet.col_csest_dtevtpdateeventtype = det.col_id
   inner join tbl_cw_workitemcc cwi on cs.col_id = cwi.col_cw_workitemccdict_casest
   inner join tbl_casecc cse on cwi.col_id = cse.col_cw_workitemcccasecc
   where cse.col_id = v_CaseId)
   loop
     v_result := f_DCM_createCaseDateEventCC (Name => rec.DateEventTypeCode, CaseId => v_CaseId);
   end loop;

  --Check if CASE is in FINISH state
  begin
    select dcs.col_id into v_target
    from tbl_dict_casestate dcs
    inner join tbl_case cs on dcs.col_id = cs.col_casedict_casestate
    where dcs.col_isfinish = 1;
    exception
    when NO_DATA_FOUND then
    v_target := null;
  end;

  for rec in
  (
  select col_slaeventccslaevent as SeId, col_slaeventcc_dateeventtype as DateEventTypeId
  from tbl_slaeventcc
  where col_slaeventcccasecc = v_CaseId
  )
  loop
    v_finishdateeventvalue := null;
    v_slaeventdate := null;
    v_startdateeventby := null;
    v_startdateeventvalue := null;

    begin
      select max(col_datevalue) into v_startdateeventvalue
      from tbl_dateeventcc
      where col_dateeventcccasecc = v_CaseId
      and col_dateeventcc_dateeventtype = rec.DateEventTypeId;
    exception
      when NO_DATA_FOUND then v_startdateeventvalue := null;
    end;

   if v_startdateeventvalue is not null then
    begin
      select s.col_performedby into v_startdateeventby
      from
          (
          select rownum as rn, col_performedby
          from tbl_dateeventcc
          where col_dateeventcccasecc = v_CaseId
          and col_dateeventcc_dateeventtype = rec.DateEventTypeId
          and col_datevalue = v_startdateeventvalue
          ) s
      where s.rn=1;
    end;

    if v_target is not null then
      v_finishdateeventvalue := v_startdateeventvalue;
    end if;

    update tbl_slaeventcc se2
    set col_finishdateeventvalue = v_finishdateeventvalue,
         col_startdateeventvalue = v_startdateeventvalue,
         col_startdateeventby = v_startdateeventby,
         col_slaeventdate = v_startdateeventvalue + nvl(to_dsinterval(se2.col_intervalds), to_dsinterval('0 0' || ':' || '0' || ':' || '0')) + nvl(to_yminterval(se2.col_intervalym), to_yminterval('0-0'))
    where col_id=rec.SeId;

   end if; --v_startdateeventvalue is not null

  end loop;

  update tbl_casecc cs
  set col_goalslaeventdate = (select max(col_slaeventdate) from tbl_slaeventcc where col_slaeventcccasecc = cs.col_id and col_slaeventcc_slaeventtype =
  (select col_id from tbl_dict_slaeventtype where col_code = 'GOAL')),
  col_dlineslaeventdate = (select max(col_slaeventdate) from tbl_slaeventcc where col_slaeventcccasecc = cs.col_id and col_slaeventcc_slaeventtype =
  (select col_id from tbl_dict_slaeventtype where col_code = 'DEADLINE'))
  where cs.col_id = v_CaseId;

end;