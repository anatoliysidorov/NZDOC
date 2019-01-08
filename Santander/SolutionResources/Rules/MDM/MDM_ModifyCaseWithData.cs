//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//system info
bool foundError = false;
const string invokeRuleCode = "root_UTIL_genericInvoker";
const string ruleErrTpl = "ERROR: There was an error executing rule {0} exiting with code {1} => {2}";
List<string> ruleLog = new List<string>();
ruleLog.Add("=====RULE: MDM_CreateCaseWithData=====");
List<string> v_SuccessMessage = new List<string>();
int v_CaseId = 0;

//input params
string v_InputXML = request.AsString("InputXML");

//calculated fields
string v_summary = string.Empty;
string v_priorityId = string.Empty;
string v_description = string.Empty;
string v_caseTypeId = string.Empty;
string v_draft = string.Empty;
string v_OutputXML = string.Empty;


//==PARAMETER PRE-CHECK==
if (string.IsNullOrWhiteSpace(v_InputXML))
{
	foundError = true;
	ruleLog.Add("ERROR: The InputXML is missing and can't continue");
	goto Validation;
}

//==EXTRACT CASE OBJECT VARIABLES TO CREATE CASE        
var parsedInputXML = new XmlDocument();
try
{

	parsedInputXML.LoadXml(v_InputXML);
	var caseNode = parsedInputXML.SelectSingleNode("//CustomData/Attributes/Object[@ObjectCode='CASE']/Item");

	v_summary = caseNode.SelectSingleNode("SUMMARY").InnerText;
	v_priorityId = caseNode.SelectSingleNode("PRIORITY_ID").InnerText;
	v_description = caseNode.SelectSingleNode("DESCRIPTION").InnerText;
	v_caseTypeId = caseNode.SelectSingleNode("CASESYSTYPE_ID").InnerText;
	v_draft = caseNode.SelectSingleNode("DRAFT").InnerText;

}
catch (Exception ex)
{
	foundError = true;
	ruleLog.Add("ERROR: " + ex.ToString());
	goto Validation;
}

if (string.IsNullOrWhiteSpace(v_caseTypeId))
{
	foundError = true;
	ruleLog.Add("ERROR: the Input XML is missing the Case Type");
	goto Validation;
}

//==CREATE CASE
string v_CaseName = string.Empty;

using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
{
	const string RuleCode = "root_DCM_createCaseWithOptions";
	var RuleParams = new ParameterCollection();
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "CASESYSTYPE_ID",
		Value = v_caseTypeId
	});
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "SUMMARY",
		Value = v_summary
	});
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "DESCRIPTION",
		Value = v_description
	});
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "PRIORITY_ID",
		Value = v_priorityId
	});
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "DRAFT",
		Value = 0
	});

	var RuleResult = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = RuleCode,
		Domain = appDomain,
		Parameters = RuleParams,
		Token = token
	});

	//parse response
	try
	{
		Newtonsoft.Json.Linq.JToken RuleData = Newtonsoft.Json.Linq.JObject.Parse(RuleResult.Data.ToJson())["DATA"][RuleCode];

		v_CaseId = Convert.ToInt32((string)RuleData.SelectToken("CASE_ID"));
		v_CaseName = (string)RuleData.SelectToken("CASENAME");
		int v_TempErrorCode = Convert.ToInt32((string)RuleData.SelectToken("ERRORCODE"));

		//--catch rule error
		if (v_TempErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(string.Format(ruleErrTpl, invokeRuleCode, v_TempErrorCode, (string)RuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}
		else
		{
			ruleLog.Add("INFO: " + (string)RuleData.SelectToken("SUCCESSRESPONSE"));
			v_SuccessMessage.Add((string)RuleData.SelectToken("SUCCESSRESPONSE"));
		}

		if (v_CaseId <= 0)
		{
			foundError = true;
			ruleLog.Add("ERROR: Case was not created");
			goto Validation;
		}

	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

//==GET MDM CONFIGURATION FROM DB==
int v_ConfigId = 0;
bool StopMDM = false;
using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
{
	const string RuleCode = "root_MDM_getDataModelConfig";
	var RuleParams = new ParameterCollection();
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "CASETYPEID",
		Value = v_caseTypeId
	});
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "PURPOSE",
		Value = "CREATE"
	});

	//parse response
	try
	{
		var RuleResult = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = RuleCode,
			Domain = appDomain,
			Parameters = RuleParams,
			Token = token
		});

		Newtonsoft.Json.Linq.JToken RuleData = Newtonsoft.Json.Linq.JObject.Parse(RuleResult.Data.ToJson())["DATA"][RuleCode];
		v_ConfigId = Convert.ToInt32((string)RuleData.SelectToken("CONFIGID"));

		if (v_ConfigId > 0)
		{
			ruleLog.Add("INFO: Found DOM_Config.ID = " + v_ConfigId.ToString());
		}
		else
		{
			ruleLog.Add("WARNING: Missing DOM_Config for CREATE purpose");
			StopMDM = true;
		}
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}


