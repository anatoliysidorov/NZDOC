//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//system info
bool foundError = false;
//const string invokeRuleCode = "root_UTIL_genericInvoker";
const string ruleErrTpl = "ERROR: There was an error executing rule {0} exiting with code {1} => {2}";
List<string> ruleLog = new List<string>();
ruleLog.Add("=====RULE: MDM_ModifyCaseWithData=====");
List<string> v_SuccessMessage = new List<string>();

//input params
string v_InputXML = request.AsString("InputXML");
string v_ParentCode = request.AsString("ParentCode");
string v_ParentId = request.AsString("ParentId");


//calculated fields
int v_CaseTypeId = 0;
string v_caseId = string.Empty;
string v_summary = string.Empty;
string v_priorityId = string.Empty;
string v_description = string.Empty;            
string v_draft = string.Empty;
int v_ConfigId = 0;
string v_OutputXML = "TEMP";

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
	v_caseId = caseNode.SelectSingleNode("ID").InnerText;
	v_draft = caseNode.SelectSingleNode("DRAFT").InnerText;

}
catch (Exception ex)
{
	foundError = true;
	ruleLog.Add("ERROR: " + ex.ToString());
	goto Validation;
}

if (string.IsNullOrWhiteSpace(v_caseId))
{
	foundError = true;
	ruleLog.Add("ERROR: the Input XML is missing the Case");
	goto Validation;
}

//==UPDATE CASE
using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
{
	const string RuleCode = "root_DCM_updateBasicCaseData";
	var RuleParams = new ParameterCollection();
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "ID",
		Value = v_caseId
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
		int v_TempErrorCode = Convert.ToInt32((string)RuleData.SelectToken("ERRORCODE"));

		//--catch rule error
		if (v_TempErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(string.Format(ruleErrTpl, RuleCode, v_TempErrorCode, (string)RuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}
		else
		{
			ruleLog.Add("INFO: " + (string)RuleData.SelectToken("SUCCESSRESPONSE"));
			v_SuccessMessage.Add((string)RuleData.SelectToken("SUCCESSRESPONSE"));
		}

	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

//==GET INFORMATION ABOUT CASE FOR MDM PURPOSES==
using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
{
	const string RuleCode = "root_MDM_getCaseOrCTinfo";
	var RuleParams = new ParameterCollection();
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "CASEID",
		Value = v_caseId
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
		v_CaseTypeId = Convert.ToInt32((string)RuleData.SelectToken("CALC_CASETYPEID"));
		v_ConfigId = Convert.ToInt32((string)RuleData.SelectToken("CREATE_CONFIGID"));

		if (v_CaseTypeId > 0)
		{
			ruleLog.Add("INFO: Found Case Type = " + v_CaseTypeId.ToString());
		}
		else
		{
			foundError = true;
			ruleLog.Add("ERROR: Missing Case Type");
			goto Validation;
		}

		if (v_ConfigId > 0)
		{
			ruleLog.Add("INFO: Found EDIT Config = " + v_ConfigId.ToString());
		}
		else
		{
			foundError = true;
			ruleLog.Add("ERROR: Missing EDIT Config");
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


//==CREATE DATA WITH MDM==
ruleLog.Add("INFO: Attempting to update Case data with MDM");
using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
{
	const string RuleCode = "root_DOM_updateCustomBO";
	var RuleParams = new ParameterCollection();
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "ConfigId",
		Value = v_ConfigId
	});
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Integer(),
		Name = "RootObjectIdId",
		Value = v_ParentId
	});
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "RootObjectName",
		Value = v_ParentCode
	});
	RuleParams.AddParameter(new Parameter
	{
		Type = ParameterType.Text(),
		Name = "Input",
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
			ruleLog.Add(string.Format(ruleErrTpl, RuleCode, v_TempErrorCode, (string)RuleData.SelectToken("ERRORMESSAGE")));
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

//==GET THE SAVED DATA FOR THE CASE TO VALIDATE IT WAS SAVED CORRECTLY==
if(v_ParentCode.ToLower() == "case"){
	ruleLog.Add("INFO: Attempting to read Case data");
	using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
		const string RuleCode = "root_MDM_RetrieveDataSetByCaseId";
		var RuleParams = new ParameterCollection();
		RuleParams.AddParameter(new Parameter
		{
			Type = ParameterType.Text(),
			Name = "CASEID",
			Value = v_ParentId
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
	//response["SUCCESSRESPONSE"] = string.Join(System.Environment.NewLine, ruleLog);

	//history info
	historyMsgCode = "CaseModified";
	additionalInfo.Add("{[" + String.Format("this.YELLOW_TABLE('{0}','{1}')", v_InputXML, v_OutputXML) + "]}");
}


var historyParams = new ParameterCollection();
historyParams.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "TargetType", Value = "CASE" });
historyParams.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "TargetID", Value = v_caseId });
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