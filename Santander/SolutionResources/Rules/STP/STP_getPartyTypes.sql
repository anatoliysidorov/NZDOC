SELECT pt.col_id AS id,
       pt.col_code AS code,
       pt.col_name AS name,
       pt.col_description AS description,
       pt.col_isdeleted AS isdeleted,
       pt.col_issystem AS issystem,
       pt.col_partytypeparticiptype AS participantid,
       pt.col_retcustdataprocessor AS retcustdataprocessor,
       pt.col_updatecustdataprocessor AS updatecustdataprocessor,
       pt.col_customdataprocessor AS customdataprocessor,
       pt.col_delcustdataprocessor AS delcustdataprocessor,
       pt.col_disablemanagement AS disablemanagement,
       pctt.col_code AS participantcode,
       pctt.col_name AS participantname,
      ( 
                 SELECT     list_collect(cast(collect(To_char(cspt.col_name) order BY to_char(cspt.col_name)) AS split_tbl),'|||',1) AS ids
                 FROM       tbl_dict_partytype spt 
                 inner join tbl_map_partytype ctspt 
                 ON         spt.col_id = ctspt.col_parentpartytype 
                 left join  tbl_dict_partytype cspt 
                 ON         cspt.col_id = ctspt.col_childpartytype 
                 WHERE      ctspt.col_parentpartytype = pt.col_id ) subpartytypes_names, 
      ( 
                 SELECT     list_collect(cast(collect(to_char(ctspt.col_childpartytype) ORDER BY to_char(ctspt.col_childpartytype)) AS split_tbl),'|||',1) AS ids
                 FROM       tbl_dict_partytype spt 
                 inner join tbl_map_partytype ctspt 
                 ON         spt.col_id = ctspt.col_parentpartytype 
                 WHERE      ctspt.col_parentpartytype = pt.col_id ) subpartytypes,        
       -------------------------------------------
       f_getNameFromAccessSubject (pt.col_createdBy) AS CreatedBy_Name,
       f_UTIL_getDrtnFrmNow (pt.col_createdDate) AS CreatedDuration,
       f_getNameFromAccessSubject (pt.col_modifiedBy) AS ModifiedBy_Name,
       f_UTIL_getDrtnFrmNow (pt.col_modifiedDate) AS ModifiedDuration
  FROM    tbl_dict_partytype pt
       LEFT JOIN
          tbl_dict_participanttype pctt
       ON pctt.col_id = pt.col_partytypeparticiptype
 WHERE (:PartyType_Id IS NULL OR pt.col_id = :PartyType_Id)
       AND (:ParticipantType_Code IS NULL OR LOWER (:ParticipantType_Code) = LOWER (pctt.col_code))
       AND (:PartyType_Code IS NULL OR LOWER (pt.col_code) = LOWER (:PartyType_Code))
       AND (:IsDeleted IS NULL OR NVL (pt.col_isdeleted, 0) = :IsDeleted)
       AND (:IsDisabledManagement IS NULL OR NVL (pt.col_disablemanagement, 0) = :IsDisabledManagement)
<%=IfNotNull("@SORT@", " ORDER BY @SORT@ @DIR@, 1")%>