declare
    v_fomObjectId number;
    v_xmlResult XMLTYPE;
    v_result nclob;
begin

    v_fomObjectId := :FOMObjectId;
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
                              fa.COL_NAME AS NAME,
                              fa.COL_CODE AS CODE,
                              NVL (fa.COL_APICODE, fa.COL_CODE) AS APICODE,
                              dt.COL_CODE AS TYPECODE,
                              dt.COL_NAME AS TYPENAME,
                              dt.COL_TYPECODE AS APPBASECODE,
                              dt.COL_SEARCHTYPE AS SEARCHTYPE)))),
                  VERSION '1.0',
                  standalone yes) into v_xmlResult
          from    tbl_fom_attribute fa
               inner join
                  tbl_dict_datatype dt
               ON dt.col_ID = fa.COL_FOM_ATTRIBUTEDATATYPE
         where fa.col_fom_attributefom_object = v_fomObjectId
               and fa.COL_STORAGETYPE = 'SIMPLE';
    exception when no_data_found then
        v_xmlResult := NULL;
    end;
    
    if(v_xmlResult is not null) then
        v_result := dbms_xmlgen.CONVERT(v_xmlResult.getClobVal());
    end if;
    
    return v_result;
end;