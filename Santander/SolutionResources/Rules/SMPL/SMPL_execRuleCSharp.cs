// Rule Name: SMPL_execRuleCSharp
// Rule Type: C#
// Input- TaskId, Integer
// Input- SomeNumber, Text
// Input- SomeText, Integer
// Input- SlaActionId, Integer
// This should create a history record viewable both in the Task and the Case

//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//input params
string v_TaskId = request.AsString("TaskId");
string v_SLAActionID = request.AsString("SlaActionId");
string v_SomeText = request.AsString("SomeText");
string v_SomeNumber = request.AsString("SomeNumber");

if(String.IsNullOrWhiteSpace(v_TaskId) && !String.IsNullOrWhiteSpace(v_SLAActionID)){
	const string getTaskIdRuleCode = "root_DCM_getTaskIdBySLA";
	var taskRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	taskRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "SLAActionID",
		Value = v_SLAActionID
	});

	var taskRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = getTaskIdRuleCode,
		Domain = appDomain,
		Parameters = taskRuleParams,
		Token = token
	});

	//parse response
	Newtonsoft.Json.Linq.JToken taskRuleData = Newtonsoft.Json.Linq.JObject.Parse(taskRuleResult.Data.ToJson())["DATA"][getTaskIdRuleCode];
	v_TaskId = (string)taskRuleData.SelectToken("TASKID");	
}

//add history to the Task
var historyParams = new ASF.Framework.Service.Parameters.ParameterCollection();
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetType", Value = "task" });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetID", Value = v_TaskId });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Message", Value = "Executed C# rule SMPL_execRuleCSharp " + v_SomeText + " - " + v_SomeNumber});
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "AdditionalInfo", Value = "Ths is a rule for testing Workflow Events"});
var writeHistoryRequest = ASF.CoreLib.APIHelper.BDSExecute(
	new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_HIST_createHistory",
		Domain = appDomain,
		Parameters = historyParams,
		Token = token
	}
);

//------------------------------------End rule ------------------------------------