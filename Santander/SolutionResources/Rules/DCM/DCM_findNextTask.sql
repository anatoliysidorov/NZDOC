declare
  v_TaskId Integer;
  v_result Integer;
  v_NextReviewTaskId Integer;
  v_CloseTaskId Integer;
begin
  v_TaskId := :TaskId;
  begin
    --GET ID OF NEXT REVIEW TASK BY TASK ORDER. NEXT TASK IS SELECTED BY MINIMUM TASK ORDER BETWEEN TASKS THAT ARE NOT CLOSED (DATE CLOSED IS NULL)
    select col_id
      into v_NextReviewTaskId
      from tbl_task
      where col_id = (select col_id
                        from tbl_task
                          where col_parentid = (select col_parentid
                          from tbl_task
                          where col_id = v_TaskId)
                          and col_DateClosed is null
                          and lower(col_systemtype2) = 'review'
                          and col_taskorder = (select min(col_taskorder)
                                                 from tbl_task
                                                   where col_parentid = (select col_parentid
                                                                           from tbl_task
                                                                           where col_id = v_TaskId)
                                                     and col_id <> v_TaskId
                                                     and col_DateClosed is null
                                              )
                     );
      exception
        when NO_DATA_FOUND then
          --IF NEXT REVIEW TASK NOT FOUND, THEN GET ID OF REVIEW CLOSE TASK FOR CASE
          begin
            select col_id
              into v_CloseTaskId
              from tbl_task
                where col_parentid = (select col_parentid
                                        from tbl_task
                                          where col_id = v_TaskId)
                  and col_dateclosed is null
                  and lower(col_systemtype2) = 'reviewclose';
              exception
                when NO_DATA_FOUND then
                  v_result := -1;
          end;
        when TOO_MANY_ROWS then
          v_result := -2;
  end;
  :NextReviewTaskId := v_NextReviewTaskId;
  :CloseTaskId := v_CloseTaskId;
end;
