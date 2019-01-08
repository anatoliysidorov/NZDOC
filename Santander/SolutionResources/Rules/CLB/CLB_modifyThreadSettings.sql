declare
    v_id number;
begin 
    begin
        select col_id into  v_id
        from tbl_threadsetting
        where rownum = 1;
      exception
        when no_data_found then
            v_id := null;
    end;

    if(v_id is null) then
        insert into tbl_threadsetting(
            col_allowaddpeople,
            col_allowdeletecomment,
            col_alloweditcomment,
            col_allowjoindiscussion,
            col_allowleavediscussion,
            col_allowremovepeople,
            col_allowcommentdiscussion,
            col_allowcreatediscussion,
            col_allowdeletediscussion
        ) values (
            :ALLOWADDPEOPLE,
            :ALLOWDELETECOMMENT,
            :ALLOWEDITCOMMENT,
            :ALLOWJOINDISCUSSION,
            :ALLOWLEAVEDISCUSSION,
            :ALLOWREMOVEPEOPLE,
            :ALLOWCOMMENTDISCUSSION,
            :ALLOWCREATEDISCUSSION,
            :ALLOWDELETEDISCUSSION
        );
    else 
        update tbl_threadsetting set
            col_allowaddpeople = :ALLOWADDPEOPLE,
            col_allowdeletecomment = :ALLOWDELETECOMMENT,
            col_alloweditcomment = :ALLOWEDITCOMMENT,
            col_allowjoindiscussion =:ALLOWJOINDISCUSSION,
            col_allowleavediscussion = :ALLOWLEAVEDISCUSSION,
            col_allowremovepeople = :ALLOWREMOVEPEOPLE,
            col_allowcommentdiscussion = :ALLOWCOMMENTDISCUSSION,
            col_allowcreatediscussion = :ALLOWCREATEDISCUSSION,
            col_allowdeletediscussion = :ALLOWDELETEDISCUSSION
        where col_id = v_id;  
    end if;

    :SuccessResponse := 'Settings were successfully updated';
end;