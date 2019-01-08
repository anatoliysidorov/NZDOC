//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//system info
bool foundError = false;
const string ruleErrTpl = "ERROR: There was an error executing rule {0} exiting with code {1} => {2}";
List<String> ruleLog = new List<String>();
ruleLog.Add("==INT_sendToPureEngage==");
string internalInteractonId = Guid.NewGuid().ToString();

//input params
string v_targetId = request.AsString("TargetID");
string v_TargetType = request.AsString("TargetType");
string v_CustomData_Rule = request.AsString("CustomDataRule");
string v_PageSend1 = request.AsString("PageSend1").ToLower();
string v_PageSend1_ParamRule = request.AsString("PageSendParamsRule1");
string v_PageSend2 = request.AsString("PageSend2").ToLower();
string v_PageSend2_ParamRule = request.AsString("PageSendParamsRule2");
string v_channel = request.AsString("IntegrationChannel");            

//==GET GENESYS CONFIGURATION FROM DB==
Boolean StopSend = false;
int isDisabled = 0;


const string configRuleCode = "root_INT_getSingleConfig";
var configRuleParams = new ParameterCollection();
configRuleParams.AddParameter(new Parameter
{
	Type = ParameterType.Text(),
	Name = "CODE",
	Value = "GENESYS"
});

var configRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
{
	DataCommand = configRuleCode,
	Domain = appDomain,
	Parameters = configRuleParams,
	Token = token
});

//parse response
try
{
	ruleLog.Add("INFO: Getting Genesys configuration");
	Newtonsoft.Json.Linq.JToken configRuleData = Newtonsoft.Json.Linq.JObject.Parse(configRuleResult.Data.ToJson())["DATA"][configRuleCode];
	isDisabled = Convert.ToInt32((string)configRuleData.SelectToken("ISDISABLED"));
	int configConfig_ErrorCode = Convert.ToInt32((string)configRuleData.SelectToken("ERRORCODE"));
	string configConfig_Config = (string)configRuleData.SelectToken("CONFIG");

	//--catch rule error
	if (configConfig_ErrorCode != 0)
	{
		foundError = true;
		ruleLog.Add(String.Format(ruleErrTpl, configRuleCode, configConfig_ErrorCode, (string)configRuleData.SelectToken("ERRORMESSAGE")));
		goto Validation;
	}

	//--parse config
	if (!string.IsNullOrWhiteSpace(configConfig_Config))
	{
		XmlDocument configConfig_XML = new XmlDocument();
		configConfig_XML.LoadXml(configConfig_Config);
	}
	else
	{
		foundError = true;
		ruleLog.Add("ERROR: Genesys configuration is missing");
		StopSend = true;
	}

	if (isDisabled == 1)
	{
		foundError = true;
		ruleLog.Add("WARNING: Genesys service has been disabled in this application");
		StopSend = true;
	}
}
catch (Exception ex)
{
	foundError = true;
	ruleLog.Add("ERROR: " + ex.ToString());
	goto Validation;
}

if (!StopSend)
{
	ruleLog.Add("INFO: Genesys configuration found");
}
else
{
	ruleLog.Add("WARNING: Won't send items via Genesys");
}


//==GET ALL POSSIBLE PAGE INFORMATION==
string case_data = String.Empty;
string case_name = String.Empty;
Dictionary<string, string> case_pageparams = new Dictionary<string, string>();

string task_data = String.Empty;
string task_name = String.Empty;
Dictionary<string, string> task_pageparams = new Dictionary<string, string>();

string cp_unitid = String.Empty;
string cp_unitname = String.Empty;
string cp_unittype = String.Empty;
string cp_name = String.Empty;
Dictionary<string, string> cp_pageparams = new Dictionary<string, string>();

string page1_params = String.Empty;
string page2_params = String.Empty;
string customdata_params = String.Empty;


