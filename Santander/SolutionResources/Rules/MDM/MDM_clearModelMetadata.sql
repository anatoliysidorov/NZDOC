DECLARE
  v_result  NUMBER;
  v_modelid NUMBER;
BEGIN
  v_modelid := :ModelId;

  v_result := f_dom_clearDOMModel(ModelId => v_modelid, DeleteFOM => 1);

  DELETE FROM TBL_MDM_LOG WHERE COL_MDM_LOGMDM_MODEL = v_modelid;
  DELETE FROM TBL_DOM_MODELJOURNAL
   WHERE COL_MDM_MODVERDOM_MODJRNL IN (SELECT COL_ID FROM TBL_MDM_MODELVERSION WHERE COL_MDM_MODELVERSIONMDM_MODEL = v_modelid);
  DELETE FROM TBL_MDM_MODELVERSION WHERE COL_MDM_MODELVERSIONMDM_MODEL = v_modelid;
  --DELETE FROM tbl_mdm_model WHERE COL_ID = v_modelid;
END;