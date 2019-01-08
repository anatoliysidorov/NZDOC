//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//system info
Boolean foundError = false;
const string ruleErrTpl = "ERROR: There was an error executing rule {0} exiting with code {1} => {2}";
List<String> ruleLog = new List<String>();
ruleLog.Add("==EVN_SendSMSviaTwilio==");

//input params
string v_CaseID = request.AsString("CaseId");
string v_TaskID = request.AsString("TaskId");
string v_SLAActionID = request.AsString("SlaActionId");

//calculated fields
string calcTargetType = String.Empty;
string calcTargetId = String.Empty;
if (!String.IsNullOrWhiteSpace(v_CaseID))
{
	calcTargetId = v_CaseID;
	calcTargetType = "case";
}
else if (!String.IsNullOrWhiteSpace(v_TaskID))
{
	calcTargetId = v_TaskID;
	calcTargetType = "task";
}
else if (!String.IsNullOrWhiteSpace(v_SLAActionID)) 
{
	ruleLog.Add("INFO: set as SLA Action context, converting to Task context");	
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
	try
	{
		Newtonsoft.Json.Linq.JToken taskRuleData = Newtonsoft.Json.Linq.JObject.Parse(taskRuleResult.Data.ToJson())["DATA"][getTaskIdRuleCode];
		calcTargetId = (string)taskRuleData.SelectToken("TASKID");
		calcTargetType = "task";
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

ruleLog.Add("INFO: set with context " + calcTargetType + " - " + calcTargetId);

//==EXECUTE SEND SMS RULE==       

const string ruleCode = "root_INT_SendSMSviaTwilio";

var ruleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetID", Value = calcTargetId });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetType", Value = calcTargetType });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "From", Value = request.AsString("From") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "FromRule", Value = request.AsString("FromRule") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "To", Value = request.AsString("To") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "ToRule", Value = request.AsString("ToRule") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Message", Value = request.AsString("Message") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "MessageCode", Value = request.AsString("MessageCode") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "MessageRule", Value = request.AsString("MessageRule") });

ruleLog.Add("INFO: Pushing to send rule");
var ruleResponse = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
{
	DataCommand = ruleCode,
	Domain = appDomain,
	Parameters = ruleParams,
	Token = token
});

//parse response
try
{
	Newtonsoft.Json.Linq.JToken sendRuleData = Newtonsoft.Json.Linq.JObject.Parse(ruleResponse.Data.ToJson())["DATA"][ruleCode];
	int sendConfig_ErrorCode = Convert.ToInt32((string)sendRuleData.SelectToken("ERRORCODE"));
	string sendConfig_Success = (string)sendRuleData.SelectToken("SUCCESSRESPONSE");

	//--catch rule error
	if (sendConfig_ErrorCode != 0)
	{
		foundError = true;
		ruleLog.Add(String.Format(ruleErrTpl, ruleCode, sendConfig_ErrorCode, (string)sendRuleData.SelectToken("ERRORMESSAGE")));
		goto Validation;
	}
	else
	{
		ruleLog.Add(sendConfig_Success);
	}

}
catch (Exception ex)
{
	foundError = true;
	ruleLog.Add("ERROR: " + ex.ToString());
	goto Validation;
}


Validation:
const string msgTpl = "<p><b>{0}:</b> {1}</p>";

//set response information
if (foundError)
{
	ruleLog.Add(String.Format(msgTpl, "Error Code", 101));

	response["ERRORCODE"] = 101;
	response["ERRORMESSAGE"] = String.Join(System.Environment.NewLine, ruleLog);
	response["SUCCESSRESPONSE"] = String.Empty;

	//history info
	var historyParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetType", Value = calcTargetType });
	historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetId", Value = calcTargetId });
	historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "MessageCode", Value = "GenericEventFailure" });
	historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "AdditionalInfo", Value = String.Join(System.Environment.NewLine, ruleLog) });
	var getFolderTreeRequest = ASF.CoreLib.APIHelper.BDSExecute(
		new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = "root_HIST_createHistory",
			Domain = appDomain,
			Parameters = historyParams,
			Token = token
		}
	);
}
else
{
	response["ERRORCODE"] = 0;
	response["ERRORMESSAGE"] = String.Empty;
	response["SUCCESSRESPONSE"] = String.Join(System.Environment.NewLine, ruleLog);
}

//------------------------------------End rule ------------------------------------