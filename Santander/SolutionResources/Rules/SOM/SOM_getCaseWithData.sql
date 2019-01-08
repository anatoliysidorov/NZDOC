declare
    v_output CLOB;
    v_rootobjectid Integer;
    v_CaseTypeId   Integer;
    v_objectname2 nvarchar2(255) ;
    v_parentobject2 nvarchar2(255) ;
    v_parentobjecttype2 nvarchar2(255) ;
    v_mapobjectname2 nvarchar2(255) ;
    v_prevobjectname nvarchar2(255) ;
    v_prevmapobjectname nvarchar2(255) ;
    v_tablename nvarchar2(255) ;
    v_tablename2 nvarchar2(255) ;
    v_parenttablename2 nvarchar2(255) ;
    v_prevtablename nvarchar2(255) ;
    v_prevforeignkeyname nvarchar2(255) ;
    v_attributename2 nvarchar2(255) ;
    v_attributemapname2 nvarchar2(255) ;
    v_columnname2 nvarchar2(255) ;
    v_attributealias2 nvarchar2(255) ;
    v_foreignkeyname2 nvarchar2(255) ;
    v_query    varchar2(32767) ;
    v_whereqry varchar2(32767) ;
    type cur_typ is ref cursor;
    cur cur_typ;
    v_result varchar2(4000) ;
    curid    number;
    colcnt   number;
    desctab dbms_sql.desc_tab2;
    namevar varchar2(50) ;
    numvar  number;
    datevar date;
    type ObjAliasType
    is
    table of varchar2(64) index by varchar2(64);
    v_ObjectAlias ObjAliasType;
    v_attrcount  Integer;
    v_wherecount Integer;
    /*------------------------------------------------------------------*/
    v_id Integer;
    v_caseid nvarchar2(255) ;
    v_extsysid nvarchar2(255) ;
    v_integtargetid Integer;
    v_summary nvarchar2(255) ;
    v_description nvarchar2(32767) ;
    v_createdby nvarchar2(255) ;
    v_createddate date;
    v_modifiedby nvarchar2(255) ;
    v_modifieddate date;
    v_dateassigned date;
    v_dateclosed   date;
    v_manualworkduration nvarchar2(255) ;
    v_manualdateresolved date;
    v_resolutiondescription nvarchar2(255) ;
    v_draft number;
    v_casefrom nvarchar2(255) ;
    v_casetypecode nvarchar2(255) ;
    v_casetypename nvarchar2(255) ;
    v_casetypeiconcode nvarchar2(255) ;
    v_casetypecolorcode nvarchar2(255) ;
    v_casetypeusedatamodel     number;
    v_casetypeisdraftmodeavail number;
    v_workitemid               Integer;
    v_workitemactivity nvarchar2(255) ;
    v_workitemworkflow nvarchar2(255) ;
    v_priorityid Integer;
    v_priorityname nvarchar2(255) ;
    v_priorityvalue number;
    v_casestateid   Integer;
    v_casestatecode nvarchar2(255) ;
    v_casestatename nvarchar2(255) ;
    v_casestateisstart           number;
    v_casestateisresolve         number;
    v_casestateisfinish          number;
    v_casestateisassign          number;
    v_casestateisfix             number;
    v_casestateisinprocess       number;
    v_casestateisdefaultoncreate number;
    v_workbasketid               Integer;
    v_workbasketcode nvarchar2(255) ;
    v_workbasketname nvarchar2(255) ;
    v_workbaskettypecode nvarchar2(255) ;
    v_workbaskettypename nvarchar2(255) ;
    v_resolutioncodeid INTEGER;
    v_resolutioncodecode nvarchar2(255) ;
    v_resolutioncodename nvarchar2(255) ;
    v_resolutioncodeicon nvarchar2(255) ;
    v_resolutioncodetheme nvarchar2(255) ;
    v_ownercaseworkername nvarchar2(255) ;
    v_hoursspent number;