//==CREATE DATA WITH MDM==
if (StopMDM)
{
	ruleLog.Add("WARNING: Will not use MDM to create initial Case data because the Model Configuration can't be found");
}
else
{
	ruleLog.Add("INFO: Attempting to create Case data with MDM");
	using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
		const string RuleCode = "root_DOM_createCustomBO";
		var RuleParams = new ParameterCollection();
		RuleParams.AddParameter(new Parameter
		{
			Type = ParameterType.Text(),
			Name = "CONFIGID",
			Value = v_ConfigId
		});
		RuleParams.AddParameter(new Parameter
		{
			Type = ParameterType.Integer(),
			Name = "ROOTOBJECTIDID",
			Value = v_CaseId
		});
		RuleParams.AddParameter(new Parameter
		{
			Type = ParameterType.Text(),
			Name = "ROOTOBJECTNAME",
			Value = "CASE"
		});
		RuleParams.AddParameter(new Parameter
		{
			Type = ParameterType.Text(),
			Name = "INPUT",
			Value = parsedInputXML.InnerXml
		});



		//parse response
		try
		{
			var RuleResult = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
			{
				DataCommand = RuleCode,
				Domain = appDomain,
				Parameters = RuleParams,
				Token = token
			});


			Newtonsoft.Json.Linq.JToken RuleData = Newtonsoft.Json.Linq.JObject.Parse(RuleResult.Data.ToJson())["DATA"][RuleCode];
			int v_TempErrorCode = Convert.ToInt32((string)RuleData.SelectToken("ERRORCODE"));

			//--catch rule error
			if (v_TempErrorCode != 0)
			{
				foundError = true;
				ruleLog.Add(string.Format(ruleErrTpl, invokeRuleCode, v_TempErrorCode, (string)RuleData.SelectToken("ERRORMESSAGE")));
				goto Validation;
			}
			else
			{
				ruleLog.Add("INFO: " + (string)RuleData.SelectToken("SUCCESSRESPONSE"));
				v_SuccessMessage.Add((string)RuleData.SelectToken("SUCCESSRESPONSE"));
			}

			ruleLog.Add("INFO: Saved data using MDM");
		}
		catch (Exception ex)
		{
			foundError = true;
			ruleLog.Add("ERROR: " + ex.ToString());
			ruleLog.Add(ex.StackTrace);
			goto Validation;
		}
	}
}

//==GET THE SAVED DATA FOR THE CASE TO VALIDATE IT WAS SAVED CORRECTLY==
ruleLog.Add("INFO: Attempting to read Case data");
using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
{
	const string RuleCode = "root_MDM_RetrieveDataSetByCaseId";
	var RuleParams = new ParameterCollection();
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "CASEID",
		Value = v_CaseId
	});

	//parse response
	try
	{
		var RuleResult = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = RuleCode,
			Domain = appDomain,
			Parameters = RuleParams,
			Token = token
		});

		Newtonsoft.Json.Linq.JToken RuleData = Newtonsoft.Json.Linq.JObject.Parse(RuleResult.Data.ToJson())["DATA"][RuleCode];
		v_OutputXML = (string)RuleData.SelectToken("MDM_DATA_XML");
		ruleLog.Add("INFO: Retreieved XML data");
		ruleLog.Add("===OUTPUT XML===");
		ruleLog.Add(v_OutputXML);
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		ruleLog.Add(ex.StackTrace);
		goto Validation;
	}
}



Validation:
const string msgTpl = "<p><b>{0}:</b> {1}</p>";
string historyMsgCode = string.Empty;
List<string> additionalInfo = new List<string>();

//set response information
if (foundError)
{
	ruleLog.Add("--INPUT XML--");
	additionalInfo.Add("{[" + String.Format("this.YELLOW_TABLE('{0}','{1}')", v_InputXML, v_OutputXML) + "]}");

	response["ERRORCODE"] = 101;
	response["ERRORMESSAGE"] = string.Join(System.Environment.NewLine, ruleLog);
	response["SUCCESSRESPONSE"] = string.Empty;

	//history info
	additionalInfo.Add(string.Format(msgTpl, "Error Code", 101));
	additionalInfo.Add(string.Join("<br>", ruleLog));
	historyMsgCode = "GenericError";
}
else
{
	response["ERRORCODE"] = 0;
	response["ERRORMESSAGE"] = string.Empty;
	response["SUCCESSRESPONSE"] = string.Join(System.Environment.NewLine, v_SuccessMessage);

	//history info
	historyMsgCode = "CaseModified";
	additionalInfo.Add("{[" + String.Format("this.YELLOW_TABLE('{0}','{1}')", v_InputXML, v_OutputXML) + "]}");
}


var historyParams = new ParameterCollection();
historyParams.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "TargetType", Value = "CASE" });
historyParams.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "TargetID", Value = v_CaseId });
historyParams.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "MessageCode", Value = historyMsgCode });
historyParams.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "AdditionalInfo", Value = string.Join("", additionalInfo) });
using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
{
	var writeHistoryRequest = client.Execute(
		new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = "root_HIST_createHistory",
			Domain = appDomain,
			Parameters = historyParams,
			Token = token
		}
	);
};


//------------------------------------End rule ------------------------------------