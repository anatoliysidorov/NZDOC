declare
  -- idx number;
begin
--select GEN_TBL_LOG.nextval into idx from dual;
insert into tbl_log (col_data1)values('NFS_Domain - ' || :NFS_Domain);
insert into tbl_log (col_data1)values('NFS_Code - ' || :NFS_Code);
insert into tbl_log (col_data1)values('NFS_ModifiedBy - ' || :NFS_ModifiedBy);
end;