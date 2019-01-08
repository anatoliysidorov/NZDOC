declare
  v_data1  nvarchar2(255);
  v_data2  nvarchar2(255);
  v_data3  nvarchar2(255);
  v_data4  nvarchar2(255);
  v_data5  nvarchar2(255);
  v_data6  nvarchar2(255);
  v_data7  nvarchar2(255);
  v_data8  nvarchar2(255);
  v_data9  nvarchar2(255);
  v_data10 nvarchar2(255);
  v_TaskId Integer;
begin
  v_data1  := 'Test1';
  v_data2  := 'Test2';
  v_data3  := 'Test3';
  v_data4  := 'Test4';
  v_data5  := 'Test5';
  v_data6  := 'Test6';
  v_data7  := 'Test7';
  v_data8  := 'Test8';
  v_data9  := 'Test9';
  v_data10 := 'Test10';
  v_TaskId := :TaskId;
  insert into tbl_log(col_data1, col_data2, col_data3, col_data4, col_data5, col_data6, col_data7, col_data8, col_data9, col_data10, col_bigdata1)
    values(v_data1, v_data2, v_data3, v_data4, v_data5, v_data6, v_data7, v_data8, v_data9, v_data10, cast(v_TaskId as nvarchar2(64)));
end;