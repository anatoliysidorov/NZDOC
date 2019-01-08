declare
  v_result nvarchar2(255);
  v_query varchar2(2000);
  v_col_result_name nvarchar2(255);
  v_col_searchby_name nvarchar2(255);
  v_col_searchby_value nvarchar2(255);
  v_tbl_name nvarchar2(255);
  v_default nvarchar2(255);
begin
  v_col_result_name := :p_col_result_name;
  v_col_searchby_name := :p_col_searchby_name;
  v_col_searchby_value := :p_col_searchby_value;
  v_tbl_name := :p_tbl_name;
  v_default := :p_default;
  v_query := 'select ' || v_col_result_name || ' from ' || v_tbl_name || ' where ' || v_col_searchby_name || ' = ' || '''' || v_col_searchby_value || '''';
  
  begin
    execute immediate v_query into v_result;
    exception
      when NO_DATA_FOUND then
        v_result := v_default;
  end;

  :result := v_result;
end;