begin
    v_rootObjectId := :RootObjectId;
    v_CaseTypeId := :CaseTypeId;
    v_output := NULL;
    begin
        select    cs.col_id,
                  cs.caseid,
                  cs.extsysid,
                  cs.integtarget_id,
                  cs.summary,
                  cse.col_description,
                  cs.createdby,
                  cs.createddate,
                  cs.modifiedby,
                  cs.modifieddate,
                  cs.dateassigned,
                  cs.dateclosed,
                  cs.manualworkduration,
                  cs.manualdateresolved,
                  --cs.hoursspent,
                  cse.col_resolutiondescription,
                  cs.draft,
                  cs.casefrom,
                  cs.casesystype_id,
                  cs.casesystype_code,
                  cs.casesystype_name,
                  cs.casesystype_iconcode,
                  cs.casesystype_colorcode,
                  cs.casesystype_usedatamodel,
                  cs.casesystype_isdraftmodeavail,
                  cs.workitem_id,
                  cs.workitem_activity,
                  cs.workitem_workflow,
                  cs.priority_id,
                  cs.priority_name,
                  cs.priority_value,
                  cs.casestate_id,
                  cs.casestate_name,
                  cs.casestate_isstart,
                  cs.casestate_isresolve,
                  cs.casestate_isfinish,
                  cs.casestate_isassign,
                  cs.casestate_isfix,
                  cs.casestate_isinprocess,
                  cs.casestate_isdefaultoncreate,
                  cs.workbasket_id,
                  cs.workbasket_name,
                  cs.owner_caseworker_name,
                  cs.workbasket_type_code,
                  cs.workbasket_type_name,
                  cs.resolutioncode_id,
                  cs.resolutioncode_code,
                  cs.resolutioncode_name,
                  cs.resolutioncode_icon,
                  cs.resolutioncode_theme
        into      v_id,
                  v_caseid,
                  v_extsysid,
                  v_integtargetid,
                  v_summary,
                  v_description,
                  v_createdby,
                  v_createddate,
                  v_modifiedby,
                  v_modifieddate,
                  v_dateassigned,
                  v_dateclosed,
                  v_manualworkduration,
                  v_manualdateresolved,
                  --v_hoursspent,
                  v_resolutiondescription,
                  v_draft,
                  v_casefrom,
                  v_casetypeid,
                  v_casetypecode,
                  v_casetypename,
                  v_casetypeiconcode,
                  v_casetypecolorcode,
                  v_casetypeusedatamodel,
                  v_casetypeisdraftmodeavail,
                  v_workitemid,
                  v_workitemactivity,
                  v_workitemworkflow,
                  v_priorityid,
                  v_priorityname,
                  v_priorityvalue,
                  v_casestateid,
                  v_casestatename,
                  v_casestateisstart,
                  v_casestateisresolve,
                  v_casestateisfinish,
                  v_casestateisassign,
                  v_casestateisfix,
                  v_casestateisinprocess,
                  v_casestateisdefaultoncreate,
                  v_workbasketid,
                  v_workbasketname,
                  v_ownercaseworkername,
                  v_workbaskettypecode,
                  v_workbaskettypename,
                  v_resolutioncodeid,
                  v_resolutioncodecode,
                  v_resolutioncodename,
                  v_resolutioncodeicon,
                  v_resolutioncodetheme
        from      vw_dcm_simplecaselist cs
        left join tbl_caseext cse ON cs.col_id = cse.col_caseextcase
        where     cs.col_id = v_rootobjectid;
    
        exception
        when NO_DATA_FOUND then
        v_id := null;
    end;
    v_output := null;
    if v_id is not null then
        v_output := '<Object ObjectCode="CASE">';
        v_output := v_output || '<Item>';
        v_output := v_output || '<ID>' || TO_CHAR(v_rootobjectid) || '</ID>';
        v_output := v_output || '<COL_ID>' || TO_CHAR(v_rootobjectid) || '</COL_ID>';
        v_output := v_output || '<CASEID>' || v_caseid || '</CASEID>';
        v_output := v_output || '<EXTSYSID>' || v_extsysid || '</EXTSYSID>';
        v_output := v_output || '<INTEGTARGET_ID>' || TO_CHAR(v_integtargetid) || '</INTEGTARGET_ID>';
        v_output := v_output || '<SUMMARY><![CDATA[' || v_summary || ']]></SUMMARY>';
        v_output := v_output || '<DESCRIPTION><![CDATA[' || v_description || ']]></DESCRIPTION>';
        v_output := v_output || '<CREATEDBY>' || v_createdby || '</CREATEDBY>';
        v_output := v_output || '<CREATEDDATE>' || TO_CHAR(v_createddate) || '</CREATEDDATE>';
        v_output := v_output || '<MODIFIEDBY>' || v_modifiedby || '</MODIFIEDBY>';
        v_output := v_output || '<MODIFIEDDATE>' || TO_CHAR(v_modifieddate) || '</MODIFIEDDATE>';
        v_output := v_output || '<DATEASSIGNED>' || TO_CHAR(v_dateassigned) || '</DATEASSIGNED>';
        v_output := v_output || '<DATECLOSED>' || TO_CHAR(v_dateclosed) || '</DATECLOSED>';
        v_output := v_output || '<MANUALWORKDURATION>' || v_manualworkduration || '</MANUALWORKDURATION>';
        v_output := v_output || '<MANUALDATERESOLVED>' || TO_CHAR(v_manualdateresolved) || '</MANUALDATERESOLVED>';
        v_output := v_output || '<RESOLUTIONDESCRIPTION>' || v_resolutiondescription || '</RESOLUTIONDESCRIPTION>';
        v_output := v_output || '<DRAFT>' || TO_CHAR(v_draft) || '</DRAFT>';
        v_output := v_output || '<CASEFROM>' || v_casefrom || '</CASEFROM>';
        v_output := v_output || '<CASESYSTYPE_ID>' || TO_CHAR(v_casetypeid) || '</CASESYSTYPE_ID>';
        v_output := v_output || '<CASESYSTYPE_NAME>' || v_casetypename || '</CASESYSTYPE_NAME>';
        v_output := v_output || '<CASESYSTYPE_CODE>' || v_casetypecode || '</CASESYSTYPE_CODE>';
        v_output := v_output || '<CASESYSTYPE_ICONCODE>' || v_casetypeiconcode || '</CASESYSTYPE_ICONCODE>';
        v_output := v_output || '<CASESYSTYPE_COLORCODE>' || v_casetypecolorcode || '</CASESYSTYPE_COLORCODE>';
        v_output := v_output || '<CASESYSTYPE_USEDATAMODEL>' || TO_CHAR(v_casetypeusedatamodel) || '</CASESYSTYPE_USEDATAMODEL>';
        v_output := v_output || '<CASESYSTYPE_ISDRAFTMODEAVAIL>' || TO_CHAR(v_casetypeisdraftmodeavail) || '</CASESYSTYPE_ISDRAFTMODEAVAIL>';
        v_output := v_output || '<WORKITEM_ID>' || TO_CHAR(v_workitemid) || '</WORKITEM_ID>';
        v_output := v_output || '<WORKITEM_ACTIVITY>' || v_workitemactivity || '</WORKITEM_ACTIVITY>';
        v_output := v_output || '<WORKITEM_WORKFLOW>' || v_workitemworkflow || '</WORKITEM_WORKFLOW>';
        v_output := v_output || '<PRIORITY_ID>' || TO_CHAR(v_priorityid) || '</PRIORITY_ID>';
        v_output := v_output || '<PRIORITY_NAME>' || v_priorityname || '</PRIORITY_NAME>';
        v_output := v_output || '<PRIORITY_VALUE>' || TO_CHAR(v_priorityvalue) || '</PRIORITY_VALUE>';
        v_output := v_output || '<CASESTATE_ID>' || TO_CHAR(v_casestateid) || '</CASESTATE_ID>';
        v_output := v_output || '<CASESTATE_NAME>' || v_casestatename || '</CASESTATE_NAME>';
        v_output := v_output || '<CASESTATE_ISSTART>' || TO_CHAR(v_casestateisstart) || '</CASESTATE_ISSTART>';
        v_output := v_output || '<CASESTATE_ISRESOLVE>' || TO_CHAR(v_casestateisresolve) || '</CASESTATE_ISRESOLVE>';
        v_output := v_output || '<CASESTATE_ISFINISH>' || TO_CHAR(v_casestateisfinish) || '</CASESTATE_ISFINISH>';
        v_output := v_output || '<CASESTATE_ISASSIGN>' || TO_CHAR(v_casestateisassign) || '</CASESTATE_ISASSIGN>';
        v_output := v_output || '<CASESTATE_ISFIX>' || TO_CHAR(v_casestateisfix) || '</CASESTATE_ISFIX>';
        v_output := v_output || '<CASESTATE_ISINPROCESS>' || TO_CHAR(v_casestateisinprocess) || '</CASESTATE_ISINPROCESS>';
        v_output := v_output || '<CASESTATE_ISDEFAULTONCREATE>' || TO_CHAR(v_casestateisdefaultoncreate) || '</CASESTATE_ISDEFAULTONCREATE>';
        v_output := v_output || '<WORKBASKET_ID>' || TO_CHAR(v_workbasketid) || '</WORKBASKET_ID>';
        v_output := v_output || '<WORKBASKET_NAME>' || v_workbasketname || '</WORKBASKET_NAME>';
        v_output := v_output || '<OWNER_CASEWORKER_NAME>' || v_ownercaseworkername || '</OWNER_CASEWORKER_NAME>';
        v_output := v_output || '<WORKBASKET_TYPE_NAME>' || v_workbaskettypename || '</WORKBASKET_TYPE_NAME>';
        v_output := v_output || '<WORKBASKET_TYPE_CODE>' || v_workbaskettypecode || '</WORKBASKET_TYPE_CODE>';
        v_output := v_output || '<RESOLUTIONCODE_ID>' || TO_CHAR(v_resolutioncodeid) || '</RESOLUTIONCODE_ID>';
        v_output := v_output || '<RESOLUTIONCODE_NAME>' || v_resolutioncodename || '</RESOLUTIONCODE_NAME>';
        v_output := v_output || '<RESOLUTIONCODE_CODE>' || v_resolutioncodecode || '</RESOLUTIONCODE_CODE>';
        v_output := v_output || '<RESOLUTIONCODE_ICON>' || v_resolutioncodeicon || '</RESOLUTIONCODE_ICON>';
        v_output := v_output || '<RESOLUTIONCODE_THEME>' || v_resolutioncodetheme || '</RESOLUTIONCODE_THEME>';
        v_output := v_output || '<HOURSSPENT>' || TO_CHAR(v_hoursspent) || '</HOURSSPENT>';
        v_output := v_output || '</Item>';
        v_output := v_output || '</Object>';
    else
        goto exit_;
    end if;
    v_attrcount := 1;
    for rec2 in
    (with s2 as
    (select sra.col_id as ResultAttrId,sra.col_code as ResultAttrCode,sra.col_sorder as ResultOrder,sra.col_metaproperty as ResultAttrMetaProp,sra.col_idproperty as ResultAttrIDProp,
      sra.col_processorcode as ResultAttrProcCode,fp.PathId as PathId,sra.col_som_resultattrfom_path as ObjAttrPath,fo.col_code as ObjCode,fo.col_name as ObjName,fo.col_tablename as ObjTableName,
      fr.col_code as RelCode,fr.col_foreignkeyname as RelForeignKeyName,cfo.col_id as ChildObjId,cfo.col_code as ChildObj,cfo.col_name as ChildObjName,cfo.col_tablename as ChildObjTableName,
      pfo.col_id as ParentObjId,pfo.col_code as ParentObj,pfo.col_name as ParentObjName,pfo.col_tablename as ParentObjTableName,pso.col_type as SOMObjType,fa.col_id as AttrId,fa.col_code as AttrCode,
      fa.col_name as AttrName,fa.col_columnname as AttrColumnName,fa.col_alias as AttrAlias,dt.col_code as DataTypeCode,rfo.col_code as RootObjCode,rfo.col_name as RootObjName,rfo.col_tablename as RootObjTableName,
      case when fo.col_code = rfo.col_code then 1 else 0 end as IsRootObject
      from (select col_id as PathId,col_fom_pathfom_relationship,col_fom_pathfom_path,col_code,col_name,col_jointype
            from tbl_fom_path
            connect by prior col_id = col_fom_pathfom_path
            start with col_id in (select col_som_resultattrfom_path
                                  from tbl_som_resultattr
                                  where col_som_resultattrsom_config in (select sc.col_id
                                                                    from   tbl_som_config sc
                                                                    inner join tbl_som_model sm ON sc.col_som_configsom_model = sm.col_id
                                                                    inner join tbl_mdm_model mm ON sm.col_som_modelmdm_model = mm.col_id
                                                                    inner join tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
                                                                    where ct.col_id = v_CaseTypeId))) fp
      left join tbl_fom_relationship fr on fp.col_fom_pathfom_relationship = fr.col_id
      left join tbl_fom_object cfo on fr.col_childfom_relfom_object = cfo.col_id
      left join tbl_fom_object pfo on fr.col_parentfom_relfom_object = pfo.col_id
      inner join (select count(*),col_type,col_som_objectfom_object,col_som_objectsom_model
                  from tbl_som_object
                  where col_som_objectsom_model =
                  (select col_id from tbl_som_model where col_som_modelmdm_model = (select col_id from tbl_mdm_model where col_id = (select col_casesystypemodel from tbl_dict_casesystype where col_id = v_CaseTypeId)))
                  group by col_type,col_som_objectfom_object,col_som_objectsom_model) pso on pfo.col_id = pso.col_som_objectfom_object
                                                                                         and pso.col_som_objectsom_model = (select sm.col_id
                                                                                         from tbl_som_model sm
                                                                                         inner join tbl_mdm_model mm ON sm.col_som_modelmdm_model = mm.col_id
                                                                    inner join tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
                                                                    where ct.col_id = v_CaseTypeId)
      left join tbl_som_resultattr sra on fp.pathid = sra.col_som_resultattrfom_path and sra.col_som_resultattrsom_config in (select sc.col_id
                                                                                     from tbl_som_config sc
                                                                                     inner join tbl_som_model sm ON sc.col_som_configsom_model = sm.col_id
                                                                                     inner join tbl_mdm_model mm ON sm.col_som_modelmdm_model = mm.col_id
                                                                    inner join tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
                                                                    where ct.col_id = v_CaseTypeId)
      left join tbl_fom_attribute fa on sra.col_som_resultattrfom_attr = fa.col_id
      left join tbl_fom_object fo on fa.col_fom_attributefom_object = fo.col_id
      left join tbl_som_config sc on sra.col_som_resultattrsom_config = sc.col_id
      left join tbl_fom_object rfo on sc.col_som_configfom_object = rfo.col_id
      left join tbl_dict_datatype dt on dt.col_id = fa.col_fom_attributedatatype)
      select count(*) as ResultAttrCount,ResultAttrId,ResultAttrCode,ResultOrder,ResultAttrMetaProp,ResultAttrIDProp,ResultAttrProcCode,AttrId,AttrCode,AttrName,AttrColumnName,AttrAlias,DataTypeCode,
             PathId as PathId,ObjAttrPath,ObjCode,ObjName,ObjTableName,RelCode,RelForeignKeyName,RootObjCode,RootObjName,RootObjTableName,IsRootObject,ChildObjId,ChildObj,ChildObjName,ChildObjTableName,
             ParentObjId,ParentObj,ParentObjName,ParentObjTableName,SOMObjType
      from s2
      group by ResultAttrId,ResultAttrCode,ResultOrder,ResultAttrMetaProp,ResultAttrIDProp,ResultAttrProcCode,AttrId,AttrCode,AttrName,AttrColumnName,AttrAlias,DataTypeCode,
             PathId,ObjAttrPath,ObjCode,ObjName,ObjTableName,RelCode,RelForeignKeyName,RootObjCode,RootObjName,RootObjTableName,IsRootObject,ChildObjId,ChildObj,ChildObjName,ChildObjTableName,
             ParentObjId,ParentObj,ParentObjName,ParentObjTableName,SOMObjType
      order by ChildObjId,ResultOrder)
    loop
        v_objectname2 := rec2.ChildObj;
        v_tablename2 := rec2.ChildObjTableName;
        v_parentobject2 := rec2.ParentObj;
        v_parenttablename2 := rec2.ParentObjTableName;
        v_parentobjecttype2 := rec2.SOMObjType;
        v_mapobjectname2 := rec2.ChildObjName;
        v_foreignkeyname2 := rec2.RelForeignKeyName;
        v_attributename2 := rec2.AttrName;
        v_attributemapname2 := NULL;
        v_columnname2 := rec2.AttrColumnName;
        if v_columnname2 is null then
          continue;
        end if;
        if rec2.ObjCode = 'CASE' or rec2.ChildObj = 'CASE' then
          continue;
        end if;
        if rec2.ResultAttrMetaProp = 1 AND rec2.ResultAttrIDProp = 1 then
            v_columnname2 := rec2.ResultAttrProcCode || '(' || rec2.ResultAttrId || ')';
            v_attributealias2 := rec2.ResultAttrCode;
        elsif v_parentobjecttype2 = 'referenceObject' THEN
            v_attributealias2 := rec2.ResultAttrCode;
        else
            v_attributealias2 := rec2.AttrAlias;
        end if;
        if v_parentobjecttype2 = 'referenceObject' THEN
            v_columnname2 := '(select ' || v_columnname2 || ' from ' || v_parenttablename2 || ' where col_id = ' || v_foreignkeyname2 || ')';
        end if;
        v_ObjectAlias(v_attrcount) := v_attributealias2;
        if v_objectname2 <> nvl(v_prevobjectname,v_objectname2) then
            v_whereqry := null;
            v_wherecount := 0;
            for rec in (select fo.col_id as ChildFOMObjId,fo.col_code as ChildFOMObjCode,fo.col_tablename as ChildTableName,pfo.col_id as ParentFOMObjId,pfo.col_code as ParentFOMObjCode,pfo.col_tablename as ParentTableName,
                       fr.col_code as FOMRelCode,fr.col_foreignkeyname as FOMRelForeignKeyName,so.col_id as ChildSOMObjId,so.col_code as ChildSOMObjCode,so.col_type as ChildSOMObjType,pso.col_id as ParentSOMObjId,
                       pso.col_code as ParentSOMObjCode,pso.col_type as ParentSOMObjType
            from       tbl_fom_object fo
            inner join tbl_fom_relationship fr on fo.col_id = fr.col_childfom_relfom_object
            inner join tbl_fom_object pfo      on fr.col_parentfom_relfom_object = pfo.col_id
            inner join tbl_som_object so       on fo.col_id = so.col_som_objectfom_object AND so.col_som_objectsom_model IN(SELECT col_id
                       from    tbl_som_model
                       where   col_som_modelmdm_model in (select mm.col_id
                               from    tbl_mdm_model mm
                        inner join tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
                        where ct.col_id = v_CaseTypeId))
            inner join tbl_som_relationship sr on so.col_id = sr.col_childsom_relsom_object
            inner join tbl_som_object pso      on pfo.col_id = pso.col_som_objectfom_object and sr.col_parentsom_relsom_object = pso.col_id and pso.col_som_objectsom_model in
                                                    (select col_id
                                                     from    tbl_som_model
                                                     where   col_som_modelmdm_model in (select mm.col_id
                                                                                        from    tbl_mdm_model mm
                                                                                    inner join tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
                                                                                    where ct.col_id = v_CaseTypeId))
            where      pso.col_type in ('businessObject','rootBusinessObject','parentBusinessObject')
                       connect by prior pfo.col_id = fo.col_id
                       start with fo.col_code = v_prevobjectname)
            loop
                if v_whereqry is null then
                    v_whereqry := ' where ' || rec.FOMRelForeignKeyName || ' in ';
                else
                    v_whereqry := v_whereqry || '.' || rec.FOMRelForeignKeyName || ' in ';
                end if;
                if rec.ParentFOMObjCode = 'CASE' then
                    v_whereqry := v_whereqry || '(select col_id from ' || rec.ParentTableName || ' where ' || rec.ParentTableName || '.col_id = ' || TO_CHAR(v_rootobjectid) || rpad(')',v_wherecount+1,')') ;
                else
                    v_whereqry := v_whereqry || '(select col_id from ' || rec.ParentTableName || ' where ' || rec.ParentTableName;
                    v_wherecount := v_wherecount + 1;
                end if;
            end loop;
            v_query := v_query || ' from ' || v_prevtablename || v_whereqry || ' order by ' || v_prevtablename || '.col_id';
            v_output := v_output || '<Object ObjectCode="' || v_prevobjectname || '">';
            open cur for v_query;
            curid := dbms_sql.to_cursor_number(cur);
            dbms_sql.describe_columns2(curid,colcnt,desctab) ;
            for i IN 1 .. colcnt
            loop
                IF desctab(i).col_type = 2 then
                    dbms_sql.define_column(curid,i,numvar) ;
                elsif desctab(i).col_type = 12 then
                    dbms_sql.define_column(curid,i,datevar) ;
                else
                    dbms_sql.define_column(curid,i,namevar,50) ;
                end if;
            end loop;
            /*-- Fetch rows with DBMS_SQL package:*/
            while dbms_sql.fetch_rows(curid) > 0
            loop
                v_output := v_output || '<Item>';
                for i IN 1 .. colcnt
                loop
                    if(desctab(i).col_type = 1) then
                        dbms_sql.column_value(curid,i,namevar) ;
                        v_output := v_output || '<' || v_objectalias(i) || '><![CDATA[' || namevar || ']]></' || v_objectalias(i) || '>';
                    elsif(desctab(i).col_type = 2) THEN
                        dbms_sql.column_value(curid,i,numvar) ;
                        v_output := v_output || '<' || v_objectalias(i) || '>' || TO_CHAR(numvar) || '</' || v_objectalias(i) || '>';
                    elsif(desctab(i).col_type = 12) THEN
                        dbms_sql.column_value(curid,i,datevar) ;
                        v_output := v_output || '<' || v_objectalias(i) || '>' || TO_CHAR(datevar) || '</' || v_objectalias(i) || '>';
                    end if;
                end loop;
                v_output := v_output || '</Item>';
            end loop;
            dbms_sql.close_cursor(curid) ;
            v_output := v_output || '</Object>';
            v_query := null;
            v_attrcount := 1;
        end if;
        if v_query is null then
            v_query := 'select ' || v_columnName2;
        elsif trim(v_query) = 'select' then
            v_query := v_query || v_columnName2;
        else
            v_query := v_query || ', ' || v_columnName2;
        end if;
        v_attrcount := v_attrcount + 1;
        v_prevobjectname := v_objectname2;
        v_prevtablename := v_tablename2;
        v_prevforeignkeyname := v_foreignkeyname2;
        v_prevmapobjectname := v_mapobjectname2;
    end loop;
    v_whereqry := null;
    v_wherecount := 0;
    for rec in (select fo.col_id as ChildFOMObjId,fo.col_code as ChildFOMObjCode,fo.col_tablename as ChildTableName,pfo.col_id as ParentFOMObjId,pfo.col_code as ParentFOMObjCode,pfo.col_tablename as ParentTableName,
               fr.col_code as FOMRelCode,fr.col_foreignkeyname as FOMRelForeignKeyName,so.col_id as ChildSOMObjId,so.col_code as ChildSOMObjCode,so.col_type as ChildSOMObjType,pso.col_id as ParentSOMObjId,
               pso.col_code as ParentSOMObjCode,pso.col_type as ParentSOMObjType
    from       tbl_fom_object fo
    inner join tbl_fom_relationship fr on fo.col_id = fr.col_childfom_relfom_object
    inner join tbl_fom_object pfo      on fr.col_parentfom_relfom_object = pfo.col_id
    inner join tbl_som_object so       on fo.col_id = so.col_som_objectfom_object and so.col_som_objectsom_model in (select col_id
               from    tbl_som_model
               where   col_som_modelmdm_model in (select mm.col_id
                       from    tbl_mdm_model mm
                inner join tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
                where ct.col_id = v_CaseTypeId))
    inner join tbl_som_relationship sr on so.col_id = sr.col_childsom_relsom_object
    inner join tbl_som_object pso      on pfo.col_id = pso.col_som_objectfom_object and sr.col_parentsom_relsom_object = pso.col_id and pso.col_som_objectsom_model in (select col_id
               from    tbl_som_model
               where   col_som_modelmdm_model in (select mm.col_id
                       from    tbl_mdm_model mm
                inner join tbl_dict_casesystype ct on ct.col_casesystypemodel =  mm.col_id
                where ct.col_id = v_CaseTypeId))
    where      pso.col_type IN('businessObject',
                               'rootBusinessObject',
                               'parentBusinessObject')
               connect by prior pfo.col_id = fo.col_id
               start with fo.col_code = v_prevobjectname)
    loop
        if v_whereqry is null then
            v_whereqry := ' where ' || rec.FOMRelForeignKeyName || ' in ';
        else
            v_whereqry := v_whereqry || '.' || rec.FOMRelForeignKeyName || ' in ';
        end if;
        if rec.ParentFOMObjCode = 'CASE' then
            v_whereqry := v_whereqry || '(select col_id from ' || rec.ParentTableName || ' where ' || rec.ParentTableName || '.col_id = ' || TO_CHAR(v_rootobjectid) || rpad(')',v_wherecount+1,')') ;
        else
            v_whereqry := v_whereqry || '(select col_id from ' || rec.ParentTableName || ' where ' || rec.ParentTableName;
            v_wherecount := v_wherecount + 1;
        end if;
    end loop;
    v_query := v_query || ' from ' || v_prevtablename || v_whereqry || ' order by ' || v_prevtablename || '.col_id';
    v_output := v_output || '<Object ObjectCode="' || v_prevobjectname || '">';
    open cur for v_query;
    curid := dbms_sql.to_cursor_number(cur);
    dbms_sql.describe_columns2(curid,colcnt,desctab);
    for i IN 1 .. colcnt
    loop
        if desctab(i).col_type = 2 then
            dbms_sql.define_column(curid,i,numvar) ;
        elsif desctab(i).col_type = 12 then
            dbms_sql.define_column(curid,i,datevar) ;
        else
            dbms_sql.define_column(curid,i,namevar,50) ;
        end if;
    end loop;
    /*-- Fetch rows with DBMS_SQL package:*/
    while dbms_sql.fetch_rows(curid) > 0
    loop
        v_output := v_output || '<Item>';
        for i IN 1 .. colcnt
        loop
            if(desctab(i).col_type = 1) then
                dbms_sql.column_value(curid,i,namevar) ;
                v_output := v_output || '<' || v_objectalias(i) || '><![CDATA[' || namevar || ']]></' || v_objectalias(i) || '>';
            elsif(desctab(i).col_type = 2) then
                dbms_sql.column_value(curid,i,numvar) ;
                v_output := v_output || '<' || v_objectalias(i) || '>' || TO_CHAR(numvar) || '</' || v_objectalias(i) || '>';
            elsif(desctab(i).col_type = 12) then
                dbms_sql.column_value(curid,i,datevar) ;
                v_output := v_output || '<' || v_objectalias(i) || '>' || TO_CHAR(datevar) || '</' || v_objectalias(i) || '>';
            end if;
        end loop;
        v_output := v_output || '</Item>';
    end loop;
    dbms_sql.close_cursor(curid) ;
    v_output := v_output || '</Object>';
    v_output := '<CustomData><Attributes>' || v_output || '</Attributes></CustomData>';
    v_query := NULL;
    update tbl_caseext
    set    col_customdata = xmltype(v_output)
    where  col_caseextcase = v_rootobjectid;

    <<exit_>> NULL;
    exception
    when OTHERS then
    :ErrorCode := 301;
    :ErrorMessage := 'There was an error retrieving the Case' || '<br> QUERY >>>> ' || v_query;
end;