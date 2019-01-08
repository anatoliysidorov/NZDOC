declare
  v_result number;
  v_tagid Integer;
  v_tagcode nvarchar2(255);
  v_tagname nvarchar2(255);
  v_tagtypecode nvarchar2(255);
  v_tagtypename nvarchar2(255);
  v_tagtypeid Integer;
  v_tagobjectid Integer;
  v_tagobjectcode nvarchar2(255);
  v_tagobjectname nvarchar2(255);
begin
  v_tagcode := :TagCode;
  v_tagname := :TagName;
  if v_tagname is null then
    v_tagname := v_tagcode;
  end if;
  v_tagtypecode := :TagTypeCode;
  v_tagtypename := :TagTypeName;
  if v_tagtypename is null then
    v_tagtypename := v_tagtypecode;
  end if;
  v_tagobjectcode := :TagObjectCode;
  v_tagobjectname := :TagObjectName;
  if v_tagobjectname is null then
    v_tagobjectname := v_tagobjectcode;
  end if;
  if (v_tagcode is null) or (v_tagtypecode is null) then
    return null;
  end if;
  begin
    select col_id into v_tagtypeid from tbl_dict_tagtype where lower(col_code) = lower(v_tagtypecode);
    exception
    when NO_DATA_FOUND then
    insert into tbl_dict_tagtype(col_code, col_name) values(v_tagtypecode, v_tagtypename);
    select gen_tbl_dict_tagtype.currval into v_tagtypeid from dual;
  end;
  begin
    select col_id into v_tagid from tbl_dict_tag where lower(col_code) = lower(v_tagcode);
    exception
    when NO_DATA_FOUND then
    insert into tbl_dict_tag(col_code, col_name, col_dict_tagdict_tagtype) values(v_tagcode, v_tagname, v_tagtypeid);
    select gen_tbl_dict_tag.currval into v_tagid from dual;
  end;
  begin
    select col_id into v_tagobjectid from tbl_dict_tagobject where lower(col_code) = lower(v_tagobjectcode);
    exception
    when NO_DATA_FOUND then
    insert into tbl_dict_tagobject(col_code, col_name) values(v_tagobjectcode, v_tagobjectname);
    select gen_tbl_dict_tagobject.currval into v_tagobjectid from dual;
  end;
  begin
    select col_id into v_result from tbl_dict_tagtotagobject where col_tagtotagobjectdict_tag = v_tagid and col_tagtotagobjectdict_tagobj = v_tagobjectid;
    exception
    when NO_DATA_FOUND then
    begin
      insert into tbl_dict_tagtotagobject(col_code, col_name, col_tagtotagobjectdict_tag, col_tagtotagobjectdict_tagobj) values(v_tagcode || '_' || v_tagobjectcode, v_tagcode || '_' || v_tagobjectcode, v_tagid, v_tagobjectid);
      exception
      when DUP_VAL_ON_INDEX then
      insert into tbl_dict_tagtotagobject(col_code, col_name, col_tagtotagobjectdict_tag, col_tagtotagobjectdict_tagobj) values(sys_guid(), v_tagcode || '_' || v_tagobjectcode, v_tagid, v_tagobjectid);
    end;
  end;
  return v_tagid;
end;