const string pageRuleCode = "root_INT_getBasicPagesInfo";
var pageRuleParams = new ParameterCollection();
pageRuleParams.AddParameter(new Parameter
{
	Type = ParameterType.Text(),
	Name = "TARGETID",
	Value = v_targetId
});
pageRuleParams.AddParameter(new Parameter
{
	Type = ParameterType.Text(),
	Name = "TARGETTYPE",
	Value = v_TargetType
});
pageRuleParams.AddParameter(new Parameter
{
	Type = ParameterType.Text(),
	Name = "CUSTOMDATARULECODE",
	Value = v_CustomData_Rule
});
pageRuleParams.AddParameter(new Parameter
{
	Type = ParameterType.Text(),
	Name = "PAGE1RULECODE",
	Value = v_PageSend1_ParamRule
});
pageRuleParams.AddParameter(new Parameter
{
	Type = ParameterType.Text(),
	Name = "PAGE2RULECODE",
	Value = v_PageSend2_ParamRule
});


var pageRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
{
	DataCommand = pageRuleCode,
	Domain = appDomain,
	Parameters = pageRuleParams,
	Token = token
});

//parse response
try
{
	ruleLog.Add("INFO: Getting page information about Case, Task and Case Party");
	Newtonsoft.Json.Linq.JToken pageRuleData = Newtonsoft.Json.Linq.JObject.Parse(pageRuleResult.Data.ToJson())["DATA"][pageRuleCode];
	int page_ErrorCode = Convert.ToInt32((string)pageRuleData.SelectToken("ERRORCODE"));

	//--catch rule error
	if (page_ErrorCode != 0)
	{
		foundError = true;
		ruleLog.Add(String.Format(ruleErrTpl, pageRuleCode, page_ErrorCode, (string)pageRuleData.SelectToken("ERRORMESSAGE")));
		goto Validation;
	}

	//--get the info
	case_data = (string)pageRuleData.SelectToken("CASECUSTOMDATA"); //expect XML
	case_name = (string)pageRuleData.SelectToken("CASENAME");
	var tempCaseParams = pageRuleData.SelectToken("CUR_CASEPAGE");

	task_data = (string)pageRuleData.SelectToken("TASKCUSTOMDATA"); //expect XML
	task_name = (string)pageRuleData.SelectToken("TASKNAME");
	var tempTaskParams = pageRuleData.SelectToken("CUR_TASKPAGE");

	cp_unitid = (string)pageRuleData.SelectToken("UNITID");
	cp_unitname = (string)pageRuleData.SelectToken("UNITNAME");
	cp_unittype = (string)pageRuleData.SelectToken("UNITTYPE");
	cp_name = (string)pageRuleData.SelectToken("CASEPARTYNAME");
	var tempCPParams = pageRuleData.SelectToken("CUR_CASEPARTYPAGE");

	page1_params = (string)pageRuleData.SelectToken("PAGE1PARAMS");
	page2_params = (string)pageRuleData.SelectToken("PAGE2PARAMS");
	customdata_params = (string)pageRuleData.SelectToken("CUSTOMDATAPARAMS");

	//add page params to dictionary collection                    
	foreach (var param in tempCaseParams)
	{
		case_pageparams.Add((string)param.SelectToken("NAME"), (string)param.SelectToken("VALUE"));
	}
	foreach (var param in tempTaskParams)
	{
		task_pageparams.Add((string)param.SelectToken("NAME"), (string)param.SelectToken("VALUE"));
	}
	foreach (var param in tempCPParams)
	{
		cp_pageparams.Add((string)param.SelectToken("NAME"), (string)param.SelectToken("VALUE"));
	}

}
catch (Exception ex)
{
	foundError = true;
	ruleLog.Add("ERROR: " + ex.ToString());
	goto Validation;
}

//==CONVERT TO SERVICE REQUEST OBJECTS==
var genInteractionParams = new ParameterCollection();

//--PAGE 1 INFO
bool sendPage1 = true;
string page1Code = "root_UTIL_CaseManagement";

