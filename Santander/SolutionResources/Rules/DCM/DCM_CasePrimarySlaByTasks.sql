select   nexttaskid,
           nextcaseid,
           nextslaseconds,
           nextrownumber,
           lasttaskid,
           lastcaseid,
           lastslaseconds,
           lastrownumber,
           prevtaskid,
           prevcaseid,
           prevslaseconds,
           prevrownumber,
           firsttaskid,
           firstcaseid,
           firstslaseconds,
           firstrownumber
from
(select nexttaskid,
           nextcaseid,
           nextslaseconds,
           nextrownumber
from (select nexttaskid,
                  nextcaseid,
                  (nextslaseconds + nextslaminutes * 60 + nextslahours * 60 * 60 + nextsladays * 24 * 60 * 60) as nextslaseconds,
                            row_number() over(partition by nextcaseid order by(nextslaseconds + nextslaminutes * 60 + nextslahours * 60 * 60 + nextsladays * 24 * 60 * 60)) as nextrownumber
                   from vw_dcm_taskslaprimaryevent6
                   where (nextslaseconds + nextslaminutes * 60 + nextslahours * 60 * 60 + nextsladays * 24 * 60 * 60) > 0)
           where nextrownumber = 1) s1
inner join
(select lasttaskid,
           lastcaseid,
           lastslaseconds,
           lastrownumber
from (select nexttaskid as lasttaskid,
                  nextcaseid as lastcaseid,
                  (nextslaseconds + nextslaminutes * 60 + nextslahours * 60 * 60 + nextsladays * 24 * 60 * 60) as lastslaseconds,
                            row_number() over(partition by nextcaseid order by(nextslaseconds + nextslaminutes * 60 + nextslahours * 60 * 60 + nextsladays * 24 * 60 * 60) desc) as lastrownumber
                   from vw_dcm_taskslaprimaryevent6
                   where (nextslaseconds + nextslaminutes * 60 + nextslahours * 60 * 60 + nextsladays * 24 * 60 * 60) > 0)
           where lastrownumber = 1) s3 on s1.nextcaseid = s3.lastcaseid
left join
(select  prevtaskid,
            prevcaseid,
            prevslaseconds,
            prevrownumber
from (select prevtaskid,
                  prevcaseid,
                  (prevslaseconds + prevslaminutes * 60 + prevslahours * 60 * 60 + prevsladays * 24 * 60 * 60) as prevslaseconds,
                            row_number() over(partition by prevcaseid order by(prevslaseconds + prevslaminutes * 60 + prevslahours * 60 * 60 + prevsladays * 24 * 60 * 60)) as prevrownumber
                   from vw_dcm_taskslaprimaryevent6
                   where (prevslaseconds + prevslaminutes * 60 + prevslahours * 60 * 60 + prevsladays * 24 * 60 * 60) > 0)
           where prevrownumber = 1) s2 on s1.nextcaseid = s2.prevcaseid
left join
(select  firsttaskid,
            firstcaseid,
            firstslaseconds,
            firstrownumber
from (select prevtaskid as firsttaskid,
                  prevcaseid as firstcaseid,
                  (prevslaseconds + prevslaminutes * 60 + prevslahours * 60 * 60 + prevsladays * 24 * 60 * 60) as firstslaseconds,
                            row_number() over(partition by prevcaseid order by(prevslaseconds + prevslaminutes * 60 + prevslahours * 60 * 60 + prevsladays * 24 * 60 * 60) desc) as firstrownumber
                   from vw_dcm_taskslaprimaryevent6
                   where (prevslaseconds + prevslaminutes * 60 + prevslahours * 60 * 60 + prevsladays * 24 * 60 * 60) > 0)
           where firstrownumber = 1) s4 on s2.prevcaseid = s4.firstcaseid