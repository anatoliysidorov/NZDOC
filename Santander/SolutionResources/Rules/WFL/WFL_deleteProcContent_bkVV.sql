declare
  v_procedureid Integer;
begin
  v_procedureid := :ProcedureId;

  delete from tbl_taskevent
  where col_taskeventtaskstateinit in
    (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittasktmpl in
      (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid));

  delete from tbl_autoruleparameter
  where col_taskeventautoruleparam in
    (select col_id from tbl_taskevent
     where col_taskeventtaskstateinit in
       (select col_id from tbl_map_taskstateinitiation where col_map_taskstateinittasktmpl in
         (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid)));

  delete from tbl_autoruleparameter
  where col_autoruleparamtaskdep in
   (select col_id from tbl_taskdependency
    where col_tskdpndchldtskstateinit in
     (select col_id from tbl_map_taskstateinitiation
      where col_map_taskstateinittasktmpl in
       (select col_id from tbl_tasktemplate
        where col_proceduretasktemplate = v_procedureid))
  and col_tskdpndprnttskstateinit in
   (select col_id from tbl_map_taskstateinitiation
    where col_map_taskstateinittasktmpl in
     (select col_id from tbl_tasktemplate
      where col_proceduretasktemplate = v_procedureid)));

  delete from tbl_taskdependency
  where col_tskdpndchldtskstateinit in
   (select col_id from tbl_map_taskstateinitiation
    where col_map_taskstateinittasktmpl in
     (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid));

  delete from tbl_map_taskstateinitiation
  where col_map_taskstateinittasktmpl in
   (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid);

  delete from tbl_slaaction
  where col_slaactionslaevent in
    (select col_id from tbl_slaevent
     where col_slaeventtasktemplate in
       (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid));

  delete from tbl_slaevent
  where col_slaeventtasktemplate in
    (select col_id from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid);

  delete from tbl_tasktemplate where col_proceduretasktemplate = v_procedureid and lower(nvl(col_name,'No Name')) <> 'root';

end;