Dictionary<string, string> page1TempParams = new Dictionary<string, string>();
switch (v_PageSend1)
{
	case "task":
		genInteractionParams.AddParameter(new Parameter("viewname", ParameterType.Text(), ParameterDirection.Input, "DCM Task"));
		page1TempParams = task_pageparams;
		break; 
	case "case":
		genInteractionParams.AddParameter(new Parameter("viewname", ParameterType.Text(), ParameterDirection.Input, "DCM Case"));
		page1TempParams = case_pageparams;
		break;
	case "external_party":
		genInteractionParams.AddParameter(new Parameter("viewname", ParameterType.Text(), ParameterDirection.Input, "DCM360"));
		page1TempParams = case_pageparams;
		break;
	default:
		sendPage1 = false;
		break;
}

var page1Params = new ParameterCollection();
if (sendPage1)
{
	
	page1Params.AddParameter(new Parameter("appid", ParameterType.Text(), ParameterDirection.Input, "root_CaseManagement"));
	page1Params.AddParameter(new Parameter("d", ParameterType.Text(), ParameterDirection.Input, appDomain));
	ruleLog.Add("INFO: Page 1 is " + v_PageSend1 + " with parameters => ");
	foreach (var param in page1TempParams)
	{
		page1Params.AddParameter(new Parameter(param.Key, ParameterType.Text(), ParameterDirection.Input, param.Value));
		ruleLog.Add("&nbsp;&nbsp;&nbsp;&nbsp;" + param.Key + " : "  + param.Value);
		
	}
} else
{
	ruleLog.Add("INFO: will not send Page 1");
}

//--PAGE 2 INFO
bool sendPage2 = true;
string page2Code = "root_UTIL_CaseManagement";
Dictionary<string, string> page2TempParams = new Dictionary<string, string>();

switch (v_PageSend2)
{
	case "task":
		genInteractionParams.AddParameter(new Parameter("viewname2", ParameterType.Text(), ParameterDirection.Input, "DCM Task"));
		page2TempParams = task_pageparams;
		break;
	case "case":
		genInteractionParams.AddParameter(new Parameter("viewname2", ParameterType.Text(), ParameterDirection.Input, "DCM Case"));
		page2TempParams = case_pageparams;
		break;
	case "external_party":
		genInteractionParams.AddParameter(new Parameter("viewname2", ParameterType.Text(), ParameterDirection.Input, "DCM360"));
		page2TempParams = case_pageparams;
		break;
	default:
		sendPage2 = false;
		break;
}

var page2Params = new ParameterCollection();
if (sendPage2)
{
	page2Params.AddParameter(new Parameter("appid", ParameterType.Text(), ParameterDirection.Input, "root_CaseManagement"));
	page2Params.AddParameter(new Parameter("d", ParameterType.Text(), ParameterDirection.Input, appDomain));
	ruleLog.Add("INFO: Page 2 is " + v_PageSend2 + " with parameters =>");
	foreach (var param in page2TempParams)
	{
		page2Params.AddParameter(new Parameter(param.Key, ParameterType.Text(), ParameterDirection.Input, param.Value));
		ruleLog.Add("&nbsp;&nbsp;&nbsp;&nbsp;" + param.Key + " : " + param.Value);
	}
}
else
{
	ruleLog.Add("INFO: will not send Page 2");
}

//==SEND TO GENESYS==
genInteractionParams.AddParameter(new Parameter("captureId", ParameterType.Text(), ParameterDirection.Input, internalInteractonId));
genInteractionParams.AddParameter(new Parameter("DCM_CATEGORY", ParameterType.Text(), ParameterDirection.Input, "DCM_WORKITEM"));
genInteractionParams.AddParameter(new Parameter("ContactId", ParameterType.Text(), ParameterDirection.Input, "0008Va76MGEC000Q"));

string genesysExternalId = String.Empty;

