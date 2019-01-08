// Rule Name: SMPL_MS_execRuleCSharp
// Rule Type: C#
// Input- CaseId, Integer
// Input- SomeNumber, Text
// Input- SomeText, Integer
// Input- v_StateSLAActionID, Integer (TBL_DICT_STATESLAACTION.col_id if executed from a Milestone SLA)
// This should create a history record viewable in the Case

//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//input params
string v_caseid = request.AsString("CaseId");
string v_StateSLAActionID = request.AsString("StateSLAActionId");
string v_SomeText = request.AsString("SomeText");
string v_SomeNumber = request.AsString("SomeNumber");

//add history to the Task
string message = "This is a C# rule for testing Milestone Events.";
if(!String.IsNullOrWhiteSpace(v_StateSLAActionID)){
	message += " Executed from an SLA.";
}
var historyParams = new ASF.Framework.Service.Parameters.ParameterCollection();
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetType", Value = "case" });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetID", Value = v_caseid });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Message", Value = message + " - " + v_SomeText + " - " + v_SomeNumber});
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "AdditionalInfo", Value = "This is a rule for testing Milestone Events"});
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