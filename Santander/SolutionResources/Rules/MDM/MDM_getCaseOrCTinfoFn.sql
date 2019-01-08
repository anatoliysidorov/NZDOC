DECLARE
    --input
    v_TaskID INTEGER; --optional
    v_CaseID INTEGER; --optional
    v_CaseTypeID INTEGER; --optional

    --calculated
    v_temp INTEGER;
    v_result NVARCHAR2(255);

    --OUTPUT
    v_create_ConfigId  INTEGER;
    v_create_ConfigCode NVARCHAR2(255);
    v_create_ConfigName NVARCHAR2(255);
    v_create_ModelId  INTEGER;

    v_edit_ConfigId  INTEGER;
    v_edit_ConfigCode NVARCHAR2(255);
    v_edit_ConfigName NVARCHAR2(255);
    v_edit_ModelId  INTEGER;
BEGIN
    --input
    v_TaskID := :TaskId;
    v_CaseID := NVL(:CaseID, f_DCM_getCaseIdByTaskId(v_TaskID));
    v_CaseTypeID := NVL(:CaseTypeID, f_DCM_getCaseTypeForCase(v_CaseID));

    --calculate CREATE config
    SELECT col_id,
           col_code,
           col_name,
           col_dom_configdom_model
    INTO   v_create_ConfigId,
           v_create_ConfigCode,
           v_create_ConfigName,
           v_create_ModelId
    FROM   tbl_dom_config
    WHERE  col_dom_configdom_model IN(
           SELECT col_id
           FROM   tbl_dom_model
           WHERE  col_dom_modelmdm_model =(
                  SELECT mm.col_id
                  FROM   tbl_mdm_model mm
                    inner join tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
                    where ct.col_id = v_casetypeid
                  )
           )
           AND
    lower(col_purpose) = 'create';

    --calculate EDIT config
    SELECT col_id,
           col_code,
           col_name,
           col_dom_configdom_model
    INTO   v_edit_ConfigId,
           v_edit_ConfigCode,
           v_edit_ConfigName,
           v_edit_ModelId
    FROM   tbl_dom_config
    WHERE  col_dom_configdom_model IN(
           SELECT col_id
           FROM   tbl_dom_model
           WHERE  col_dom_modelmdm_model =(
                  SELECT mm.col_id
                  FROM   tbl_mdm_model mm
                    inner join tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
                    where ct.col_id = v_casetypeid
                  )
           )
           AND
    lower(col_purpose) = 'edit';

    --set values
    :calc_CaseId := v_CaseID;
    :calc_TaskId := v_TaskID;
    :calc_CaseTypeId := v_CaseTypeID;

    :create_ConfigId  := v_create_ConfigId;
    :create_ConfigCode  := v_create_ConfigCode;
    :create_ConfigName  := v_create_ConfigName;
    :create_ModelId  := v_create_ModelId;

    :edit_ConfigId  := v_edit_ConfigId ;
    :edit_ConfigCode  := v_edit_ConfigCode;
    :edit_ConfigName  := v_edit_ConfigName;
    :edit_ModelId  := v_edit_ModelId;

EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;