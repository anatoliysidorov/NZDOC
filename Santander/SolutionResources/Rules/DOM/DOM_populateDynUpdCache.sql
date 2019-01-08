declare
            v_input nclob;
            v_rootobjectid Integer;
            v_CaseExtId Integer;
            v_ConfigId Integer;
            v_objectname nvarchar2(255);
            v_objectname2 nvarchar2(255);
            v_prevobjectname nvarchar2(255);
            v_childobjectname nvarchar2(255);
            v_childtablename nvarchar2(255);
            v_parentobject nvarchar2(255);
            v_parentobject2 nvarchar2(255);
            v_parentobjtablename nvarchar2(255);
            v_parentobjtablename2 nvarchar2(255);
            v_mapobjectname nvarchar2(255);
            v_mapobjectname2 nvarchar2(255);
            v_childmapobjectname nvarchar2(255);
            v_tablename nvarchar2(255);
            v_tablename2 nvarchar2(255);
            v_formname nvarchar2(255);
            v_attributename nvarchar2(255);
            v_attributename2 nvarchar2(255);
            v_attributemapname nvarchar2(255);
            v_attributemapname2 nvarchar2(255);
            v_childattributename nvarchar2(255);
            v_childattributemapname nvarchar2(255);
            v_columnname nvarchar2(255);
            v_columnname2 nvarchar2(255);
            v_columnvalue nvarchar2(32000);
            v_childcolumnname nvarchar2(255);
            v_childcolumnvalue nvarchar2(255);
            v_foreignkeyname nvarchar2(255);
            v_foreignkeyname2 nvarchar2(255);
            v_childforeignkeyname nvarchar2(255);
            v_fcount Integer;
            v_attrcount Integer;
            v_rootattrcount Integer;
            v_recordcount Integer;
            v_childattrcount Integer;
            v_childobjectcount Integer;
            v_startrecordid Integer;
            v_query1 varchar2(32767);
            v_query2 varchar2(32767);
            v_query varchar2(32767);
            v_sqlrecordid varchar2(255);
            v_recordid Integer;
            v_parentrecordid Integer;
            ErrorCode number;
            ErrorMessage nvarchar2(255);
            v_rootobjectname nvarchar2(255);
            v_roottablename nvarchar2(255);
            v_seqnumber nvarchar2(255);
            v_session nvarchar2(255);
            v_sorder Integer;
            v_parentid Integer;
            v_insertparentid Integer;
            v_isdeleted number;
            v_isadded number;
            v_rownum Integer;
            v_result nvarchar2(255);
            v_exit number;
            v_isreference number;
            v_path nvarchar2(255);
            v_rowvalue nvarchar2(4000);
            v_tagpath nvarchar2(255);
            v_tagvalue nvarchar2(32000);
            v_itemid Integer;
            v_parentitemid Integer;
            v_cacherecordid Integer;
            v_parentcacherecordid Integer;
        begin
            v_input := :Input;
            v_session := sys_guid();
            v_rootObjectId := :RootObjectId;
            v_ConfigId := :ConfigId;
            if v_ConfigId is null then
                v_ConfigId := 1;
            end if;
            v_sorder := 0;
            if v_rootObjectId is null then
                v_rootObjectId := 1;
            end if;
            v_rootObjectName := :RootObjectName;
            if v_rootObjectName is null then
                v_rootObjectName := 'CASE';
            end if;
            delete
            from   tbl_dom_cache
            where  col_dom_cachedom_config = v_ConfigId
                   and col_sqltype in('UPDATE',
                                      'DELETE',
                                      'INSERT',
                                      'SEQUENCE');
            
            v_prevobjectname := 'NO_DATA_FOUND';
            -----------------------------------------------------------------------------------------------------------------------------------------------------------------
            --Arrange business objects for update in hierarchical order (starting from CASE business object as ROOT business object down to all other child business objects)
            -----------------------------------------------------------------------------------------------------------------------------------------------------------------
            for rec2 in(with s2 as
                              (select   dua.col_code as UpdateAttrCode,
                                        dua.col_mappingname as UpdateAttrMappingName,
                                        dua.col_dorder as UpdateOrder,
                                        fp.PathId as PathId,
                                        dua.col_dom_updateattrfom_path as ObjAttrPath,
                                        fo.col_code as ObjCode,
                                        fo.col_name as ObjName,
                                        fo.col_tablename as ObjTableName,
                                        fr.col_code as RelCode,
                                        fr.col_foreignkeyname as RelForeignKeyName,
                                        cfo.col_id as ChildObjId,
                                        cfo.col_code as ChildObj,
                                        cfo.col_name as ChildObjName,
                                        cfo.col_tablename as ChildObjTableName,
                                        pfo.col_id as ParentObjId,
                                        pfo.col_code as ParentObj,
                                        pfo.col_name as ParentObjName,
                                        pfo.col_tablename as ParentObjTableName,
                                        fa.col_id as AttrId,
                                        fa.col_code as AttrCode,
                                        fa.col_name as AttrName,
                                        fa.col_columnname as AttrColumnName,
                                        dt.col_code as DataTypeCode,
                                        rfo.col_code as RootObjCode,
                                        rfo.col_name as RootObjName,
                                        rfo.col_tablename as RootObjTableName,
                                        case
                                                  when fo.col_code = rfo.col_code then 1 else 0
                                        end as IsRootObject
                              from     (select  col_id as PathId,
                                                 col_fom_pathfom_relationship,
                                                 col_fom_pathfom_path,
                                                 col_code,
                                                 col_name,
                                                 col_jointype
                                        from     tbl_fom_path
                                                 connect by prior col_id = col_fom_pathfom_path
                                                 start with col_id in(select col_dom_updateattrfom_path
                                                 from    tbl_dom_updateattr
                                                 where   col_dom_updateattrdom_config = v_ConfigId)
                                        group by col_id,col_fom_pathfom_relationship,col_fom_pathfom_path,col_code,col_name,col_jointype) fp
                              left join tbl_fom_relationship fr on fp.col_fom_pathfom_relationship = fr.col_id
                              left join tbl_fom_object cfo      on fr.col_childfom_relfom_object = cfo.col_id
                              left join tbl_fom_object pfo      on fr.col_parentfom_relfom_object = pfo.col_id
                              left join tbl_dom_updateattr dua  on fp.pathid = dua.col_dom_updateattrfom_path and col_dom_updateattrdom_config = v_ConfigId
                              left join tbl_fom_attribute fa    on dua.col_dom_updateattrfom_attr = fa.col_id
                              left join tbl_fom_object fo       on fa.col_fom_attributefom_object = fo.col_id
                              left join tbl_dom_config dc       on dua.col_dom_updateattrdom_config = dc.col_id
                              left join tbl_fom_object rfo      on dc.col_dom_configfom_object = rfo.col_id
                              left join tbl_dict_datatype dt    on dt.col_id = fa.col_fom_attributedatatype
                              )
                        select   UpdateAttrCode,
                                 UpdateAttrMappingName,
                                 UpdateOrder,
                                 AttrId,
                                 AttrCode,
                                 AttrName,
                                 AttrColumnName,
                                 DataTypeCode,
                                 PathId as PathId,
                                 ObjAttrPath,
                                 ObjCode,
                                 ObjName,
                                 ObjTableName,
                                 RelCode,
                                 RelForeignKeyName,
                                 RootObjCode,
                                 RootObjName,
                                 RootObjTableName,
                                 IsRootObject,
                                 ChildObjId,
                                 ChildObj,
                                 ChildObjName,
                                 ChildObjTableName,
                                 ParentObjId,
                                 ParentObj,
                                 ParentObjName,
                                 ParentObjTableName
                        from     s2
                        order by ChildObjId,UpdateOrder)
            loop
				 
                v_objectname2 := rec2.ChildObj;
                v_tablename2 := rec2.ChildObjTableName;
                v_mapobjectname2 := rec2.ChildObjName;
                v_parentobject2 := rec2.ParentObj;
                v_parentobjtablename2 := rec2.ParentObjTableName;
                v_foreignkeyname2 := rec2.RelForeignKeyName;
                v_attributename2 := rec2.AttrName;
                v_attributemapname2 := rec2.UpdateAttrMappingName;
                v_columnname2 := rec2.AttrColumnName;
                if v_tablename = v_tablename2 then
                    continue;
                end if;
				
                v_recordcount := 1;
				
                while(true)
                loop
                    v_attrcount := 1;
                    for rec in(with s2 as
                                     (select   dua.col_code as UpdateAttrCode,
                                               dua.col_mappingname as UpdateAttrMappingName,
                                               dua.col_dorder as UpdateOrder,
                                               fp.PathId as PathId,
                                               dua.col_dom_updateattrfom_path as ObjAttrPath,
                                               fo.col_code as ObjCode,
                                               fo.col_name as ObjName,
                                               fo.col_tablename as ObjTableName,
                                               fr.col_code as RelCode,
                                               fr.col_foreignkeyname as RelForeignKeyName,
                                               cfo.col_id as ChildObjId,
                                               cfo.col_code as ChildObj,
                                               cfo.col_name as ChildObjName,
                                               cfo.col_tablename as ChildObjTableName,
                                               pfo.col_id as ParentObjId,
                                               pfo.col_code as ParentObj,
                                               pfo.col_name as ParentObjName,
                                               pfo.col_tablename as ParentObjTableName,
                                               fa.col_id as AttrId,
                                               fa.col_code as AttrCode,
                                               fa.col_name as AttrName,
                                               fa.col_columnname as AttrColumnName,
                                               dt.col_code as DataTypeCode,
                                               rfo.col_code as RootObjCode,
                                               rfo.col_name as RootObjName,
                                               rfo.col_tablename as RootObjTableName,
                                               case
                                                         when fo.col_code = rfo.col_code then 1 else 0
                                               end as IsRootObject
                                     from     (select  col_id as PathId,
                                                        col_fom_pathfom_relationship,
                                                        col_fom_pathfom_path,
                                                        col_code,
                                                        col_name,
                                                        col_jointype
                                               from     tbl_fom_path
                                                        connect by prior col_id = col_fom_pathfom_path
                                                        start with col_id in(select col_dom_updateattrfom_path
                                                        from    tbl_dom_updateattr
                                                        where   col_dom_updateattrdom_config = v_ConfigId)
                                               group by col_id,col_fom_pathfom_relationship,col_fom_pathfom_path,col_code,col_name,col_jointype) fp
                                     left join tbl_fom_relationship fr on fp.col_fom_pathfom_relationship = fr.col_id
                                     left join tbl_fom_object cfo      on fr.col_childfom_relfom_object = cfo.col_id
                                     left join tbl_fom_object pfo      on fr.col_parentfom_relfom_object = pfo.col_id
                                     left join tbl_dom_updateattr dua  on fp.pathid = dua.col_dom_updateattrfom_path and col_dom_updateattrdom_config = v_ConfigId
                                     left join tbl_fom_attribute fa    on dua.col_dom_updateattrfom_attr = fa.col_id
                                     left join tbl_fom_object fo       on fa.col_fom_attributefom_object = fo.col_id
                                     left join tbl_dom_config dc       on dua.col_dom_updateattrdom_config = dc.col_id
                                     left join tbl_fom_object rfo      on dc.col_dom_configfom_object = rfo.col_id
                                     left join tbl_dict_datatype dt    on dt.col_id = fa.col_fom_attributedatatype
                                     )
                               select   UpdateAttrCode,
                                        UpdateAttrMappingName,
                                        UpdateOrder,
                                        AttrId,
                                        AttrCode,
                                        AttrName,
                                        AttrColumnName,
                                        DataTypeCode,
                                        PathId as PathId,
                                        ObjAttrPath,
                                        ObjCode,
                                        ObjName,
                                        ObjTableName,
                                        RelCode,
                                        RelForeignKeyName,
                                        RootObjCode,
                                        RootObjName,
                                        RootObjTableName,
                                        IsRootObject,
                                        ChildObjId,
                                        ChildObj,
                                        ChildObjName,
                                        ChildObjTableName,
                                        ParentObjId,
                                        ParentObj,
                                        ParentObjName,
                                        ParentObjTableName
                               from     s2
                               where    ChildObjId = rec2.ChildObjId
                               order by ChildObjId,UpdateOrder)
                    loop
					
                        -- skip variables
                        if(rec.AttrColumnName in('col_createdby','col_createddate','col_modifiedby','col_modifieddate')) then
                            continue;
                        end if;
	
						
                        v_objectname := rec.ChildObj;
                        v_tablename := rec.ChildObjTableName;
                        v_mapobjectname := rec.ChildObjName;
                        v_parentobject := rec.ParentObj;
                        v_parentobjtablename := rec.ParentObjTableName;
                        v_foreignkeyname := rec.RelForeignKeyName;
                        v_attributename := rec.AttrName;
                        v_attributemapname := rec.UpdateAttrMappingName;
                        v_columnname := rec.AttrColumnName;
                   
                        if v_parentobject <> v_parentobject2 and v_foreignkeyname is not null then
                            v_isreference := 1;
                            v_columnname := rec.RelForeignKeyName;
                        else
                            v_isreference := 0;
                        end if;
						
                        --Check if record[recordcount] exists
                        v_path := '/CustomData/Attributes/Object[@ObjectCode="' || v_objectname || '"]/Item[' || to_char(v_recordcount) || ']';
                        v_rowvalue := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                                                               Path => v_path);
                        if v_rowvalue is null then
                            v_exit := 1;
                            exit;
                        end if;
                        v_path := '/CustomData/Attributes/Object[@ObjectCode="' || v_objectname || '"]/Item[' || to_char(v_recordcount) || ']/' || 'IS_DELETED' || '/text()';
                        v_result := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                                                             Path => v_path);
                        v_isdeleted := null;
                        if v_result is not null then
                            v_isdeleted := to_number(v_result);
                        end if;
                        v_path := '/CustomData/Attributes/Object[@ObjectCode="' || v_objectname || '"]/Item[' || to_char(v_recordcount) || ']/' || 'IS_ADDED' || '/text()';
                        v_result := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                                                             Path => v_path);
                        v_isadded := null;
                        if v_result is not null then
                            v_isadded := to_number(v_result);
                        end if;
                        v_path := '/CustomData/Attributes/Object[@ObjectCode="' || v_objectname || '"]/Item[' || to_char(v_recordcount) || ']/' || 'ID' || '/text()';
                        v_result := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                                                             Path => v_path);
                        v_recordid := null;
                        if v_result is not null then
                            v_recordid := to_number(v_result);
                        end if;
                        if v_recordid < 0 then
                            v_isadded := 1;
                        end if;
                        v_path := '/CustomData/Attributes/Object[@ObjectCode="' || v_objectname || '"]/Item[' || to_char(v_recordcount) || ']/' || 'PID' || '/text()';
                        v_result := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                                                             Path => v_path);
                        v_parentrecordid := null;
                        if v_result is not null then
                            v_parentrecordid := to_number(v_result);
                        end if;
                        v_tagpath := '/CustomData/Attributes/Object[@ObjectCode="' || v_objectname || '"]/Item[' || to_char(v_recordcount) || ']/' || v_attributemapname;
                        v_tagvalue := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                                                               Path => v_tagpath);
                        if v_tagvalue is null then
                            continue;
                        end if;
                        v_path := '/CustomData/Attributes/Object[@ObjectCode="' || v_objectname || '"]/Item[' || to_char(v_recordcount) || ']/' || v_attributemapname || '/text()';
                        v_columnvalue := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                                                                  Path => v_path);
                        if v_isreference = 1 then
                            v_query1 := 'select col_id from ' || v_parentobjtablename || ' where lower(' || rec.AttrColumnName || ') = ''' || lower(v_columnvalue) || '''';
                            begin
                                execute immediate v_query1 into v_columnvalue;
                            exception
                            when NO_DATA_FOUND then
                                v_columnvalue := 'null';
                            when TOO_MANY_ROWS then
                                v_columnvalue := 'null';
                            end;
                        end if;
                        -----------------------------------------------------
                        --Get value of current parameter from INPUT value XML
                        -----------------------------------------------------
                        if nvl(v_isadded,0) = 1 then
                            if v_attrcount = 1 then
                                v_query := v_query || v_columnName;
                                if v_isreference = 1 then
                                    v_query2 := v_query2 || v_columnvalue;
                                else
                                    if v_columnvalue is not null then
                                        v_query2 := v_query2 || '''' || v_columnvalue || '''';
                                    else
                                        v_query2 := v_query2 || 'null';
                                    end if;
                                end if;
                            else
                                v_query := v_query || ', ' || v_columnName;
                                if v_isreference = 1 then
                                    v_query2 := v_query2 || ', ' || v_columnvalue;
                                else
                                    if v_columnvalue is not null then
                                        v_query2 := v_query2 || ', ' || '''' || v_columnvalue || '''';
                                    else
                                        v_query2 := v_query2 || ', ' || 'null';
                                    end if;
                                end if;
                            end if;
                        else
                            if v_attrcount = 1 then
                                if v_isreference = 1 then
                                    v_query := v_query || v_columnName || ' = ' || v_columnValue;
                                else
                                    if v_columnValue is not null then
                                        v_query := v_query || v_columnName || ' = ' || '''' || v_columnValue || '''';
                                    else
                                        v_query := v_query || v_columnName || ' = ' || 'null';
                                    end if;
                                end if;
                            else
                                if v_isreference = 1 then
                                    v_query := v_query || ', ' || v_columnName || ' = ' || v_columnValue;
                                else
                                    if v_columnValue is not null then
                                        v_query := v_query || ', ' || v_columnName || ' = ' || '''' || v_columnValue || '''';
                                    else
                                        v_query := v_query || ', ' || v_columnName || ' = ' || 'null';
                                    end if;
                                end if;
                            end if;
                        end if;
                        v_attrcount := v_attrcount + 1;
                    end loop;
                    if v_exit = 1 then
                        v_exit := 0;
                        exit;
                    end if;
                    v_path := '/CustomData/Attributes/Object[@ObjectCode="' || v_objectname || '"]/Item[' || to_char(v_recordcount) || ']/' || 'SEQ_NUMBER' || '/text()';
                    v_seqnumber := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                                                            Path => v_path);
                    if v_seqnumber is null then
                        v_seqnumber := 1;
                    end if;
                    v_path := '/CustomData/Attributes/Object[@ObjectCode="' || v_objectname2 || '"]/Item[' || to_char(v_recordcount) || ']/' || 'ID' || '/text()';
                    v_itemid := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                                                         Path => v_path);
                    v_path := '/CustomData/Attributes/Object[@ObjectCode="' || v_objectname2 || '"]/Item[' || to_char(v_recordcount) || ']/' || 'PARENTID' || '/text()';
                    v_parentitemid := f_UTIL_extract_value_xml(Input => xmltype(v_input),
                                                               Path => v_path);
                    begin
                        select s1.ParentId,
                               s1.RowNumber
                        into   v_parentid,
                               v_rownum
                        from  (select  col_id as ParentId,
                                        row_number() over(order by col_id) as RowNumber
                               from     tbl_dom_cache
                               where    col_childobject = v_parentobject2
                                        and col_sqltype in('UPDATE'/*, 'INSERT'*/)) s1
                        where  s1.RowNumber = to_number(v_seqnumber);
                    
                    exception
                    when NO_DATA_FOUND then
                        v_parentid := null;
                    end;
                    
					begin
                        select s1.ParentId,
                               s1.RowNumber
                        into   v_insertparentid,
                               v_rownum
                        from  (select  col_id as ParentId,
                                        row_number() over(order by col_id) as RowNumber
                               from     tbl_dom_cache
                               where    col_childobject = v_parentobject2
                                        and col_sqltype in('UPDATE',
                                                           'INSERT')) s1
                        where  s1.RowNumber = to_number(v_seqnumber);
                    
                    exception
                    when NO_DATA_FOUND then
                        v_parentid := null;
                    end;
					
                    if nvl(v_isadded,0) <> 1 then
						
						--MAX FIX FOR BJB------------
						IF TRIM(rec2.ChildObjTableName) IS NULL THEN
							v_exit := 1;
							exit;
						END IF;
						-----------------------------		
					
					
                        v_query := 'update ' || rec2.ChildObjTableName || ' set ' || v_query || ' where col_id = ' || v_recordid;
                        v_sorder := v_sorder + 1;
                        --Insert records to the table TBL_DOM_CACHE for business object UPDATE statement
                        insert into tbl_dom_cache(col_query,
                                      col_objectname,
                                      col_objecttablename,
                                      col_childobject,
                                      col_childobjectname,
                                      col_childobjecttablename,
                                      col_parentobject,
                                      col_parentobjectname,
                                      col_parentobjecttablename,
                                      col_itemid,
                                      col_parentitemid,
                                      col_sqltype,
                                      col_recordid,
                                      col_parentrecordid,
                                      col_session,
                                      col_sorder,
                                      col_parentseqnumber,
                                      col_isadded,
                                      col_isdeleted,
                                      col_dom_cachedom_config)
                               values(v_query,
                                      v_objectname,
                                      v_tablename,
                                      rec2.ChildObj,
                                      rec2.ChildObjName,
                                      rec2.ChildObjTableName,
                                      rec2.ParentObj,
                                      rec2.ParentObjName,
                                      rec2.ParentObjTableName,
                                      v_itemid,
                                      v_parentitemid,
                                      'UPDATE',
                                      v_seqnumber,
                                      v_recordid,
                                      v_session,
                                      v_sorder,
                                      v_parentid,
                                      v_isadded,
                                      v_isdeleted,
                                      v_ConfigId);
                        
                        v_query := null;
                        v_query2 := null;
                        v_sqlrecordid := null;
                    else
						--MAX FIX FOR BJB------------
						IF TRIM(rec2.ChildObjTableName) IS NULL THEN
							v_exit := 1;
							exit;
						END IF;
						-----------------------------	
						
                        if v_query is null then
                            v_query := 'insert into ' || rec2.ChildObjTableName || '(' || v_foreignkeyname2 || ')';
                        else
                            v_query := 'insert into ' || rec2.ChildObjTableName || '(' || v_foreignkeyname2 || ', ' || v_query || ')';
                        end if;
						
						
                        if rec2.ParentObj = v_rootObjectName then
                            if v_query2 is null then
                                v_query2 := ' values ' || '(' || to_char(v_rootObjectId) || ')';
                            else
                                v_query2 := ' values ' || '(' || to_char(v_rootObjectId) || ', ' || v_query2 || ')';
                            end if;
                        else
                            if v_query2 is null then
                                v_query2 := ' values ' || '(' || '@' || 'ParentObjectId' || '@' || ')';
                            else
                                v_query2 := ' values ' || '(' || '@' || 'ParentObjectId' || '@' || ', ' || v_query2 || ')';
                            end if;
                        end if;
                        v_query := v_query || v_query2;
                        v_sorder := v_sorder + 1;
                        --Insert records to the table TBL_DOM_CACHE for business object INSERT statement and for SELECT current sequence number statement
                        insert into tbl_dom_cache(col_query,
                                      col_objectname,
                                      col_objecttablename,
                                      col_childobject,
                                      col_childobjectname,
                                      col_childobjecttablename,
                                      col_parentobject,
                                      col_parentobjectname,
                                      col_parentobjecttablename,
                                      col_itemid,
                                      col_parentitemid,
                                      col_sqltype,
                                      col_recordid,
                                      col_parentrecordid,
                                      col_session,
                                      col_sorder,
                                      col_parentseqnumber,
                                      col_dom_cachedom_config)
                               values(v_query,
                                      v_objectname,
                                      v_tablename,
                                      rec2.ChildObj,
                                      rec2.ChildObjName,
                                      rec2.ChildObjTableName,
                                      rec2.ParentObj,
                                      rec2.ParentObjName,
                                      rec2.ParentObjTableName,
                                      v_itemid,
                                      v_parentitemid,
                                      'INSERT',
                                      v_seqnumber,
                                      v_parentrecordid,
                                      v_session,
                                      v_sorder,
                                      v_insertparentid,
                                      v_ConfigId);
                        
                        select gen_tbl_dom_cache.currval
                        into   v_cacherecordid
                        from   dual;
                        
                        v_sqlrecordid := 'select gen_' || v_tablename || '.currval from dual';
                        v_sorder := v_sorder + 1;
                        insert into tbl_dom_cache(col_query,
                                      col_objectname,
                                      col_objecttablename,
                                      col_childobject,
                                      col_childobjectname,
                                      col_childobjecttablename,
                                      col_parentobject,
                                      col_parentobjectname,
                                      col_parentobjecttablename,
                                      col_sqltype,
                                      col_recordid,
                                      col_session,
                                      col_sorder,
                                      col_dom_cachedom_config)
                               values(v_sqlrecordid,
                                      v_objectname,
                                      v_tablename,
                                      rec2.ChildObj,
                                      rec2.ChildObjName,
                                      rec2.ChildObjTableName,
                                      rec2.ParentObj,
                                      rec2.ParentObjName,
                                      rec2.ParentObjTableName,
                                      'SEQUENCE',
                                      v_seqnumber,
                                      v_session,
                                      v_sorder,
                                      v_ConfigId);
                        
                        if v_itemid is not null and v_parentitemid is not null then
                            begin
                                select col_id
                                into   v_parentcacherecordid
                                from   tbl_dom_cache
                                where  col_itemid = v_parentitemid
                                       and col_objectname = rec2.ParentObj;
                            
                            exception
                            when NO_DATA_FOUND then
                                v_parentcacherecordid := null;
                            when TOO_MANY_ROWS then
                                v_parentcacherecordid := null;
                            end;
                            if v_parentcacherecordid is not null then
                                update tbl_dom_cache
                                set    col_parentseqnumber = v_parentcacherecordid
                                where  col_id = v_cacherecordid;
                            
                            end if;
                        end if;
                        v_query := null;
                        v_query2 := null;
                        v_sqlrecordid := null;
                    end if;
                    v_recordcount := v_recordcount + 1;
                end loop;
            end loop;
            --Find and mark records to be deleted
            for rec in(select s1.ID,
                    s1.ItemId,
                    s1.ParentItemId,
                    s1.IsDeleted,
                    s1.ParentSeqNumber,
                    s1.ObjectTableName,
                    s1.Query
            from   (select col_id as ID,
                            col_itemid as ItemId,
                            col_parentitemid as ParentItemId,
                            col_isdeleted as IsDeleted,
                            col_parentseqnumber as ParentSeqNumber,
                            col_objecttablename as ObjectTableName,
                            col_query as Query
                    from    tbl_dom_cache
                    where   col_dom_cachedom_config = v_ConfigId
                            and col_sqltype = 'UPDATE') s1
                    connect by nocycle s1.ParentItemId = prior s1.ItemId /*s1.ParentSeqNumber = prior s1.ID*/
                    start with s1.IsDeleted = 1)
            loop
                v_query := 'delete from ' || rec.ObjectTableName || ' ' || substr(rec.Query,instr(rec.Query,'where'));
                update tbl_dom_cache
                set    col_isdeleted = 1,
                       col_sqltype = 'DELETE',
                       col_query = v_query
                where  col_id = rec.ID;
            
            end loop;
            :Session := v_session;
            return null;
        end;