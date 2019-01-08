//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//system info
Boolean foundError = false;
const string ruleErrTpl = "ERROR: There was an error executing rule {0} exiting with code {1} => {2}";
List<String> ruleLog = new List<String>();
ruleLog.Add("==EVN_SendAdvancedEmail==");

//input params for TASK PROCEDURE
string v_CaseID = request.AsString("CaseId"); 
string v_TaskID = request.AsString("TaskId"); // for executing a normal event attached to a Task in Procedure
string v_SLAActionID = request.AsString("SlaActionId"); //for task SLAs

//input params for CASE  MILESTONES
string v_StateEventId = request.AsString("StateEventId"); 
string v_StateId = request.AsString("StateId"); 
string v_executionMoment = request.AsString("executionMoment"); 
string v_eventType = request.AsString("eventType"); 
string v_eventSubtype  = request.AsString("subtype"); 
string v_StateSLAActionID = request.AsString("StateSlaActionId"); //for case milestone SLAs

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


//==EXECUTE SEND EMAIL RULE==       

const string ruleCode = "root_LTR_SendAdvancedEmail";

var ruleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetID", Value = calcTargetId });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetType", Value = calcTargetType });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "To", Value = request.AsString("To") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "ToRule", Value = request.AsString("ToRule") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Cc", Value = request.AsString("Cc") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CcRule", Value = request.AsString("CcRule") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Bcc", Value = request.AsString("Bcc") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "BccRule", Value = request.AsString("BccRule") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "From", Value = request.AsString("From") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "FromRule", Value = request.AsString("FromRule") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "AttachmentsRule", Value = request.AsString("AttachmentsRule") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Template", Value = request.AsString("Template") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TemplateRule", Value = request.AsString("TemplateRule") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Body", Value = request.AsString("Body") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "DistributionChannel", Value = request.AsString("DistributionChannel") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Subject", Value = request.AsString("Subject") });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Subject_Rule", Value = request.AsString("Subject_Rule") });

ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "SlaActionId", Value = v_SLAActionID });
ruleParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "StateSlaActionId", Value = v_StateSLAActionID });


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
	ruleLog.Add(String.Format(msgTpl, "Error Code", 301));

	response["ERRORCODE"] = 301;
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