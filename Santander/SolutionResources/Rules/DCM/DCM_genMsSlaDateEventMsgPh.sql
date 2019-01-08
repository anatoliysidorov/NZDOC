DECLARE
  --input
  v_slaeventid INTEGER;
  --internal
  v_inCache INTEGER;
BEGIN
  v_slaeventid := :SLAEventId;
  v_inCache    := f_DCM_isSlaEventInCache(SlaEventID => v_slaeventid);
  --get cache from proper place
  IF v_inCache = 1 THEN
    SELECT et.col_name
    INTO PlaceholderResult
    FROM tbl_SlaEventCC se
    LEFT JOIN tbl_DICT_DateEventType et
    ON et.col_id    = se.COL_SLAEVENTCC_DATEEVENTTYPE
    WHERE se.col_id = v_slaeventid;
  ELSE
    SELECT et.col_name
    INTO PlaceholderResult
    FROM tbl_SlaEvent se
    LEFT JOIN tbl_DICT_DateEventType et
    ON et.col_id    = se.COL_SLAEVENT_DATEEVENTTYPE
    WHERE se.col_id = v_slaeventid;
  END IF;
  :PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';
EXCEPTION
WHEN no_data_found THEN
  :PlaceholderResult := 'NONE';
WHEN OTHERS THEN
  :PlaceholderResult := 'SYSTEM ERROR';
END;