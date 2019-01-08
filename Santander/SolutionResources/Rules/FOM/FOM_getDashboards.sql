  SELECT Id,
         CaseworkerId,
         IsSystem,
         IsDeleted,
         Name,
         Code,
         DashboardOrder,
         Description,
         Config,
         ISIMPORTED,
         CreatedBy_Name,
         CreatedDuration,
         ModifiedBy_Name,
         ModifiedDuration,
         WidgetCount
    FROM (SELECT dbd.col_Id AS Id,
                 dbd.col_dashboardcaseworker AS CaseworkerId,
                 dbd.col_Name AS Name,
                 dbd.col_Code AS Code,
                 NVL(dbd_cw.COL_DASHBOARDORDER, 0) AS DashboardOrder,
                 NVL(dbd.col_isDeleted, 0) AS IsDeleted,
                 NVL(dbd.col_isSystem, 0) AS IsSystem,
                 dbd.col_Description AS Description,
                 dbd.col_Config AS Config,
                 (CASE WHEN dbd.COL_CREATEDBY = 'IMPORT' THEN 1 ELSE 0 END) AS ISIMPORTED,
                 f_getNameFromAccessSubject(dbd.col_createdBy) AS CreatedBy_Name,
                 f_UTIL_getDrtnFrmNow(dbd.col_createdDate) AS CreatedDuration,
                 f_getNameFromAccessSubject(dbd.col_modifiedBy) AS ModifiedBy_Name,
                 f_UTIL_getDrtnFrmNow(dbd.col_modifiedDate) AS ModifiedDuration,
                 NVL((SELECT COUNT(uiel.col_id)
                        FROM tbl_fom_uielement uiel
                       WHERE dbd.col_id = uiel.col_uielementdashboard),
                     0)
                    AS WidgetCount
            FROM    tbl_FOM_Dashboard dbd
                 LEFT JOIN
                    TBL_FOM_DASHBOARDCW dbd_cw
                 ON (dbd_cw.COL_DASHBOARD = dbd.col_id AND dbd_cw.COL_CASEWORKER = f_dcm_getcaseworkerId()))
   WHERE (CaseworkerId = f_dcm_getcaseworkerId() OR CaseworkerId IS NULL) AND (:DashboardId IS NULL OR (Id = :DashboardId))
         AND 1 =
                (CASE
                    WHEN :Expression IS NULL THEN 1
                    WHEN (:Expression = 1) AND (IsDeleted = 0) THEN 1
                    WHEN (:Expression = 2) AND ((IsDeleted = 0 AND IsSystem = 1) OR (IsSystem = 0)) THEN 1
                    WHEN (:Expression = 3) AND (IsSystem = 1) THEN 1
                    ELSE 0
                 END)
ORDER BY DashboardOrder DESC