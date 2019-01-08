DECLARE
  --input
  v_slaeventid INTEGER;
  
  --internal
  v_inCache INTEGER;
  v_dsinterval NVARCHAR2(255);
  v_yminterval NVARCHAR2(255);
BEGIN
  v_slaeventid  := :SLAEventId;
  v_inCache := f_DCM_isSlaEventInCache(SlaEventID => v_slaeventid);
  
  --get data from proper place
  IF v_inCache = 1 THEN
    SELECT COL_INTERVALDS, COL_INTERVALYM
    INTO v_dsinterval, v_yminterval
    FROM tbl_SlaEventCC
    WHERE col_id = v_slaeventid;
  ELSE
    SELECT COL_INTERVALDS, COL_INTERVALYM
    INTO v_dsinterval, v_yminterval
    FROM tbl_SlaEvent
    WHERE col_id = v_slaeventid;
  END IF;
  
  --normalize the intervals  
	:PlaceholderResult := '{[this.INTERVAL(';
	:PlaceholderResult := :PlaceholderResult || NVL(EXTRACT(YEAR FROM TO_YMINTERVAL(v_yminterval)), '0') || ',';
	:PlaceholderResult := :PlaceholderResult || NVL(EXTRACT(MONTH FROM TO_YMINTERVAL(v_yminterval)), '0') || ',';
	:PlaceholderResult := :PlaceholderResult || NVL(EXTRACT(DAY FROM TO_DSINTERVAL(v_dsinterval)), '0') || ',';
	:PlaceholderResult := :PlaceholderResult || NVL(EXTRACT(HOUR FROM TO_DSINTERVAL(v_dsinterval)), '0') || ',';
	:PlaceholderResult := :PlaceholderResult || NVL(EXTRACT(MINUTE FROM TO_DSINTERVAL(v_dsinterval)), '0') || ',';
	:PlaceholderResult := :PlaceholderResult || NVL(EXTRACT(SECOND FROM TO_DSINTERVAL(v_dsinterval)), '0');
	:PlaceholderResult := :PlaceholderResult || ')]}';
  
	:PlaceholderResult := '<b>' || :PlaceholderResult || '</b>';
EXCEPTION
WHEN no_data_found THEN
  :PlaceholderResult := 'NONE';
WHEN OTHERS THEN
  :PlaceholderResult := 'SYSTEM ERROR';
END;