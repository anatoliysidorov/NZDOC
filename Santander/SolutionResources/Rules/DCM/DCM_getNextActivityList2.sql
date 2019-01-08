select tskt.col_id as Id, tskts.col_activity as NextActivity
      from tbl_dict_tasktransition tskt
      inner join tbl_dict_taskstate tskss on tskt.col_sourcetasktranstaskstate = tskss.col_id
      inner join tbl_dict_taskstate tskts on tskt.col_targettasktranstaskstate = tskts.col_id
      inner join tbl_tw_workitem twi on tskss.col_id = twi.col_tw_workitemdict_taskstate
      inner join tbl_task tsk on twi.col_id = tsk.col_tw_workitemtask
      where tsk.col_id = :TaskId