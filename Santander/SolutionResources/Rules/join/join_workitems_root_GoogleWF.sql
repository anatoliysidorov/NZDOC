BEGIN
  DECLARE
        v_InstanceId NVARCHAR2(255);
        v_WorkflowCode NVARCHAR2(255);
        v_ActivityCode NVARCHAR2(255);
        v_AccessSubjectCode NVARCHAR2(255);

	v_SplitActivityCode NVARCHAR2(255);
        v_RefParentId NUMBER;
        v_ParentActivityCode NVARCHAR2(255);
        v_SiblingCount NUMBER;
        v_SiblingArrived NUMBER;
  BEGIN	
      :ErrorCode := 0;
      :ErrorMessage := '';

      v_InstanceId := :InstanceId;
      v_WorkflowCode := :WorkflowCode;
      v_ActivityCode := :ActivityCode;
      v_AccessSubjectCode := :AccessSubjectCode;

      -- Get split activity corresponding to current activity, if any
      v_SplitActivityCode := NULL;
      BEGIN
          SELECT a2.Code INTO v_SplitActivityCode
          FROM
          @TOKEN_SYSTEMDOMAINUSER@.WF_WORKFLOW w INNER JOIN
          @TOKEN_SYSTEMDOMAINUSER@.WF_ACTIVITY a1 ON (a1.WorkflowId = w.WorkflowId) LEFT JOIN
          @TOKEN_SYSTEMDOMAINUSER@.WF_ACTIVITY a2 ON (a1.LINKSPLITACTIVITYID = a2.ACTIVITYID AND a2.WorkflowId = w.WorkflowId)
          WHERE w.EnvId = '@TOKEN_DOMAIN@' AND a1.Code = v_ActivityCode;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
          v_SplitActivityCode := NULL;
      END;

      IF v_SplitActivityCode IS NULL THEN
         RETURN;
      END IF;

      -- Detect if instance if sub-instance
      SELECT w.COL_REFPARENTID INTO v_RefParentId
      FROM TBL_CW_WORKITEM w 
      WHERE w.COL_INSTANCEID = v_InstanceId;

      IF (v_RefParentId IS NOT NULL) THEN
          -- Check if parent instance is in v_SplitActivityCode activity
          v_ParentActivityCode := NULL;
          BEGIN
             SELECT w.COL_ACTIVITY INTO v_ParentActivityCode
             FROM TBL_CW_WORKITEM w WHERE w.COL_ID = v_RefParentId;
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                   v_ParentActivityCode := NULL;
                RETURN;
          END;

          -- If yes, it's, sibling
          IF (v_ParentActivityCode IS NULL) THEN
              :ErrorCode := 102;
              :ErrorMessage := 'Inconsitent state in parent instance: activity not defined';
              RETURN;
          END IF;

          -- If not, go ahead
          IF (v_ParentActivityCode <> v_SplitActivityCode) THEN
              :ErrorCode := 103;
              :ErrorMessage := 'Inconsitent state in parent instance: activity not correspond to split';
              RETURN;
          END IF;

          -- Here v_RefParentId contains id of parent workitem, if all its children are in JOIN activity, return true
	  SELECT COUNT(*) AS cnt, SUM(CASE WHEN w.COL_ACTIVITY = v_ActivityCode THEN 1 ELSE 0 END) AS sum
          INTO v_SiblingCount, v_SiblingArrived
          FROM TBL_CW_WORKITEM w WHERE w.COL_REFPARENTID = v_RefParentId;
          
          IF (v_SiblingCount = 0) THEN
              :ErrorCode := 104;
              :ErrorMessage := 'Inconsitent state in parent instance: no activity found for parent';
              RETURN;
          END IF;

          IF (v_SiblingCount <> v_SiblingArrived) THEN
              :ErrorCode := 105;
              :ErrorMessage := 'Inconsitent state in parent instance: some siblings did not arrive';
              RETURN;
          END IF;

          -- Remove child records, restore state
          DELETE FROM TBL_CW_WORKITEM WHERE COL_REFPARENTID = v_RefParentId;
          UPDATE TBL_CW_WORKITEM SET 
                COL_INSTANCETYPE = 1,
		COL_WORKFLOW = v_WorkflowCode,
		COL_ACTIVITY = v_ActivityCode,
		COL_OWNER = v_AccessSubjectCode,
		COL_MODIFIEDBY = '@TOKEN_USERACCESSSUBJECT@',
		COL_MODIFIEDDATE = sysdate,
                COL_PREVACTIVITY = v_SplitActivityCode
		WHERE COL_ID = v_RefParentId;
      ELSE
          :ErrorCode := 106;
          :ErrorMessage := 'Inconsitent state in parent instance: not found';
      END IF;
  EXCEPTION
          WHEN OTHERS THEN
  	      :ErrorCode := 100;
              :ErrorMessage := SUBSTR(SQLERRM, 1, 200);
  END;
END;