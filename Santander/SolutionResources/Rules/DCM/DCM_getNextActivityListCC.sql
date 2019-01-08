select tskt.col_id as Id, tskts.col_activity as NextActivity
      from tbl_dict_tasktransition tskt
      inner join tbl_dict_taskstate tskss on tskt.col_sourcetasktranstaskstate = tskss.col_id
      inner join tbl_dict_taskstate tskts on tskt.col_targettasktranstaskstate = tskts.col_id
      inner join tbl_tw_workitemcc twi on tskss.col_id = twi.col_tw_workitemccdict_taskst
      inner join tbl_taskcc tsk on twi.col_id = tsk.col_tw_workitemcctaskcc
      where tsk.col_id = :TaskId