using (var client = new ASF.Genesys.WebService.Proxy.IntegrationServiceSvc.IntegrationServiceClient())
{
	const string integrationChannel = "root_demosGenesysChannel";
	ruleLog.Add("INFO: using integration channel " + integrationChannel);
	var genesysRequestData = new ASF.Genesys.Common.Domain.CreateTaskData()
	{
		CaptureId = internalInteractonId,
		Channel = "workitem",
		Category = "DCM_WORKITEM",
		MediaType = "webform",
		Priority = 100,
		CustomerId = "5115",
		Parameters = genInteractionParams,
		CreatedDateTime = null,
		ActivationDateTime = null,
		DueDateTime = null,
		ExpirationDateTime = null,
		BusinessValue = 100,
		ProcessId = null,
		Hold = null,
		Reason = null,
		Actor = null
	};

	if (sendPage1)
	{
		genesysRequestData.PageCode = page1Code;
		genesysRequestData.PageParameters = page1Params;
	}

	if (sendPage2)
	{
		genesysRequestData.PageCode2  = page2Code;
		genesysRequestData.PageParameters2 = page2Params;
	}


	var genesysRequest = new ASF.Genesys.WebService.Messages.CreateTaskRequest()
	{
		Code = integrationChannel,
		Domain = appDomain,
		Token = token,
		Data = genesysRequestData
	};

	//parse response
	try
	{
		var createTaskResp = client.CreateTask(genesysRequest);
		genesysExternalId = createTaskResp.ExternalId;
		ruleLog.Add("INFO: " + "Genesys External ID returned " + genesysExternalId);

		if (createTaskResp.ErrorCode > 0)
		{
			foundError = true;
			ruleLog.Add(String.Format(ruleErrTpl, "client.CreateTask", createTaskResp.ErrorCode, createTaskResp.ErrorMessage));
			goto Validation;
		}
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		ruleLog.Add(ex.StackTrace);
		goto Validation;
	}
}

//==UPDATE TARGET WITH THE GENESYS EXTERNAL ID==
ruleLog.Add("INFO: " + "Updated " + v_TargetType + " with new External ID");
var intUpdateParams = new ParameterCollection();
intUpdateParams.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "TargetType", Value = v_TargetType });
intUpdateParams.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "TargetId", Value = v_targetId });
intUpdateParams.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "ExternalIntegrationID", Value = genesysExternalId });
intUpdateParams.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "IntegrationCode", Value = "GENESYS" });

var getFolderTreeRequest = ASF.CoreLib.APIHelper.BDSExecute(
	new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_INT_setTarget",
		Domain = appDomain,
		Parameters = intUpdateParams,
		Token = token
	}
);


Validation:
const string msgTpl = "<p><b>{0}:</b> {1}</p>";
string historyMsgCode = String.Empty;
List<String> additionalInfo = new List<String>();

//set response information
if (foundError)
{
	response["ERRORCODE"] = 101;
	response["ERRORMESSAGE"] = String.Join(System.Environment.NewLine, ruleLog);
	response["SUCCESSRESPONSE"] = String.Empty;

	//history info
	additionalInfo.Add(String.Format(msgTpl, "Error Code", 101));
	additionalInfo.Add(String.Join(System.Environment.NewLine, ruleLog));
	historyMsgCode = "PUREENGAGE_FAILURE";
}
else
{
	response["ERRORCODE"] = 0;
	response["ERRORMESSAGE"] = String.Empty;
	response["SUCCESSRESPONSE"] = String.Join(System.Environment.NewLine, ruleLog);
	additionalInfo.Add(String.Join(System.Environment.NewLine, ruleLog));
	//history info
	historyMsgCode = "PUREENGAGE_SUCCESS";
}

var historyParams = new ASF.Framework.Service.Parameters.ParameterCollection();
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetType", Value = v_TargetType });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "targetId", Value = v_targetId });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "MessageCode", Value = historyMsgCode });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "AdditionalInfo", Value = String.Join("", additionalInfo) });
var historyResponse = ASF.CoreLib.APIHelper.BDSExecute(
	new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_HIST_createHistory",
		Domain = appDomain,
		Parameters = historyParams,
		Token = token
	}
);


//------------------------------------End rule ------------------------------------