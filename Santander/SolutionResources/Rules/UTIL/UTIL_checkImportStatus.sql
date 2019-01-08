DECLARE
  v_queueid     INT := NVL(:QUEUEID, 0);
  v_xmlid       INT := NVL(:XMLID, 0);
  v_queuestatus INT; --1=pending, 2=executing, 4/16=processing, 8=processed
  v_queueerror  INT; --1=no error, 2=error
  v_xmlstatus   VARCHAR2(20);
  v_status      INT; -- 0=no started, 1=working, 2=success, 3=fail
  v_message     NCLOB;
  v_notes       NCLOB;
BEGIN
  --get queue status
  IF v_queueid > 0 THEN
    BEGIN
      SELECT PROCESSEDSTATUS, ERRORSTATUS INTO v_queuestatus, v_queueerror FROM QUEUE_EVENT WHERE QUEUEID = v_queueid;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_queuestatus := NULL;
        v_queueerror  := NULL;
    END;
  END IF;

  --get xml status
  IF v_xmlid > 0 THEN
    BEGIN
      SELECT UPPER(col_ImportStatus), col_notes INTO v_xmlstatus, v_notes FROM tbl_ImportXML WHERE col_id = v_xmlid;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_xmlstatus := NULL;
    END;
  END IF;

  --calculate true status
  IF ((v_queuestatus = 8 AND v_queueerror = 2) OR v_xmlstatus = 'LOADED WITH ERROR') OR
     ((v_queuestatus = 8 AND v_queueerror = 1) AND v_notes IS NULL) THEN
    SELECT ERROR INTO v_message FROM QUEUE_EVENT WHERE QUEUEID = v_queueid;
    v_message := NVL(v_message, 'Please contact administrator');
    v_status  := 3;
  ELSIF v_queuestatus = 1 THEN
    v_status := 0;
  ELSIF v_queuestatus = 2 OR v_queuestatus = 4 OR v_queuestatus = 16 THEN
    v_status := 1;
  ELSIF (v_queueid = 0 OR (v_queuestatus = 8 AND v_queueerror = 1)) AND v_xmlstatus = 'SUCCESS' THEN
    v_status := 2;
  ELSE
    v_status  := 0;
    v_message := 'No information';
  END IF;

  :message    := v_message;
  :procStatus := v_status;
EXCEPTION
  WHEN OTHERS THEN
    :message    := 'Please contact administrator';
    :procStatus := 3;
END;