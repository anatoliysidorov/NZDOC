SELECT
	pt.col_ID as Id,  
	pt.col_Code as Code,
	pt.col_Name as Name,
	pt.col_Description as Description,
        pt.col_isDeleted as IsDeleted,
        pctt.col_Code as ParticipantCode,
        pctt.col_Name as ParticipantName	

FROM TBL_DICT_PartyType pt
INNER JOIN TBL_DICT_ParticipantType pctt ON pctt.col_Id = pt.col_PartyTypeParticipType
WHERE  pt.col_Id = :Id 
