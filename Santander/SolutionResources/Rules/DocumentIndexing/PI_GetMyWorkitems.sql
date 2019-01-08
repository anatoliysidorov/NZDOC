declare
  v_workbasketId     NUMBER;
  v_searchCode       NVARCHAR2(255);
  v_selectClause     VARCHAR2(32767);
  v_selectClause2    VARCHAR2(32767);
  v_fromClause       VARCHAR2(32767);
  v_countClause      VARCHAR2(32767);
  v_sortClause       VARCHAR2(32767);
  v_sortSelectClause VARCHAR2(32767);
  v_pageWhereClause  VARCHAR2(32767);
  v_countQuery       VARCHAR2(32767);
  v_mainQuery        VARCHAR2(32767);
  v_LIMIT            NUMBER;
  v_START            NUMBER;
  v_sort             NVARCHAR2(255);
  v_dir              NVARCHAR2(255);
  v_id               NUMBER;
  v_workitemId       NUMBER;
  v_name             NVARCHAR2(255);
  v_title            NVARCHAR2(255);
  v_sourceType       NUMBER;
  v_createdStart     DATE;
  v_createdEnd       DATE;
  v_stateConfigId    NUMBER;
  v_stateCode        NVARCHAR2(255);
  v_stateId          NUMBER;
  v_result           number;
  v_ErrorCode        number;
  v_ErrorMessage     nvarchar2(255);
  v_ITEMS            sys_refcursor;
  v_TotalCount       number;
begin
  v_workbasketId := :workbasketId;
  v_searchCode   := :searchCode;
  v_stateCode    := :stateCode;
  v_dir          := :DIR;
  v_sort         := :SORT;
  v_LIMIT        := :LIMIT;
  v_START        := :FIRST;

  -- search fields
  v_id           := :Id;
  v_name         := :NAME;
  v_title        := :Title;
  v_sourceType   := :sourceType;
  v_createdStart := :createdStart;
  v_createdEnd   := :createdEnd;
  v_workitemId   := :WorkitemId;

  IF (v_searchCode IS NULL) THEN
    v_searchCode := 'ALL';
  END IF;
  IF nvl(v_LIMIT, 0) = 0 THEN
    v_LIMIT := 10;
  END IF;
  IF v_START IS NULL THEN
    v_START := 0;
  END IF;

  IF (v_dir IS NULL) THEN
    v_dir := 'ASC';
  END IF;
  IF (v_sort IS NULL) THEN
    v_sort := 'ID';
  END IF;

  v_result := f_PI_getMyWorkitemsFn(createdEnd => v_createdEnd, createdStart => v_createdStart, DIR => v_dir, ErrorCode => v_ErrorCode, ErrorMessage => v_ErrorMessage,
                                    FIRST => v_START, Id => v_id, ITEMS => v_ITEMS, LIMIT => v_LIMIT, NAME => v_name, searchCode => v_searchCode, SORT => v_sort,
                                    sourceType => v_sourceType, StateCode => v_stateCode, Title => v_title, TotalCount => v_TotalCount, workbasketId => v_workbasketId, WorkitemId => v_workitemId);

  :ErrorCode := v_ErrorCode;
  :ErrorMessage := v_ErrorMessage;
  :TotalCount := v_TotalCount;
  :ITEMS := v_ITEMS;
end;