DECLARE
    /*--input*/
    v_caseid INTEGER; /*--OPTIONAL*/
    v_casetypeid INTEGER;
    v_purpose NVARCHAR2(255) ; /*--MANDATORY*/

    /*--output*/
    v_ConfigId INTEGER;
    v_ConfigCode NVARCHAR2(255) ;
    v_ConfigName NVARCHAR2(255) ;
    v_ModelId INTEGER;

BEGIN
    v_caseid := :CaseId;
    v_casetypeid := NVL(:CaseTypeId,f_DCM_getCaseTypeForCase(v_caseid)) ;
    v_purpose := :Purpose;

    SELECT col_id,
           col_code,
           col_name,
           col_dom_configdom_model
    INTO   v_ConfigId,
           v_ConfigCode,
           v_ConfigName,
           v_ModelId
    FROM   tbl_dom_config
    WHERE  col_dom_configdom_model IN(
           SELECT col_id
           FROM   tbl_dom_model
           WHERE  col_dom_modelmdm_model =(
                  SELECT mm.col_id
                  FROM   tbl_mdm_model mm
            INNER JOIN tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
            WHERE ct.col_id = v_casetypeid
                  )
           )
           AND
           lower(col_purpose) = lower(v_purpose) ;
    
    :ConfigId := v_ConfigId;
    :ConfigCode := v_ConfigCode;
    :ConfigName := v_ConfigName;
    :ModelId := v_ModelId;

EXCEPTION
WHEN OTHERS THEN
    :ConfigId := NULL;
    :ConfigCode := NULL;
    :ConfigName := NULL;
    :ModelId := NULL;
END;