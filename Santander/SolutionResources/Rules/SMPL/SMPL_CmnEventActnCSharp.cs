// Rule Name: SMPL_CmnEventActnCSharp
// Rule Type: C#
// Input
//    Input,TextArea
// This should create a record in the System Log

//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//input params
string v_Input = request.AsString("Input");

//add history to the Task
var smplRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
smplRuleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Input", Value = v_Input });
var writeLogRequest = ASF.CoreLib.APIHelper.BDSExecute(
	new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_SMPL_CmnEventActn",
		Domain = appDomain,
		Parameters = smplRuleParams,
		Token = token
	}
);

//------------------------------------End rule ------------------------------------