SELECT 
  map_pt.col_id as ID,
  map_pt.col_allowcreate as AllowCreate,
  map_pt.col_parentpartytype as ParentPartyType,
  map_pt.col_childpartytype as ChildPartyType,
  cpt.col_name as ChildPartyType_name
FROM tbl_ExternalParty ep
INNER JOIN tbl_map_partytype map_pt ON map_pt.COL_PARENTPARTYTYPE = ep.COL_EXTERNALPARTYPARTYTYPE
LEFT JOIN tbl_dict_partytype cpt ON cpt.col_id = map_pt.col_childpartytype
WHERE ep.col_id = :ExternalParty
<%=Sort("@SORT@","@DIR@")%>
