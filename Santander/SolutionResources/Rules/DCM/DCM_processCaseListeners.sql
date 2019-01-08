declare
  v_validationresult number;
  v_CaseId Integer;
  v_result number;
begin
  v_CaseId := :CaseId;
  for rec in
    (select cd.col_casedpndchldcasestateinit as CaseStateInitId, csi.col_map_casestateinitcase as CaseId, lst.col_processorcode as ListenerProcessor
      from tbl_casedependency cd
      inner join tbl_map_casestateinitiation csi on cd.col_casedpndchldcasestateinit = csi.col_id
      inner join tbl_globalevent ge on cd.col_casedependencyglobalevent = ge.col_id
      inner join tbl_listener lst on ge.col_id = lst.col_listenerglobalevent
      where csi.col_map_casestateinitcase = v_CaseId)
  loop
    v_result := f_DCM_invokeCaseEventProc(CaseId => v_CaseId, ProcessorName => rec.ListenerProcessor, validationresult => v_validationresult);
  end loop;
end;