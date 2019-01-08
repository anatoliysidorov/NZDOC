declare
  v_configid Integer;
  v_timeperiodcount Integer;
  v_timeperiodtype nvarchar2(255);
  v_DBConfigCode nvarchar2(255);
  v_DBConfigName nvarchar2(255);
  v_RootObjectCode nvarchar2(255);
  v_RootObjectName nvarchar2(255);
  v_RootTableName nvarchar2(255);
  v_RootAlias nvarchar2(255);
  v_ParentObjectCode nvarchar2(255);
  v_ParentObjectName nvarchar2(255);
  v_ParentTableName nvarchar2(255);
  v_ParentAlias nvarchar2(255);
  v_query varchar2(32767);
  v_countquery varchar2(32767);
begin
  v_configid := :ConfigId;
  v_timeperiodcount := :TimePeriodCount;
  v_timeperiodtype := :TimePeriodType;
  if v_timeperiodtype is null then
    v_timeperiodtype := 'MONTHLY';
  end if;
  if v_timeperiodcount is null then
    v_timeperiodcount := 1;
  end if;
  if v_timeperiodtype <> 'MONTHLY' and v_timeperiodtype <> 'DAYLY' and v_timeperiodtype <> 'WEEKLY' then
    :ErrorCode := 102;
    :ErrorMessage := 'Time period type must be one of the following: MONTHLY or DAYLY or WEEKLY';
    return -1;
  end if;
  begin
    select dbc.col_code as DBConfigCode, dbc.col_name as DBConfigName,
           fo.col_code as RootObjectCode, fo.col_name as RootObjectName, fo.col_tablename as RootTableName, fo.col_alias as RootAlias
           into v_DBConfigCode, v_DBConfigName,
            v_RootObjectCode, v_RootObjectName, v_RootTableName, v_RootAlias
       from tbl_dbm_config dbc
       inner join tbl_fom_object fo on dbc.col_dbm_configfom_object = fo.col_id
       where dbc.col_id = v_configid;
    exception
    when NO_DATA_FOUND then
    :ErrorCode := 101;
    :ErrorMessage := 'Dashboard configuration not found';
    return -1;
  end;
  if v_timeperiodtype = 'MONTHLY' then
    v_query := 'with s5 as (select ' || to_char(v_timeperiodcount) || ' as NumberOfMonths from dual),';
    v_query := v_query || 's7 as (';
    v_query := v_query || 'select level as Counter,';
    v_query := v_query || 'trunc(add_months(sysdate, 1-level), ''MM'') as StartDate,';
    v_query := v_query || 'last_day(add_months(trunc(sysdate), 1-level)) as EndDate';
    v_query := v_query || ' from dual';
    v_query := v_query || ' connect by level <= (select NumberOfMonths from s5))';
    v_query := v_query || ' select s11.ObjectCountByProp,';
    v_query := v_query || ' round(s11.ObjectCountByProp*100/s12.MonthCounter) as ObjectPercentByProp,';
    v_query := v_query || ' s11.PropertyCode, s11.MyMonth, s12.MonthCounter';
  elsif v_timeperiodtype = 'DAYLY' then
    v_query := 'with s5 as (select ' || to_char(v_timeperiodcount) || ' as NumberOfDays from dual),';
    v_query := v_query || 's7 as (';
    v_query := v_query || 'select level as Counter,';
    v_query := v_query || 'trunc(sysdate) - (level - 1) as StartDate,';
    v_query := v_query || 'trunc(sysdate) - (level - 2) EndDate';
    v_query := v_query || ' from dual';
    v_query := v_query || ' connect by level <= (select NumberOfDays from s5))';
    v_query := v_query || ' select s11.ObjectCountByProp,';
    v_query := v_query || ' case when s12.DayCounter > 0 then round(s11.ObjectCountByProp*100/s12.DayCounter) else 0 end as ObjectPercentByProp,';
    v_query := v_query || ' s11.PropertyCode, s11.MyDay, s12.DayCounter, s12.StartDate, s12.EndDate';
  elsif v_timeperiodtype = 'WEEKLY' then
    v_query := 'with s1 as (select next_day(to_date(trunc(sysdate))-1, ''SUN'') as StartDate from dual),';
    v_query := v_query || 's2 as (select '|| to_char(v_timeperiodcount) || ' as NumberOfWeeks from dual),';
    v_query := v_query || 's3 as (select level as counter from dual connect by level <= (select NumberOfWeeks from s2)),';
    v_query := v_query || 's7 as (select counter,';
    v_query := v_query || '(select StartDate from s1) - (counter - 1) * 7 as StartDate,';
    v_query := v_query || '(select StartDate from s1) - (counter - 1) * 7 + 6 as EndDate';
    v_query := v_query || ' from s3)';
    v_query := v_query || ' select s11.ObjectCountByProp,';
    v_query := v_query || ' case when s12.WeekCounter > 0 then round(s11.ObjectCountByProp*100/s12.WeekCounter) else 0 end as ObjectPercentByProp,';
    v_query := v_query || ' s11.PropertyCode, s11.MyWeek, s12.WeekCounter, s12.StartDate, s12.EndDate';
  end if;
  v_query := v_query || ' from ';
  if v_timeperiodtype = 'MONTHLY' then
    v_query := v_query || '(select Counter, StartDate, EndDate,';
  elsif v_timeperiodtype = 'DAYLY' then
    v_query := v_query || '(select Counter, StartDate, EndDate,';
  elsif v_timeperiodtype = 'WEEKLY' then
    v_query := v_query || '(select Counter, StartDate, EndDate,';
  end if;
  v_query := v_query || ' (select count(*) from ';
  v_query := v_query || v_RootTableName || ' ' || v_RootAlias;
  for rec in (
    select dbc.col_code as DBConfigCode, dbc.col_name as DBConfigName,
           fo.col_code as RootObjectCode, fo.col_name as RootObjectName, fo.col_tablename as RootTableName, fo.col_alias as RootAlias,
           fr.col_code as RelationshipCode, fr.col_name as RelationshipName, fr.col_foreignkeyname as ForeignKeyName,
           cfo.col_code as ChildObjectCode, cfo.col_name as ChildObjectName, cfo.col_tablename as ChildTableName, cfo.col_alias as ChildAlias,
           pfo.col_code as ParentObjectCode, pfo.col_name as ParentObjectName, pfo.col_tablename as ParentTableName, pfo.col_alias as ParentAlias
      from
        (select fp.col_id as PathId, fp.col_fom_pathfom_relationship, level as PathLevel
         from tbl_fom_path fp
         connect by prior col_id = col_fom_pathfom_path
         start with col_id = (select col_dbm_configpropfom_path from tbl_dbm_config where col_id = v_configid)) fpt
      left join tbl_fom_relationship fr on fpt.col_fom_pathfom_relationship = fr.col_id
      left join tbl_fom_object cfo on fr.col_childfom_relfom_object = cfo.col_id
      left join tbl_fom_object pfo on fr.col_parentfom_relfom_object = pfo.col_id
      left join tbl_dbm_config dbc on dbc.col_id = v_configid
      left join tbl_fom_object fo on dbc.col_dbm_configfom_object = fo.col_id
      order by fpt.PathLevel desc)
  loop
    v_query := v_query || ' inner join ' || rec.ParentTableName || ' ' || rec.ParentAlias || ' on ' || rec.ChildAlias || '.' || rec.ForeignKeyName || ' = ' || rec.ParentAlias || '.col_id';
    v_ParentAlias := rec.ParentAlias;
  end loop;
  if v_timeperiodtype = 'MONTHLY' then
    v_query := v_query || ' where trunc(' || v_RootAlias || '.col_createddate) between s7.StartDate and s7.EndDate) as MonthCounter from s7) s12';
  elsif v_timeperiodtype = 'DAYLY' then
    v_query := v_query || ' where ' || v_RootAlias || '.col_createddate between s7.StartDate and s7.EndDate) as DayCounter from s7) s12';
  elsif v_timeperiodtype = 'WEEKLY' then
    v_query := v_query || ' where trunc(' || v_RootAlias || '.col_createddate, ''WW'') between s7.StartDate and s7.EndDate) as WeekCounter from s7) s12';
  end if;
  v_query := v_query || ' inner join ';
  v_query := v_query || ' (select count(*) as ObjectCountByProp, ' || v_ParentAlias || '.col_code as PropertyCode, ';
  if v_timeperiodtype = 'MONTHLY' then
    v_query := v_query || ' trunc(' || v_RootAlias || '.col_createddate, ''MM'') as MyMonth';
  elsif v_timeperiodtype = 'DAYLY' then
    v_query := v_query || ' trunc(' || v_RootAlias || '.col_createddate) as MyDay';
  elsif v_timeperiodtype = 'WEEKLY' then
    v_query := v_query || ' trunc(' || v_RootAlias || '.col_createddate, ''WW'') as MyWeek';
  end if;
  v_query := v_query || ' from ' || v_RootTableName || ' ' || v_RootAlias;
  for rec in (
    select dbc.col_code as DBConfigCode, dbc.col_name as DBConfigName,
           fo.col_code as RootObjectCode, fo.col_name as RootObjectName, fo.col_tablename as RootTableName, fo.col_alias as RootAlias,
           fr.col_code as RelationshipCode, fr.col_name as RelationshipName, fr.col_foreignkeyname as ForeignKeyName,
           cfo.col_code as ChildObjectCode, cfo.col_name as ChildObjectName, cfo.col_tablename as ChildTableName, cfo.col_alias as ChildAlias,
           pfo.col_code as ParentObjectCode, pfo.col_name as ParentObjectName, pfo.col_tablename as ParentTableName, pfo.col_alias as ParentAlias
      from
        (select fp.col_id as PathId, fp.col_fom_pathfom_relationship, level as PathLevel
         from tbl_fom_path fp
         connect by prior col_id = col_fom_pathfom_path
         start with col_id = (select col_dbm_configpropfom_path from tbl_dbm_config where col_id = v_configid)) fpt
      left join tbl_fom_relationship fr on fpt.col_fom_pathfom_relationship = fr.col_id
      left join tbl_fom_object cfo on fr.col_childfom_relfom_object = cfo.col_id
      left join tbl_fom_object pfo on fr.col_parentfom_relfom_object = pfo.col_id
      left join tbl_dbm_config dbc on dbc.col_id = v_configid
      left join tbl_fom_object fo on dbc.col_dbm_configfom_object = fo.col_id
      order by fpt.PathLevel desc)
  loop
    v_query := v_query || ' inner join ' || rec.ParentTableName || ' ' || rec.ParentAlias || ' on ' || rec.ChildAlias || '.' || rec.ForeignKeyName || ' = ' || rec.ParentAlias || '.col_id';
    v_ParentAlias := rec.ParentAlias;
  end loop;
  v_query := v_query || ' group by ' || v_ParentAlias || '.col_code,';
  if v_timeperiodtype = 'MONTHLY' then
    v_query := v_query || ' trunc(' || v_RootAlias || '.col_createddate, ''MM'')';
    v_query := v_query || ') s11 on s11.MyMonth between s12.StartDate and s12.EndDate';
  elsif v_timeperiodtype = 'DAYLY' then
    v_query := v_query || ' trunc(' || v_RootAlias || '.col_createddate)';
    v_query := v_query || ') s11 on s11.MyDay >= s12.StartDate and s11.MyDay < s12.EndDate';
  elsif v_timeperiodtype = 'WEEKLY' then
    v_query := v_query || ' trunc(' || v_RootAlias || '.col_createddate, ''WW'')';
    v_query := v_query || ') s11 on s11.MyWeek >= s12.StartDate and s11.MyWeek < s12.EndDate';
  end if;
  v_query := v_query || ' order by s12.Counter, s11.ObjectCountByProp desc';
  v_countquery := 'select count(*) from ( ' || v_query || ')';
  --dbms_output.put_line(v_countquery);
  --dbms_output.put_line(v_query);
  BEGIN
    EXECUTE IMMEDIATE v_countquery
      INTO :TotalCount;
  EXCEPTION
    WHEN OTHERS THEN
        :ErrorCode := SQLCODE;
        :ErrorMessage := SUBSTR('Error in count query' || ': ' || SQLERRM, 1, 200);
  END;
  BEGIN
    OPEN :ITEMS FOR v_query;
  EXCEPTION
    WHEN OTHERS THEN
        :ErrorCode := SQLCODE;
        :ErrorMessage := SUBSTR('Error on search query' || ': ' || SQLERRM, 1, 200);
  END;
end;
