select     nexttaskid,
           nextslaseconds,
           nextrownumber,
           prevtaskid,
           prevslaseconds,
           prevrownumber
from      (select nexttaskid,
                   nextcaseid,
                   nextslaseconds,
                   nextrownumber
           from   (select  nexttaskid,
                            nextcaseid,
                            (nextslaseconds + nextslaminutes * 60 + nextslahours * 60 * 60 + nextsladays * 24 * 60 * 60) as nextslaseconds,
                            row_number() over(order by(nextslaseconds + nextslaminutes * 60 + nextslahours * 60 * 60 + nextsladays * 24 * 60 * 60)) as nextrownumber
                   from     vw_dcm_taskslaevent6
                   where    nextcaseid = :CaseId)
           where   nextrownumber = 1) s1
inner join(select prevtaskid,
                   prevcaseid,
                   prevslaseconds,
                   prevrownumber
           from   (select  prevtaskid,
                            prevcaseid,
                            (prevslaseconds + prevslaminutes * 60 + prevslahours * 60 * 60 + prevsladays * 24 * 60 * 60) as prevslaseconds,
                            row_number() over(order by(prevslaseconds + prevslaminutes * 60 + prevslahours * 60 * 60 + prevsladays * 24 * 60 * 60)) as prevrownumber
                   from     vw_dcm_taskslaevent6
                   where    prevcaseid = :CaseId)
           where   prevrownumber = 1) s2 on s1.nextcaseid = s2.prevcaseid