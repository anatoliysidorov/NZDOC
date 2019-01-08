BEGIN
    --get all task state machines
    OPEN :CUR_TASKSTATECONFIGS FOR
    SELECT COL_ID as ID,
           COL_CODE as CODE,
           COL_NAME as NAME,
           COL_ICONCODE as ICONCODE,
           COL_ISCURRENT as ISCURRENT,
           COL_ISDEFAULT as ISDEFAULT,
           COL_ISDELETED as ISDELETED,
           COL_REVISION as REVISION,
           COL_TYPE as TYPE
    FROM   TBL_DICT_STATECONFIG
    WHERE  lower(COL_TYPE) = lower('task');
    
    --get all task states
    OPEN :CUR_TASKSTATES FOR
    SELECT COL_ID as ID,
           COL_NAME as NAME,
           COL_CODE as CODE,
           COL_STATECONFIGTASKSTATE as STATECONFIG_ID,
           COL_DEFAULTORDER as DEFAULTORDER,
           COL_ICONCODE as ICONCODE,
           COL_ISASSIGN as ISASSIGN,
           COL_ISDEFAULTONCREATE as ISDEFAULTONCREATE,
           COL_ISDEFAULTONCREATE as ISDEFAULTONCREATE2,
           COL_ISDELETED as ISDELETED,
           COL_ISFINISH as ISFINISH,
		   COL_ISHIDDEN as ISHIDDEN,
           COL_ISRESOLVE as ISRESOLVE,
           COL_ISSTART as ISSTART,
           COL_UCODE as UCODE
    FROM   TBL_DICT_TASKSTATE;
    
    --get all task state setups
    OPEN :CUR_TASKSTATESETUPS FOR
    SELECT COL_ID as ID,
           COL_CODE as CODE,
           COL_NAME as NAME,
           COL_FORCEDNULL as FORCEDNULL,
           COL_FORCEDOVERWRITE as FORCEDOVERWRITE,
           COL_NOTNULLOVERWRITE as NOTNULLOVERWRITE,
           COL_NULLOVERWRITE as NULLOVERWRITE,
           COL_TASKSTATESETUPTASKSTATE as TASKSTATE_ID
    FROM   TBL_DICT_TASKSTATESETUP;
    
    --get all task transitions
    OPEN :CUR_TASKTRANSITIONS FOR
    SELECT COL_CODE as CODE,
           COL_ID as ID,
           COL_ICONCODE as ICONCODE,
           COL_NAME as NAME,
           COL_SOURCETASKTRANSTASKSTATE as SOURCETASKTRANSTASKSTATE,
           COL_TARGETTASKTRANSTASKSTATE as TARGETTASKTRANSTASKSTATE,
           COL_TRANSITION as TRANSITION,
           COL_UCODE as UCODE,
		   COL_MANUALONLY as MANUALONLY
    FROM   TBL_DICT_TASKTRANSITION;
	
	--get all task state events
	OPEN :CUR_TASKSTATEEVENTS FOR
	SELECT
		ts.COL_ID as ID,
		ts.COL_TSKST_DTEVTPTASKSTATE as TASKSTATE_ID,
		det.COL_NAME as DET_NAME,
		det.COL_CODE as DET_CODE,
		det.COL_TYPE as DET_TYPE,
		det.COL_CANOVERWRITE as DET_CANOVERWRITE,
		det.COL_ISCASEMAINFLAG as DET_ISCASEMAINFLAG,
		det.COL_ISDELETED as DET_ISDELETED,
		det.COL_ISSLAEND as DET_ISSLAEND,
		det.COL_ISSLASTART as DET_ISSLASTART,
		det.COL_ISSTATE as DET_ISSTATE,
		det.COL_MULTIPLEALLOWED as DET_MULTIPLEALLOWED
	FROM TBL_DICT_TSKST_DTEVTP ts
	LEFT JOIN TBL_DICT_DATEEVENTTYPE det ON det.col_id = ts.COL_TSKST_DTEVTPDATEEVENTTYPE;

END;