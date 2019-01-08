declare
  v_maxid Integer;
  v_seqid Integer;
  v_nextseqid Integer;
begin
  select max(col_id) into v_maxid from tbl_dateeventcc;
  select gen_tbl_dateeventcc.nextval into v_seqid from dual;
  if v_seqid < v_maxid then
    v_nextseqid := v_seqid;
    while v_nextseqid < v_maxid
    loop
      select gen_tbl_dateeventcc.nextval into v_nextseqid from dual;
    end loop;
  end if;
end;