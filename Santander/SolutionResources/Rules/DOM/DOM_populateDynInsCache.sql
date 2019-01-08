declare
    v_input nclob;
    v_rootObjectName nvarchar2(255);
    v_rootobjectid Integer;
    v_CaseExtId Integer;
    v_ConfigId Integer;
    v_objectname nvarchar2(255);
    v_objectname2 nvarchar2(255);
    v_parentobject2 nvarchar2(255);
    v_prevobjectname nvarchar2(255);
    v_childobjectname nvarchar2(255);
    v_childtablename nvarchar2(255);
    v_parentobject nvarchar2(255);
    v_parentobjtablename nvarchar2(255);
    v_mapobjectname nvarchar2(255);
    v_mapobjectname2 nvarchar2(255);
    v_prevmapobjectname nvarchar2(255);
    v_childmapobjectname nvarchar2(255);
    v_tablename nvarchar2(255);
    v_tablename2 nvarchar2(255);
    v_parenttablename2 nvarchar2(255);
    v_prevtablename nvarchar2(255);
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
    v_tagvalue nvarchar2(32000);
    v_rowvalue nvarchar2(4000);
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
    v_query1 varchar2(32767);
    v_query2 varchar2(32767);
    v_query varchar2(32767);
    v_sqlrecordid varchar2(255);
    v_recordid Integer;
    v_itemid Integer;
    v_parentitemid Integer;
    ErrorCode number;
    ErrorMessage nvarchar2(255);
    v_roottablename nvarchar2(255);
    v_seqnumber nvarchar2(255);
    v_session nvarchar2(255);
    v_sorder Integer;
    v_parentid Integer;
    v_cacherecordid Integer;
    v_parentcacherecordid Integer;
    v_rownum Integer;
    v_exit number;
    v_isreference number;
    v_path nvarchar2(255);
    v_tagpath nvarchar2(255);
