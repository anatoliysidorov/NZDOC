DECLARE
v_graph nclob;
v_stateconfig NVARCHAR2(255);
BEGIN
v_graph := EMPTY_CLOB();
 v_stateconfig := TO_CHAR(NVL(:StateConfig_Id, 0));
 :Graph := '';
FOR REC IN(
select Col_Sourcecasetranscasestate Source, Col_Targetcasetranscasestate Target from Tbl_Dict_Casetransition
where 
Col_Sourcecasetranscasestate in(
  select col_id 
  from tbl_dict_casestate
  where NVL(Col_Stateconfigcasestate,0) = v_stateconfig)
AND
Col_Targetcasetranscasestate in(
  select col_id 
  from tbl_dict_casestate
  where NVL(Col_Stateconfigcasestate,0) = v_stateconfig)
 
)
LOOP
 v_graph := v_graph||'{'||rec.Source ||','||rec.Target||'},';
END LOOP;
v_graph := rtrim(v_graph,',');
--dbms_output.put_line(v_graph);
:Graph := v_graph;
END;