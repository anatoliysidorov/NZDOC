begin
  begin
    --select NVL(value, :defaultSetting) into :setting from config where name = :name;
    select NVL(col_value, :defaultSetting) into :setting from tbl_config where col_name = :name;
    exception
      when NO_DATA_FOUND then
        :setting := :defaultSetting;
  end;
end;