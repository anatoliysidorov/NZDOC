DECLARE
BEGIN
   :new.COL_NAME := REGEXP_REPLACE(:new.COL_NAME, n'[\/:*?"<>|]', '_');
END;