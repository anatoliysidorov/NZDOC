declare
    v_refObjectId number;
    v_refObjectName nvarchar2(255);
    v_xmlResult XMLTYPE;
    v_result nclob;
begin

    v_refObjectId := :RefObjectId;
    v_refObjectName := :RefObjectName;
    v_result := NULL;
    v_xmlResult := NULL;
    
    begin
        select xmlroot (
                xmlelement (
                    "ATTRIBUTES",
                    xmlagg (
                        xmlelement (
                            "ATTRIBUTE",
                            xmlforest (
                            v_refObjectName AS NAME,
                            ra.COL_CODE AS CODE,
                            NVL (fa.COL_APICODE, ra.COL_CODE) AS APICODE,
                            dt.COL_CODE AS TYPECODE,
                            dt.COL_NAME AS TYPENAME,
                            dt.COL_TYPECODE AS APPBASECODE,
                            NVL (ra.COL_USEONCREATE, 0) AS USEONCREATE,
                            NVL (ra.COL_USEONUPDATE, 0) AS USEONUPDATE,
                            NVL (ra.COL_USEONDETAIL, 0) AS USEONDETAIL,
                            NVL (ra.COL_USEONLIST, 0) AS USEONLIST,
                            NVL (ra.COL_USEONSEARCH, 0) AS USEONSEARCH,
                            (CASE
                                WHEN NVL (ra.COL_USEONSEARCH, 0) = 1
                                THEN
                                    'equal'
                                ELSE
                                    NULL
                                END) AS SEARCHTYPE)))),
                VERSION '1.0',
                STANDALONE YES) into v_xmlResult
        from tbl_dom_referenceattr ra
                inner join tbl_fom_attribute fa
                on fa.col_id = ra.col_dom_refattrfom_attr
                inner join tbl_dict_datatype dt
                on dt.col_id = fa.col_fom_attributedatatype
        where ra.col_dom_refattrdom_refobject = v_refObjectId;
    exception when no_data_found then
        v_xmlResult := NULL;
    end;
    
    if(v_xmlResult is not null) then
        v_result := dbms_xmlgen.CONVERT(v_xmlResult.getClobVal());
    end if;
    
    return v_result;
end;