declare
    v_workitemId number;
    v_containerId number;
    v_currentYear nvarchar2(4);
begin 

    insert into tbl_pi_workitem (
        col_code,
        col_name, 
        col_currmsactivity,
        col_pi_workitemdict_state, 
        col_pi_workitemppl_workbasket
    ) 
    values (
        :WorkitemCode,
        :WorkitemName,
        :CurrentActivity,
        :StateId,
        :WorkbasketId
    ) returning col_id into v_workitemId;

    v_currentYear := to_char(sysdate, 'YYYY');

    update tbl_pi_workitem set 
        col_title = 'DOC-' || v_currentYear || '-' || v_workitemId
    where col_id = v_workitemId;

    insert into tbl_container (
        col_code, 
        col_name,  
        col_containercontainertype,
        col_customdata
    ) 
    values (
        :ContainerCode,
        :ContainerName,
        :ContainerType,
        :CustomData
    ) returning col_id into v_containerId;
    
    :WorkitemId := v_workitemId;
    :ContainerId := v_containerId;
end;