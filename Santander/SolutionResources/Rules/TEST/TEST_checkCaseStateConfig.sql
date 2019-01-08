DECLARE

v_result number;
v_errorCode number;
v_errorMessage nclob;
BEGIN

v_errorCode := 0;
v_errorMessage := '';

:ErrorCode := v_errorCode;
:ErrorMessage := v_errorMessage;

for rec in (select NVL(cs.Col_Stateconfigcasestate,0) StateMachine, NVL(max(cs.col_isstart),0) IsStartNum
from tbl_dict_casestate cs
inner join tbl_dict_stateconfig sc on Cs.Col_Stateconfigcasestate = sc.col_id and lower(sc.col_type) = 'case'
group by cs.Col_Stateconfigcasestate, NVL(cs.Col_Stateconfigcasestate,0))
loop
  if rec.IsStartNum <> 1 then
    IF v_errorCode <> 122 THEN
    	v_errorCode := 122;
    END IF;
    v_errorMessage := v_errorMessage ||'<li>'||'State machine '||rec.statemachine||' does not have no flag <b>IsStart</b> set'||'</li>';
  end if;
end loop;

:ErrorCode := v_errorCode;
:ErrorMessage := v_errorMessage;

END;