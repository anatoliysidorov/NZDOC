BEGIN 
    IF Lower(:TargetType) = 'case' THEN 
      RETURN F_dcm_iscaseincache(:TargetId); 
    ELSIF Lower(:TargetType) = 'task' THEN 
      RETURN F_dcm_istaskincache(:TargetId); 
    ELSE 
      RETURN 0; 
    END IF; 
END; 