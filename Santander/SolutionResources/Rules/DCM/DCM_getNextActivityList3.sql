SELECT tskt.col_id AS Id, tskts.col_activity AS NextActivity
  FROM tbl_dict_tasktransition tskt
       INNER JOIN tbl_dict_taskstate tskss
          ON tskt.col_sourcetasktranstaskstate = tskss.col_id
       INNER JOIN tbl_dict_taskstate tskts
          ON tskt.col_targettasktranstaskstate = tskts.col_id
       INNER JOIN tbl_tw_workitem twi
          ON tskss.col_id = twi.col_tw_workitemdict_taskstate
       INNER JOIN tbl_task tsk
          ON twi.col_id = tsk.col_tw_workitemtask
       INNER JOIN tbl_case cs
          ON tsk.col_casetask = cs.col_id
       INNER JOIN tbl_map_taskstateinitiation mtsi
          ON tsk.col_id = mtsi.col_map_taskstateinittask AND tskts.col_id = mtsi.col_map_tskstinit_tskst
       INNER JOIN tbl_dict_initmethod dim
          ON mtsi.col_map_tskstinit_initmtd = dim.col_id
 WHERE tsk.col_id = :TaskId AND LOWER(dim.col_code) IN ('manual', 'automatic')