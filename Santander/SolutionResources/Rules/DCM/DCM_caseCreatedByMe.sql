declare
    v_result number; 
    v_caseid Integer; 
begin 
    v_caseid := :caseId;

    begin
      select Count(*)
        into   v_result 
      from tbl_case
      where	col_id = v_caseid
      and col_createdbY = sys_context('CLIENTCONTEXT', 'AccessSubject');
    exception 
      when NO_DATA_FOUND then
          v_result := 0;
    end; 


    return case
      when v_result > 0 then 1
      else 0
   end;
end;