declare
  v_result number;
  v_tagid Integer;
  v_tagcode nvarchar2(255);
  v_tagname nvarchar2(255);
  v_tagobjectcode nvarchar2(255);
  v_tagtypecode nvarchar2(255);
  v_bo_tagid Integer;
  v_docid Integer;
begin
  v_tagcode := :TagCode;
  v_tagname := :TagName;
  v_tagobjectcode := 'root_Document';
  v_tagtypecode := :TagTypeCode;
  v_docid := :DocId;
  v_tagid := f_DCM_createTag(TagCode => v_tagcode, tagname => v_tagname, tagobjectcode => v_tagobjectcode, tagobjectname => v_tagobjectcode, tagtypecode => v_tagtypecode, tagtypename => v_tagtypecode);
  begin
    select col_id into v_bo_tagid from tbl_bo_tag where col_bo_tagdict_tag = v_tagid and col_bo_tagdict_tagobject = (select col_id from tbl_dict_tagobject where lower(col_code) = lower(v_tagobjectcode)) and col_instanceid = v_docid;
    exception
    when NO_DATA_FOUND then
      insert into tbl_bo_tag(col_code, col_bo_tagdict_tag, col_bo_tagdict_tagobject, col_instanceid) values(sys_guid(), v_tagid, (select col_id from tbl_dict_tagobject where lower(col_code) = lower(v_tagobjectcode)), v_docid);
      select gen_tbl_bo_tag.currval into v_bo_tagid from dual;
  end;
  :Bo_TagId := v_bo_tagid;
end;