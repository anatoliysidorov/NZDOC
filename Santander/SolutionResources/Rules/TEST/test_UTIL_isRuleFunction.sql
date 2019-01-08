DECLARE 
        v_deployToFunction NUMERIC;
        v_Local_code NVARCHAR2(255);
BEGIN
   v_Local_code := :RuleLocalCode;
  
  SELECT nvl(r.ISNEEDDEPLOYFUNCTION, 0) INTO v_deployToFunction
  FROM vw_util_deployedrule r
  WHERE r.LocalCode = v_Local_code;
  RETURN v_deployToFunction;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
  RETURN 0;
END;