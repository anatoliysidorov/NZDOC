DECLARE
    
    v_result    NUMBER;
    v_errorCode NUMBER;
    v_errorMessage NCLOB;
BEGIN
    
    v_errorCode := 0;
    v_errorMessage := '';
    
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;
    
    --Check that all listed AppBase pages are deployed
    FOR rec IN
    (
        SELECT ap.col_id AssocPageId,
            ap.col_title Title,
            ap.col_pagecode AssocPageCode,
            dp.code
        FROM tbl_assocpage ap
            LEFT JOIN Vw_Util_Deployedpage dp ON dp.code = ap.col_pagecode
        WHERE lower(col_pagecode) LIKE('root_%')
            AND dp.code IS NULL
    )
    LOOP
        v_errorCode := 131;
        v_errorMessage := v_errorMessage || '<li>Associated Page '||rec.Title||' with Id# '||TO_CHAR(rec.AssocPageId) ||' references a page that is not deployed: '|| rec.AssocPageCode||'</li>';
    END LOOP;
    --Check if FOM forms is presented
    FOR rec IN
    (
        SELECT ap.col_id AssocPageId,
            ap.Col_Assocpageform,
            ap.col_title Title,
            fm.col_code FOMCode
        FROM Tbl_Assocpage ap
            LEFT JOIN tbl_fom_form fm ON Ap.Col_Assocpageform = fm.col_id
        WHERE NVL(ap.Col_Assocpageform, 0) > 0 AND fm.col_id IS NULL
    )
    LOOP
        v_errorCode := 132;
        v_errorMessage := v_errorMessage || '<li>Associated Page '||rec.Title||' with Id# '||TO_CHAR(rec.AssocPageId) ||' references non-existent form: '||rec.FOMCode||'</li>';
    
    END LOOP;
    
    :ErrorCode := v_errorCode;
    :ErrorMessage := v_errorMessage;

END;