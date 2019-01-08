declare
  v_result number;
  v_smodelid Integer;
  v_attrcount Integer;
  v_relcode nvarchar2(255);
  v_relname nvarchar2(255);
  v_rootobjectcode nvarchar2(255);
  v_childobjectid Integer;
  v_childobjectcode nvarchar2(255);
  v_childobjecttype nvarchar2(255);
  v_parentobjectid Integer;
  v_parentobjectcode nvarchar2(255);
  v_parentobjecttype nvarchar2(255);
  v_ppobjectid Integer;
  v_ppobjectcode nvarchar2(255);
  v_ppobjectname nvarchar2(255);
  v_attrCode nvarchar2(255);
  v_attrName nvarchar2(255);
  v_configid Integer;
  v_configcode nvarchar2(255);
  v_pathid Integer;
  v_pathcode nvarchar2(255);
  v_resultattrid Integer;
  v_searchattrid Integer;
  v_attrFOMCode nvarchar2(255);
  v_attrOrder Integer;
begin
  v_result := null;
  v_smodelid := :SModelId;
  begin
    select count(*) into v_result
    from tbl_som_resultattr ra
    inner join tbl_som_config sc on ra.col_som_resultattrsom_config = sc.col_id
    inner join tbl_som_model sm on sc.col_som_configsom_model = sm.col_id
    where sm.col_id = v_smodelid;
    exception
    when NO_DATA_FOUND then
    v_result := 0;
  end;
  v_attrcount := v_result + 1;
  for rec in (select RelCode, ChildObjId, ChildObjCode, ChildObjType, ParentObjId, ParentObjCode, ParentObjType,
                     IsChildObjRoot, IsParentObjRoot, ChildModelCode, ParentModelCode,
                     level as ObjLevel, connect_by_root ChildObjCode as RootChildObj
              from
              (select sr.col_code as RelCode, co.col_id as ChildObjId, co.col_code as ChildObjCode, co.col_type as ChildObjType,
               po.col_id as ParentObjId, po.col_code as ParentObjCode, po.col_type as ParentObjType,
               co.col_isroot as IsChildObjRoot, po.col_isroot as IsParentObjRoot,
               cm.col_code as ChildModelCode, pm.col_code as ParentModelCode
               from tbl_som_relationship sr
               inner join tbl_som_object co on sr.col_childsom_relsom_object = co.col_id
               inner join tbl_som_object po on sr.col_parentsom_relsom_object = po.col_id
               inner join tbl_som_model cm on co.col_som_objectsom_model = cm.col_id
               inner join tbl_som_model pm on po.col_som_objectsom_model = pm.col_id
               where cm.col_id = v_smodelid
               and pm.col_id = v_smodelid)
              connect by prior ParentObjCode = ChildObjCode
              start with ChildObjCode in
              (select so.col_code as ObjCode
               from tbl_som_object so
               inner join tbl_som_model sm on so.col_som_objectsom_model = sm.col_id
               where sm.col_id = v_smodelid))
  loop
    v_relcode := rec.RelCode;
    v_rootobjectcode := rec.RootChildObj;
    v_childobjectid := rec.ChildObjId;
    v_childobjectcode := rec.ChildObjCode;
    v_childobjecttype := rec.ChildObjType;
    v_parentobjectid := rec.ParentObjId;
    v_parentobjectcode := rec.ParentObjCode;
    v_parentobjecttype := rec.ParentObjType;
    begin
      select po.col_id, po.col_code, po.col_name
      into v_ppobjectid, v_ppobjectcode, v_ppobjectname
      from tbl_som_relationship rl
      inner join tbl_som_object co on rl.col_childsom_relsom_object = co.col_id
      inner join tbl_som_object po on rl.col_parentsom_relsom_object = po.col_id
      where co.col_id = v_parentobjectid
      and po.col_type in ('rootBusinessObject', 'businessObject');
      exception
      when NO_DATA_FOUND then
      v_ppobjectcode := 'CASE';
      v_ppobjectname := 'CASE';
    end;
    for rec2 in (select col_code as AttrCode, col_name as AttrName, col_som_attrfom_attr as FOMAttrCode, col_dorder as DOrder
    from tbl_som_attribute
    where col_som_attributesom_object = rec.ParentObjId)
    loop
      v_attrCode := rec2.AttrCode;
      v_attrName := rec2.AttrName;
      v_attrFOMCode := rec2.FOMAttrCode;
      v_attrOrder := rec2.DOrder;
      ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      begin
        select col_id, col_code
        into v_configid, v_configcode
        from tbl_som_config sc where col_som_configsom_model = v_smodelid
       and col_som_configfom_object =
       (select col_som_objectfom_object from tbl_som_object where col_som_objectsom_model = v_smodelid and col_code = v_rootobjectcode and col_som_objectfom_object = sc.col_som_configfom_object);
       exception
       when NO_DATA_FOUND then
       null;
      end;
      if v_parentobjecttype = 'referenceObject' then
        begin
          select col_id, col_code
          into v_pathid, v_pathcode
          from tbl_fom_path where col_fom_pathfom_relationship =
          (select col_id from tbl_fom_relationship where col_parentfom_relfom_object =
            (select col_id from tbl_fom_object where lower(col_code) = lower(v_parentobjectcode))
          and col_childfom_relfom_object =
            (select col_som_objectfom_object from tbl_som_object where col_som_objectsom_model = v_smodelid and col_code = v_childobjectcode));
          exception
          when NO_DATA_FOUND then
          null;
        end;
        v_attrorder := v_attrcount + 1000;
      elsif v_parentobjecttype = 'businessObject' or v_parentobjecttype = 'rootBusinessObject' then
        begin
          select col_id, col_code
          into v_pathid, v_pathcode
          from tbl_fom_path where col_fom_pathfom_relationship =
          (select col_id from tbl_fom_relationship where col_parentfom_relfom_object =
            (select col_id from tbl_fom_object where lower(col_code) = lower(v_ppobjectcode))
          and col_childfom_relfom_object =
            (select col_som_objectfom_object from tbl_som_object where col_som_objectsom_model = v_smodelid and col_code = v_parentobjectcode));
          exception
          when NO_DATA_FOUND then
          null;
        end;
        v_attrorder := v_attrcount;
      end if;
      ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      begin
        select col_id into v_resultattrid
        from tbl_som_resultattr
        where lower(col_code) = lower(v_attrCode)
        and col_som_resultattrsom_config = v_configid;
        exception
        when NO_DATA_FOUND then
        insert into tbl_som_resultattr(col_code, col_name, col_som_resultattrfom_attr, col_som_resultattrfom_path, col_som_resultattrsom_config, col_sorder)
        values(v_attrCode, v_attrName,
               (select col_som_attrfom_attr from tbl_som_attribute where col_som_attributesom_object = v_parentobjectid and col_code = v_attrCode),
               v_pathid, v_configid, v_attrorder);
        v_attrcount := v_attrcount + 1;
      end;
      begin
        select col_id into v_searchattrid
        from tbl_som_searchattr
        where lower(col_code) = lower(v_attrCode)
        and col_som_searchattrsom_config = v_configid;
        exception
        when NO_DATA_FOUND then
        insert into tbl_som_searchattr(col_code, col_name, col_som_searchattrfom_attr, col_som_searchattrfom_path, col_som_searchattrsom_config, col_sorder)
        values(v_attrCode, v_attrName,
               (select col_som_attrfom_attr from tbl_som_attribute where col_som_attributesom_object = v_parentobjectid and col_code = v_attrCode),
               v_pathid, v_configid, v_attrorder);
        v_attrcount := v_attrcount + 1;
      end;
      null;
    end loop;
    null;
  end loop;
end;