begin
    v_session := sys_guid();
    v_rootObjectId := :RootObjectId;
    v_ConfigId := :ConfigId;
    v_input := :Input;
    v_rootObjectName := :RootObjectName;
    if v_rootObjectName is null then
        v_rootObjectName := 'CASE';
    end if;
    v_sorder := 0;
    delete
    from   tbl_dom_cache
    where  col_dom_cachedom_config = v_ConfigId
           and col_sqltype in('INSERT',
                              'SEQUENCE');
    
    v_prevobjectname := 'NO_DATA_FOUND';
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------
    --Arrange business objects for insert in hierarchical order (starting from CASE business object as ROOT business object down to all other child business objects)
    -----------------------------------------------------------------------------------------------------------------------------------------------------------------
    v_exit := 0;
    v_attrcount := 1;
    for rec2 in(with s2 as
                      (select   dia.col_code as InsertAttrCode,
                                dia.col_mappingname as InsertAttrMappingName,
                                dia.col_dorder as InsertOrder,
                                fp.PathId as PathId,
                                dia.col_dom_insertattrfom_path as ObjAttrPath,
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
                                         start with col_id in(select col_dom_insertattrfom_path
                                         from    tbl_dom_insertattr
                                         where   col_dom_insertattrdom_config = v_ConfigId)
                                group by col_id,col_fom_pathfom_relationship,col_fom_pathfom_path,col_code,col_name,col_jointype) fp
                      left join tbl_fom_relationship fr on fp.col_fom_pathfom_relationship = fr.col_id
                      left join tbl_fom_object cfo      on fr.col_childfom_relfom_object = cfo.col_id
                      left join tbl_fom_object pfo      on fr.col_parentfom_relfom_object = pfo.col_id
                      left join tbl_dom_insertattr dia  on fp.pathid = dia.col_dom_insertattrfom_path and col_dom_insertattrdom_config = v_ConfigId
                      left join tbl_fom_attribute fa    on dia.col_dom_insertattrfom_attr = fa.col_id
                      left join tbl_fom_object fo       on fa.col_fom_attributefom_object = fo.col_id
                      left join tbl_dom_config dc       on dia.col_dom_insertattrdom_config = dc.col_id
                      left join tbl_fom_object rfo      on dc.col_dom_configfom_object = rfo.col_id
                      left join tbl_dict_datatype dt    on dt.col_id = fa.col_fom_attributedatatype
                      )
                select   InsertAttrCode,
                         InsertAttrMappingName,
                         InsertOrder,
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
                order by ChildObjId,InsertOrder)
    loop
        v_objectname2 := rec2.ChildObj;
        v_tablename2 := rec2.ChildObjTableName;
        v_parentobject2 := rec2.ParentObj;
        v_parenttablename2 := rec2.ParentObjTableName;
        v_mapobjectname2 := rec2.ChildObjName;
        v_foreignkeyname2 := rec2.RelForeignKeyName;
        v_attributename2 := rec2.AttrName;
        v_attributemapname2 := rec2.InsertAttrMappingName;
        v_columnname2 := rec2.AttrColumnName;
        if v_tablename = v_tablename2 
		--ADDED BY MAX FOR BJB FIX--		
		OR trim(rec2.ChildObjTableName) IS NULL then
		----------------------------
        
			continue;
        end if;
        if v_query is null then
            v_query := 'insert into ' || rec2.ChildObjTableName || '(' || v_foreignkeyname2 || ', ';
            if rec2.ParentObj = v_rootObjectName then
                v_query2 := ' values ' || '(' || to_char(v_rootObjectId) || ', ';
            else
                v_query2 := ' values ' || '(' || '@' || 'ParentObjectId' || '@' || ', ';
            end if;
        end if;
        -----------------------------------------------------
        --Get value of current parameter from INPUT value XML
        -----------------------------------------------------
        v_recordcount := 1;
        while(true)
        loop
            v_attrcount := 1;
            for rec in(with s2 as
                             (select   dia.col_code as InsertAttrCode,
                                       dia.col_mappingname as InsertAttrMappingName,
                                       dia.col_dorder as InsertOrder,
                                       fp.PathId as PathId,
                                       dia.col_dom_insertattrfom_path as ObjAttrPath,
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
                                                start with col_id in(select col_dom_insertattrfom_path
                                                from    tbl_dom_insertattr
                                                where   col_dom_insertattrdom_config = v_ConfigId)
                                       group by col_id,col_fom_pathfom_relationship,col_fom_pathfom_path,col_code,col_name,col_jointype) fp
                             left join tbl_fom_relationship fr on fp.col_fom_pathfom_relationship = fr.col_id
                             left join tbl_fom_object cfo      on fr.col_childfom_relfom_object = cfo.col_id
                             left join tbl_fom_object pfo      on fr.col_parentfom_relfom_object = pfo.col_id
                             left join tbl_dom_insertattr dia  on fp.pathid = dia.col_dom_insertattrfom_path and col_dom_insertattrdom_config = v_ConfigId
                             left join tbl_fom_attribute fa    on dia.col_dom_insertattrfom_attr = fa.col_id
                             left join tbl_fom_object fo       on fa.col_fom_attributefom_object = fo.col_id
                             left join tbl_dom_config dc       on dia.col_dom_insertattrdom_config = dc.col_id
                             left join tbl_fom_object rfo      on dc.col_dom_configfom_object = rfo.col_id
                             left join tbl_dict_datatype dt    on dt.col_id = fa.col_fom_attributedatatype
                             )
                       select   InsertAttrCode,
                                InsertAttrMappingName,
                                InsertOrder,
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
                       order by ChildObjId,InsertOrder)
            loop
                v_objectname := rec.ChildObj;
                v_tablename := rec.ChildObjTableName;
                v_mapobjectname := rec.ChildObjName;
                v_parentobject := rec.ParentObj;
                v_parentobjtablename := rec.ParentObjTableName;
                v_foreignkeyname := rec.RelForeignKeyName;
                v_attributename := rec.AttrName;
                v_attributemapname := rec.InsertAttrMappingName;
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
                v_attrcount := v_attrcount + 1;
            end loop;
            if v_exit = 1 then
                v_exit := 0;
                exit;
            end if;
            v_query := rtrim(v_query,', ');
            v_query2 := rtrim(v_query2,', ');
            v_query := v_query || ')';
            v_query2 := v_query2 || ')';
            v_query := v_query || v_query2;
            v_sqlrecordid := 'select gen_' || v_tablename || '.currval from dual';
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
                       where    col_childobject = v_parentobject
                                and col_sqltype = 'INSERT') s1
                where  s1.RowNumber = to_number(v_seqnumber);
            
            exception
            when NO_DATA_FOUND then
                v_parentid := null;
            end;
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
                          col_session,
                          col_sorder,
                          col_parentseqnumber,
                          col_dom_cachedom_config)
                   values(v_query,
                          v_objectname2,
                          v_tablename2,
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
                          v_session,
                          v_sorder,
                          v_parentid,
                          v_ConfigId);
            
            select gen_tbl_dom_cache.currval
            into   v_cacherecordid
            from   dual;
            
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
                          v_objectname2,
                          v_tablename2,
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
			
			--ADDED BY MAX FOR BJB FIX--
			IF TRIM(rec2.ChildObjTableName) IS NULL THEN
				exit;
			END IF;
			-----------------------------
			
            v_query := 'insert into ' || rec2.ChildObjTableName || '(' || v_foreignkeyname2 || ', ';
            if rec2.ParentObj = v_rootObjectName then
                v_query2 := ' values ' || '(' || to_char(v_rootObjectId) || ', ';
            else
                v_query2 := ' values ' || '(' || '@' || 'ParentObjectId' || '@' || ', ';
            end if;
            v_prevtablename := v_tablename2;
            v_prevmapobjectname := v_mapobjectname2;
            v_recordcount := v_recordcount + 1;
            -----------------------------------------------
            --Select attributes for current business object
            -----------------------------------------------
        end loop;
        v_query := null;
        v_query2 := null;
    end loop;
    :Session := v_session;
    return 0;
end;