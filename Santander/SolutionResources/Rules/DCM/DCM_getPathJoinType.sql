declare
  v_result number;
  v_PathJoinType nvarchar2(255);
begin
  v_PathJoinType := :PathJoinType;
  if lower(trim(v_PathJoinType)) = 'inner' then
    return ' inner';
  end if;
  return ' left';
end;