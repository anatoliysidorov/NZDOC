DECLARE

  v_CaseId           NUMBER;
  v_dateEventValue   DATE;

BEGIN

  v_CaseId          := :CaseId;
  v_dateEventValue := NVL(:DateEventValue, SYSDATE);


  IF f_DCM_isCaseInCache(v_CaseId)=0 THEN
    UPDATE TBL_CASE CS 
      SET COL_DATEEVENTVALUE = v_dateEventValue,      
          COL_GOALSLADATETIME = (case when (select sseg.col_intervalds from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.col_casedict_state)
                                  is null
                                  and (select sseg.col_intervalym from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.col_casedict_state)
                                  is null then null
                                  else v_dateEventValue end) + 
                                  (case when (select sseg.col_intervalds from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.col_casedict_state)
                                  is not null then
                                  (select  to_dsinterval(sseg.col_intervalds) from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.col_casedict_state)
                                  else to_dsinterval('0 000') end) +
                                  (case when (select sseg.col_intervalym from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.col_casedict_state)
                                  is not null then
                                  (select to_yminterval(sseg.col_intervalym) from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.col_casedict_state)
                                  else to_yminterval('0-0') end),
          COL_DLINESLADATETIME = (case when (select ssed.col_intervalds from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.col_casedict_state)
                                   is null
                                   and (select ssed.col_intervalym from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.col_casedict_state)
                                   is null then null
                                   else v_dateEventValue end) + 
                                   (case when (select ssed.col_intervalds from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.col_casedict_state)
                                   is not null then
                                   (select  to_dsinterval(ssed.col_intervalds) from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.col_casedict_state)
                                   else to_dsinterval('0 000') end) +
                                   (case when (select ssed.col_intervalym from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.col_casedict_state)
                                   is not null then
                                   (select to_yminterval(ssed.col_intervalym) from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.col_casedict_state)
                                   else to_yminterval('0-0') end)
      WHERE COL_ID = v_CaseId;      
  END IF;


  IF f_DCM_isCaseInCache(v_CaseId)=1 THEN
    UPDATE TBL_CASECC CS 
      SET COL_DATEEVENTVALUE = v_dateEventValue,      
          COL_GOALSLADATETIME = (case when (select sseg.col_intervalds from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                  is null
                                  and (select sseg.col_intervalym from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                  is null then null
                                  else v_dateEventValue end) + 
                                  (case when (select sseg.col_intervalds from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                  is not null then
                                  (select  to_dsinterval(sseg.col_intervalds) from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                  else to_dsinterval('0 000') end) +
                                  (case when (select sseg.col_intervalym from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                  is not null then
                                  (select to_yminterval(sseg.col_intervalym) from tbl_dict_stateslaevent sseg where sseg.col_servicesubtype = 'goal' and sseg.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                  else to_yminterval('0-0') end),
          COL_DLINESLADATETIME = (case when (select ssed.col_intervalds from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                   is null
                                   and (select ssed.col_intervalym from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                   is null then null
                                   else v_dateEventValue end) + 
                                   (case when (select ssed.col_intervalds from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                   is not null then
                                   (select  to_dsinterval(ssed.col_intervalds) from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                   else to_dsinterval('0 000') end) +
                                   (case when (select ssed.col_intervalym from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                   is not null then
                                   (select to_yminterval(ssed.col_intervalym) from tbl_dict_stateslaevent ssed where ssed.col_servicesubtype = 'deadline' and ssed.col_stateslaeventdict_state = cs.COL_CaseCCDICT_State)
                                   else to_yminterval('0-0') end)
      WHERE COL_ID = v_CaseId;      
  END IF;      
END;
