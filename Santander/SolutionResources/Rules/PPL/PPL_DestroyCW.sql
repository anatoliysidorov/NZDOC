DECLARE
v_userid number;
v_errorCode number;
v_errorMessage nvarchar2(255);

BEGIN
v_userid := :UserId;
v_errorCode := 0;
v_errorMessage := '';

IF v_userid IS NULL THEN
  v_errorCode := 121;
  v_errorMessage := 'UserId must not be empty';
  goto cleanup;
END IF;

delete from Tbl_Ac_Accesssubject
where col_id in (
select col_caseworkeraccesssubject  from Tbl_ppl_caseworker where col_userid  = v_userid);

delete from Tbl_Ppl_Workbasket
where COL_CASEWORKERWORKBASKET in (
select col_id  from Tbl_ppl_caseworker where col_userid  = v_userid);

delete from Tbl_Ppl_Caseworker where col_userid = v_userid;

<<cleanup>>
:ErrorCode := v_errorCode;
:ErrorMessage := V_Errormessage;
END;