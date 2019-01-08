DECLARE 
    v_res nclob;
    v_fomObjectID number;
    
BEGIN
    v_fomObjectID := :FOMObjectId;

    SELECT
       LISTAGG(TO_CHAR(INITCAP(fo.col_name)), ' -> ') WITHIN GROUP (ORDER BY subQ.LVL DESC) into v_res
    FROM
    (
        SELECT 
                   1 AS LVL,
                   to_number(v_fomObjectID) AS PARENTID,
                   NULL AS CHILDID
        FROM DUAL
        union
        SELECT 
                 LEVEL + 1 AS LVL,
                 fr.COL_PARENTFOM_RELFOM_OBJECT AS PARENTID,
                 fr.COL_CHILDFOM_RELFOM_OBJECT AS CHILDID
        FROM TBL_FOM_RELATIONSHIP fr
        CONNECT BY PRIOR  fr.COL_PARENTFOM_RELFOM_OBJECT = fr.COL_CHILDFOM_RELFOM_OBJECT
        START WITH  fr.COL_CHILDFOM_RELFOM_OBJECT = v_fomObjectID
    ) subQ
    INNER JOIN TBL_FOM_OBJECT fo ON fo.col_id = subQ.PARENTID
    WHERE (select count(*) 
          from tbl_som_object s 
          where s.col_som_objectfom_object = fo.col_id 
                and s.col_type not in ('referenceObject')) > 0        
    ORDER BY subQ.LVL DESC;
    
    return v_res;
END;   
    
   