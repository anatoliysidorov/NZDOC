SELECT tt.col_id AS Id,
       tt.col_deadline AS Deadline,
       tt.col_goal AS Goal,
       tt.col_icon AS Icon,
       tt.col_icon AS IconName,
       tt.col_leaf AS Leaf,
       tt.col_maxallowed AS MaxAllowed,
       tt.col_name AS Name,
       tt.col_required AS Required,
       tt.col_taskorder AS TaskOrder,
       tt.col_tasktmpldict_tasksystype AS TaskSysType_Id,
       tt.col_createddate AS CreatedDate,
       tt.col_createdby AS CreatedBy,
       tt.col_processorcode AS ProcessorCode,
       tt.col_modifieddate AS ModifiedDate,
       tt.col_modifiedby AS ModifiedBy,
       tst.col_name AS TaskSysType_Name,
       tst.col_code AS TaskSysType_Code,
       tst.col_pagecode AS TaskSysType_PageCode,
       em.col_code AS ExecutionMethod_Code,
       em.col_name AS ExecutionMethod_Name,
       F_util_ttdependencies(tsi_START.col_id) AS STARTED_Dependencies_CSV,
       tt.col_parentttid AS ParentId,
       tt.col_parentttid AS CalcParentId,                                                                                            -- for TreeReader
       tsi_START.col_id AS TaskStateInit_Started_Id,
       initM_START.col_id AS Started_initMethod_Id,
       initM_START.col_code AS Started_initMethod_Code,
       initM_START.col_name AS Started_initMethod_Name,
       initM_START.col_description AS Started_initMethod_Description,
       tsi_CLOSE.col_id AS TaskStateInit_Closed_Id,
       initM_CLOSE.col_id AS Closed_initMethod_Id,
       initM_CLOSE.col_code AS Closed_initMethod_Code,
       --CALCULATED
       tst.col_iconCode AS CALC_ICON,
       f_getNameFromAccessSubject(tt.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow(tt.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject(tt.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow(tt.col_modifiedDate) AS ModifiedDuration       
  FROM tbl_tasktemplate tt
       LEFT JOIN tbl_map_taskstateinitiation tsi_START
          ON tt.col_id = tsi_START.col_map_taskstateinittasktmpl AND tsi_START.col_map_tskstinit_tskst = F_util_gettaskstateidbycode('STARTED')
       LEFT JOIN tbl_dict_initmethod initM_START
          ON initM_START.col_id = tsi_START.col_map_tskstinit_initmtd
       LEFT JOIN tbl_map_taskstateinitiation tsi_CLOSE
          ON tt.col_id = tsi_CLOSE.col_map_taskstateinittasktmpl AND tsi_CLOSE.col_map_tskstinit_tskst = F_util_gettaskstateidbycode('CLOSED')
       LEFT JOIN tbl_dict_initmethod initM_CLOSE
          ON initM_CLOSE.col_id = tsi_CLOSE.col_map_tskstinit_initmtd
       LEFT JOIN tbl_dict_tasksystype tst
          ON tst.col_id = tt.col_tasktmpldict_tasksystype
       LEFT JOIN tbl_dict_executionmethod em
          ON em.col_id = tt.col_execmethodtasktemplate
 WHERE tt.col_proceduretasktemplate = :Procedure
<%=Sort("@SORT@","@DIR@")%>