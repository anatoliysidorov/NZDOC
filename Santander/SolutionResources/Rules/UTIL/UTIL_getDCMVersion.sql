DECLARE
  v_version VARCHAR2(255);
BEGIN

  SELECT VALUE INTO v_version FROM config WHERE NAME = 'DCM_VERSION';

  RETURN v_version;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN '4.3.132.0-dev';
END;