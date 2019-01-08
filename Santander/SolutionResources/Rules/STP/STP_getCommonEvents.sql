SELECT ce.col_id                                      AS Id,
       ce.col_code                                    AS Code,
       ce.col_name                                    AS NAME,
       ce.col_description                             AS Description,
       ce.col_eventorder                              AS EventOrder,
       ce.col_processorcode                           AS ProcessorCode,
       ce.col_comeventtmplcomeventtype                AS EventWhen_Id,
       dict_eventwhen.col_name                        AS EventWhen_Name,
       dict_eventwhen.col_code                        AS EventWhen_Code,
       ce.col_comevttmplevtmmnt                       AS EventMoment_Id,
       dict_eventmoment.col_name                      AS EventMoment_Name,
       dict_eventmoment.col_code                      AS EventMoment_Code,
       ce.col_comevttmplevtsynct                      AS EventSyncType_Id,
       ce.col_comevttmpltaskevtt                      AS EventType_Id,
       dict_eventtype.col_name                        AS EventType_Name,
       dict_eventtype.col_code                        AS EventType_Code,
       DBMS_XMLGEN.CONVERT (ce.col_customconfig)      AS CustomConfig,
       f_getnamefromaccesssubject (ce.col_createdby)  AS Createdby_Name,
       f_util_getdrtnfrmnow (ce.col_createddate)      AS CreatedDuration,
       f_getnamefromaccesssubject (ce.col_modifiedby) AS Modifiedby_Name,
       f_util_getdrtnfrmnow (ce.col_modifieddate)     AS ModifiedDuration

  FROM tbl_commoneventtmpl  ce
       LEFT JOIN tbl_dict_commoneventtype dict_eventwhen
           ON dict_eventwhen.col_id = ce.col_comeventtmplcomeventtype
       LEFT JOIN tbl_dict_taskeventmoment dict_eventmoment
           ON dict_eventmoment.col_id = ce.col_comevttmplevtmmnt
       LEFT JOIN tbl_dict_taskeventtype dict_eventtype
           ON dict_eventtype.col_id = ce.col_comevttmpltaskevtt

 WHERE     (:Id IS NULL OR ce.col_id = :Id)
       AND (   :CaseType_Id IS NULL
            OR ce.col_commoneventtmplcasetype = :CaseType_Id)
       AND (   :Procedure_Id IS NULL
            OR ce.col_commoneventtmplprocedure = :Procedure_Id)
       AND (   :TaskType_Id IS NULL
            OR ce.col_commoneventtmpltasktype = :TaskType_Id)

<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>