declare
    v_input   nclob;
    v_modelId number;
    v_tmp_objectTypeCode nvarchar2(255);
    v_count number;
    v_isModelValid number;
    v_errorMessage nvarchar2(4000);
    v_dbName       nvarchar2(255);
    v_seqName      nvarchar2(255);
    v_tmp_objectType nvarchar2(255);
    v_errorXMLData  varchar2(32767);
    v_tmp_apiCode nvarchar2(255);

begin
    v_input := :InputXML;
    v_modelId := :ModelId;
    v_isModelValid := 1;
    v_errorXMLData := ''; 
    v_errorXMLData := '<Parameters>';
    
    for rec in (select s.TypeName AS TypeName,
                     s.ActionName AS ActionName,
                     s.DataBaseName AS DataBaseName,
                     s.Code as Code,
                     s.FullData as FullData
                from (select d.extract('Item/Parameter[@name="TypeName"]/@value').getStringVal() AS TypeName,
                             d.extract('Item/Parameter[@name="ActionName"]/@value').getStringVal() AS ActionName,
                             d.extract('Item/Parameter[@name="DataBaseName"]/@value').getStringVal() AS DataBaseName,
                             d.extract('Item/Parameter[@name="Code"]/@value').getStringVal() AS Code,
                             d.extract('Item/FullData').getStringVal() as FullData
                        from table(XMLSequence(extract(XMLType(v_input),'/Parameters/Item'))) d) s
               where s.ActionName = 'CREATE')
    loop
        v_errorMessage := '';       
        if rec.TypeName = 'OBJECT' then
            v_tmp_objectTypeCode := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                               Path  => 'FullData/Parameter[@name="TypeCode"]/@value');

            if(v_tmp_objectTypeCode not in ('parentBusinessObject', 'referenceObject')) then
                -- That a business object with the same Code doesn't already exist
                select count (*) into v_count
                from tbl_fom_object  fo
                inner join tbl_dom_object dobj on fo.col_id = dobj.col_dom_objectfom_object
                inner join tbl_dom_model dm on dm.col_id = dobj.col_dom_objectdom_model
                where upper (fo.col_code) = upper (rec.Code);

                if v_count > 0 then
                    v_errorMessage := 'Business Object with code ' || rec.Code|| ' already exist';
                    v_isModelValid := 0;
                end if;

                -- check on trigger name
                if(length(rec.DataBaseName) > 25) then
                    v_dbName := substr(rec.DataBaseName, 0, 25);
                        
                    select count(*)
                    into v_count
                    from all_triggers
                    where upper(trigger_name) like '%' || upper(v_dbname) || '%'
                    and upper(owner) =  (select upper(value) from config where name = 'ENV_SCHEMA');
                    
                    if v_count > 0 then
                        if(v_errorMessage is not null) then
                            v_errorMessage := v_errorMessage || '<br>';
                        end if;
                        v_errorMessage := v_errorMessage ||  'Trigger with code ' || v_dbName || ' already exist';
                        v_isModelValid := 0;
                    end if;                      
                end if;

                -- check on sequence name
                if (length(rec.DataBaseName) > 24) then
                    v_seqname := substr(rec.DataBaseName, 5, 20);

                    select count(*) into v_count 
                    from user_sequences
                    where upper(sequence_name) like '%' || upper(v_seqname) || '%';
                    
                    if v_count > 0 then
                        if(v_errorMessage is not null) then
                            v_errorMessage := v_errorMessage || '<br>';
                        end if;
                        v_errormessage := v_errorMessage || 'Sequence with code ' || v_seqname || ' already exist';
                        v_ismodelvalid := 0;
                    end if;
                end if;
            end if;

        elsif rec.TypeName = 'RELATIONSHIP' then
          select count(*)
            into v_count
            from tbl_fom_relationship rh
          where upper(rh.col_code) = upper(rec.Code)
            and rh.col_childfom_relfom_object not in (select fo.col_id
                                                        from tbl_fom_object fo
                                                        inner join tbl_dom_object dob
                                                          on fo.col_id = dob.col_dom_objectfom_object
                                                        inner join tbl_dom_model dm
                                                          on dm.col_id = dob.col_dom_objectdom_model
                                                        where dm.col_dom_modelmdm_model = v_modelId)
            and rh.col_parentfom_relfom_object not in (select fo.col_id
                                                          from tbl_fom_object fo
                                                        inner join tbl_dom_object dob
                                                            on fo.col_id = dob.col_dom_objectfom_object
                                                        inner join tbl_dom_model dm
                                                            on dm.col_id = dob.col_dom_objectdom_model
                                                        where dm.col_dom_modelmdm_model = v_modelId);
                
            if v_count > 0 THEN
                v_errorMessage := 'Relationship with code ' || rec.Code|| ' already exist';
                v_isModelValid := 0;
            end if;
        end if;

        if(v_errorMessage is not null) then
          v_tmp_apiCode    := f_UTIL_extract_value_xml(Input => xmltype(rec.FullData),
                                                   Path  => 'FullData/Parameter[@name="AppbaseCode"]/@value');

          v_errorXMLData := v_errorXMLData || '<Parameter>';
          v_errorXMLData := v_errorXMLData || '<ErrorMessage>' || v_errorMessage || '</ErrorMessage>';
          v_errorXMLData := v_errorXMLData || '<ErrorCode>1</ErrorCode>';
          v_errorXMLData := v_errorXMLData || '<Type>' || lower(rec.TypeName) || '</Type>';
          v_errorXMLData := v_errorXMLData || '<AppbaseCode>' || v_tmp_apiCode || '</AppbaseCode>';
          v_errorXMLData := v_errorXMLData || '</Parameter>';
        end if;
        --dbms_output.put_line('Type: ' || rec.TypeName || '| Code: ' || rec.Code);
        --dbms_output.put_line('Error message ' || v_errorMessage);
    end loop;
    
    v_errorXMLData := v_errorXMLData || '</Parameters>';
    :IS_MODEL_VALID := v_isModelValid;
    :ErrorXMLData := dbms_xmlgen.CONVERT(v_errorXMLData);
    
    --dbms_output.put_line('v_errorXMLData ' || v_errorXMLData);
    --dbms_output.put_line('v_isModelValid ' || v_isModelValid);

   <<exit_>>
    null;
end;