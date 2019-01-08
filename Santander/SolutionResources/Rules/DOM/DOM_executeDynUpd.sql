declare
  v_ConfigId Integer;
  v_id Integer;
  v_previd Integer;
  v_seqnumber nvarchar2(255);
  v_session nvarchar2(255);
  v_query varchar2(32767);
  v_query2 varchar2(32767);
  v_ObjectName nvarchar2(255);
  v_TableName nvarchar2(255);
  v_ChildObj nvarchar2(255);
  v_ChildObjName nvarchar2(255);
  v_ChildObjTableName nvarchar2(255);
  v_ParentObj nvarchar2(255);
  v_ParentObjName nvarchar2(255);
  v_ParentObjTableName nvarchar2(255);
  v_ParentObjSeqNumber nvarchar2(255);
  v_ParentRecordId Integer;
  v_ParentItemId Integer;
  v_SqlType nvarchar2(255);
  v_recordid Integer;
  v_recordid2 Integer;
  v_minrecordid Integer;
  v_rownumber Integer;
  v_count Integer;
begin
  v_ConfigId := :ConfigId;
  v_session := :Session;
  if v_session is null then
    begin
      select col_dom_cachedom_config, col_session
        into v_ConfigId, v_session
        from tbl_dom_cache
        where col_dom_cachedom_config = v_ConfigId
        and col_session = v_session
        and col_sorder = (select max(col_sorder) from tbl_dom_cache where col_dom_cachedom_config = v_ConfigId and col_session = v_session and col_sqltype in ('UPDATE', 'DELETE', 'INSERT', 'SEQUENCE'));
      exception
      when NO_DATA_FOUND then
      v_ConfigId := 1;
      when TOO_MANY_ROWS then
      v_ConfigId := 1;
    end;
  end if;
  v_previd := null;
  v_minrecordid := null;
  for rec in (select col_id as QueryId, col_query as Query, col_objectname as ObjectName, col_objecttablename as TableName,
                     col_childobject as ChildObj, col_childobjectname as ChildObjName, col_childobjecttablename as ChildObjTableName,
                     col_parentobject as ParentObj, col_parentobjectname as ParentObjName, col_parentobjecttablename as ParentObjTableName,
                     col_sqltype as SqlType, col_recordid as ParentObjSeqNumber
              from tbl_dom_cache
              where col_dom_cachedom_config = v_ConfigId
              and col_session = v_session
              and col_sqltype in ('UPDATE', 'DELETE')
              order by col_sorder)
  loop
    v_id := rec.QueryId;
    v_query := rec.Query;
    v_ObjectName := rec.ObjectName;
    v_TableName := rec.TableName;
    v_ChildObj := rec.ChildObj;
    v_ChildObjName := rec.ChildObjName;
    v_ChildObjTableName := rec.ChildObjTableName;
    v_ParentObj := rec.ParentObj;
    v_ParentObjName := rec.ParentObjName;
    v_ParentObjTableName := rec.ParentObjTableName;
    v_SqlType := rec.SqlType;
    v_ParentObjSeqNumber := rec.ParentObjSeqNumber;
    if v_SqlType in ('UPDATE', 'DELETE') then
      execute immediate v_query;
    end if;
  end loop;

  for rec in (select col_id as QueryId, col_query as Query, col_objectname as ObjectName, col_objecttablename as TableName,
                     col_childobject as ChildObj, col_childobjectname as ChildObjName, col_childobjecttablename as ChildObjTableName,
                     col_parentobject as ParentObj, col_parentobjectname as ParentObjName, col_parentobjecttablename as ParentObjTableName,
                     col_sqltype as SqlType, col_parentrecordid as ParentRecordId, col_parentitemid as ParentItemId, col_recordid as ParentObjSeqNumber
              from tbl_dom_cache
              where col_dom_cachedom_config = v_ConfigId
              and col_session = v_session
              and col_sqltype in ('INSERT', 'SEQUENCE')
              order by col_sorder)
  loop
    v_id := rec.QueryId;
    v_query := rec.Query;
    v_ObjectName := rec.ObjectName;
    v_TableName := rec.TableName;
    v_ChildObj := rec.ChildObj;
    v_ChildObjName := rec.ChildObjName;
    v_ChildObjTableName := rec.ChildObjTableName;
    v_ParentObj := rec.ParentObj;
    v_ParentObjName := rec.ParentObjName;
    v_ParentObjTableName := rec.ParentObjTableName;
    v_SqlType := rec.SqlType;
    v_ParentObjSeqNumber := rec.ParentObjSeqNumber;
    v_ParentRecordId := rec.ParentRecordId;
    v_ParentItemId := rec.ParentItemId;
    if v_SqlType = 'INSERT' and instr(v_query,'@' || 'ParentObjectId' || '@') = 0 then
      v_query := v_query || ' returning col_id into ' || ':' || 'retval ';
      execute immediate v_query using out v_recordid2;
    elsif v_SqlType = 'INSERT' and instr(v_query,'@' || 'ParentObjectId' || '@') > 0 then
      if v_ParentObjSeqNumber is null then
        v_ParentObjSeqNumber := 1;
      elsif v_ParentObjSeqNumber = 'NO_DATA_FOUND' then
        v_ParentObjSeqNumber := 0;
      end if;
      if v_ParentRecordId > 0 then
        v_recordid := v_ParentRecordId;
      else
        ------------------------------------------------------------------
        --Select minimal col_id for all records with specified object name
        ------------------------------------------------------------------
        select min(col_parentrecordid) into v_minrecordid from tbl_dom_cache where col_session = v_session and col_childobject = v_ParentObj;
        --Find parent object's col_id (v_recordid) to become parent of child object to be created
        --This value will be used as foreign key when child object is created
        begin
          select s1.RecordId, s1.RowNumber into v_recordid, v_rownumber
          from
          (select col_parentrecordid as RecordId, row_number() over (order by col_id) as RowNumber from tbl_dom_cache
           where col_childobject = v_ParentObj
           and col_session = v_session
           and col_sqltype in ('UPDATE', 'INSERT')
           and col_parentrecordid >= nvl(v_minrecordid, 0)) s1
          where s1.RowNumber = to_number(v_ParentObjSeqNumber);
          exception
          when NO_DATA_FOUND then
          v_recordid := 0;
          v_rownumber := 0;
          when TOO_MANY_ROWS then
          v_recordid := 0;
          v_rownumber := 0;
        end;
      end if;
      if nvl(v_recordid,0) = 0 and v_ParentItemId > 0 then
        v_recordid := v_ParentItemId;
      end if;
      if v_recordid is not null then
        v_query := replace(v_query, '@' || 'ParentObjectId' || '@', to_char(v_recordid));
        v_query2 := 'select count(*) from ' || v_ParentObjTableName || ' where col_id = ' || to_char(v_recordid);
        execute immediate v_query2 into v_count;
        if v_count = 1 then
          execute immediate v_query;
        end if;
      end if;
    elsif v_SqlType = 'SEQUENCE' then
      v_recordid := v_recordid2;
      --SEQUENCE IS NOT USED TO CALCULATE RECORD ID
      /*
      v_recordid := null;
      begin
        execute immediate v_query into v_recordid;
        exception
        when OTHERS then
        v_recordid := null;
      end;
      */
      --Set col_parentrecordid to col_id of recently created record (both for INSERT and SEQUENCE types)
      update tbl_dom_cache set col_parentrecordid = v_recordid where col_id in (v_previd, v_id);
    end if;
    v_previd := v_id;
  end loop;
  return 0;
end;