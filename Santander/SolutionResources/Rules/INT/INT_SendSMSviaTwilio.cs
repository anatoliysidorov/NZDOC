//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//system info
Boolean foundError = false;
const string invokeRuleCode = "root_UTIL_genericInvoker";
const string ruleErrTpl = "ERROR: There was an error executing rule {0} exiting with code {1} => {2}";
List<String> ruleLog = new List<String>();

//input params
string v_targetId = request.AsString("TargetID");
string v_targetType = request.AsString("TargetType");
string v_To = request.AsString("To");
string v_To_Rule = request.AsString("ToRule");
string v_From = request.AsString("From");
string v_From_Rule = request.AsString("FromRule");
string v_Message = request.AsString("Message");
string v_MessageCode = request.AsString("MessageCode");
string v_Message_Rule = request.AsString("MessageRule");

//calculated fields
string calcFrom = String.Empty;
string calcMsg = String.Empty;
List<String> calcTo = new List<String>();

//==PARAMETER PRE-CHECK==
if (string.IsNullOrWhiteSpace(v_To) && string.IsNullOrWhiteSpace(v_To_Rule))
{
	foundError = true;
	ruleLog.Add("ERROR: Can't send SMS because either TO or TO RULE is missing. Please contact your administrator.");
	goto Validation;
}
if (string.IsNullOrWhiteSpace(v_MessageCode) && string.IsNullOrWhiteSpace(v_Message_Rule) && string.IsNullOrWhiteSpace(v_Message))
{
	foundError = true;
	ruleLog.Add("ERROR: Can't send SMS because either MESSAGE, MESSAGE RULE or MESSAGE CODE is missing. Please contact your administrator.");
	goto Validation;
}

//==GET TWILIO CONFIGURATION FROM DB==
string ConfAccountSID = string.Empty;
string ConfAuthToken = string.Empty;
string ConfPhone = string.Empty;
Boolean StopSend = false;
int isDisabled = 0;


const string twlRuleCode = "root_INT_getSingleConfig";
var twlRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
twlRuleParams.AddParameter(new Parameter
{
	Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
	Name = "CODE",
	Value = "TWILIO"
});

var twlRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
{
	DataCommand = twlRuleCode,
	Domain = appDomain,
	Parameters = twlRuleParams,
	Token = token
});

//parse response
try
{
	Newtonsoft.Json.Linq.JToken twlRuleData = Newtonsoft.Json.Linq.JObject.Parse(twlRuleResult.Data.ToJson())["DATA"][twlRuleCode];
	isDisabled = Convert.ToInt32((string)twlRuleData.SelectToken("ISDISABLED"));
	int twlConfig_ErrorCode = Convert.ToInt32((string)twlRuleData.SelectToken("ERRORCODE"));
	string twlConfig_Config = (string)twlRuleData.SelectToken("CONFIG");

	//--catch rule error
	if (twlConfig_ErrorCode != 0)
	{
		foundError = true;
		ruleLog.Add(String.Format(ruleErrTpl, twlRuleCode, twlConfig_ErrorCode, (string)twlRuleData.SelectToken("ERRORMESSAGE")));
		goto Validation;
	}

	//--parse config
	if (!string.IsNullOrWhiteSpace(twlConfig_Config))
	{
		XmlDocument twlConfig_XML = new XmlDocument();
		twlConfig_XML.LoadXml(twlConfig_Config);
		ConfAccountSID = twlConfig_XML.SelectSingleNode("/CustomData/Attributes/SID").InnerText;
		ConfAuthToken = twlConfig_XML.SelectSingleNode("/CustomData/Attributes/TOKEN").InnerText;
		ConfPhone = twlConfig_XML.SelectSingleNode("/CustomData/Attributes/FROMNUM").InnerText;
	}
	else
	{
		foundError = true;
		ruleLog.Add("ERROR: Twilio configuration is missing");
		StopSend = true;
	}

	if (string.IsNullOrWhiteSpace(ConfAccountSID))
	{
		foundError = true;
		ruleLog.Add("ERROR: Twilio SID is missing");
		StopSend = true;
	}

	if (string.IsNullOrWhiteSpace(ConfAccountSID))
	{
		foundError = true;
		ruleLog.Add("ERROR: Twilio Authentication Token is missing");
		StopSend = true;
	}

	if (isDisabled == 1)
	{
		foundError = true;
		ruleLog.Add("WARNING: Twilio service has been disabled in this application");
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
	ruleLog.Add("INFO: Twilio configuration found");
}
else
{
	ruleLog.Add("WARNING: Won't send SMS via Twilio");
}


//==CALCULATE TO PHONE NUMBERS==
if (!String.IsNullOrWhiteSpace(v_To))
{
	calcTo.AddRange(v_To.Split(new string[] { "," }, StringSplitOptions.RemoveEmptyEntries));
}

if (!String.IsNullOrWhiteSpace(v_To_Rule))
{
	var toRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	toRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "ProcessorName",
		Value = v_To_Rule
	});
	toRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetType",
		Value = v_targetType
	});
	toRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetId",
		Value = v_targetId
	});

	var toRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = invokeRuleCode,
		Domain = appDomain,
		Parameters = toRuleParams,
		Token = token
	});

	//parse response
	try
	{
		Newtonsoft.Json.Linq.JToken toRuleData = Newtonsoft.Json.Linq.JObject.Parse(toRuleResult.Data.ToJson())["DATA"][invokeRuleCode];
		int toConfig_ErrorCode = Convert.ToInt32((string)toRuleData.SelectToken("ERRORCODE"));
		string toConfig_Result = (string)toRuleData.SelectToken("RESULT");

		//--catch rule error
		if (toConfig_ErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(String.Format(ruleErrTpl, invokeRuleCode, toConfig_ErrorCode, (string)toRuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}

		//--parse config
		if (!string.IsNullOrWhiteSpace(toConfig_Result))
		{
			calcTo.AddRange(toConfig_Result.Split(new string[] { "," }, StringSplitOptions.RemoveEmptyEntries));
		}
		else
		{
			ruleLog.Add("WARNING: To Rule didn't return any phone numbers");
		}


	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

if (calcTo.Count() == 0)
{
	foundError = true;
	ruleLog.Add("ERROR: No phone numbers to send SMS to");
	goto Validation;
}
else
{
	ruleLog.Add("INFO: Send to " + String.Join(", ", calcTo));
}

//==CALCULATE FROM PHONE NUMBER==       
if (!String.IsNullOrWhiteSpace(v_From_Rule))
{
	var fromRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	fromRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "ProcessorName",
		Value = v_From_Rule
	});
	fromRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetType",
		Value = v_targetType
	});
	fromRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetId",
		Value = v_targetId
	});

	var fromRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = invokeRuleCode,
		Domain = appDomain,
		Parameters = fromRuleParams,
		Token = token
	});

	//parse response
	try
	{
		Newtonsoft.Json.Linq.JToken fromRuleData = Newtonsoft.Json.Linq.JObject.Parse(fromRuleResult.Data.ToJson())["DATA"][invokeRuleCode];
		int fromConfig_ErrorCode = Convert.ToInt32((string)fromRuleData.SelectToken("ERRORCODE"));
		string fromConfig_Result = (string)fromRuleData.SelectToken("RESULT");

		//--catch rule error
		if (fromConfig_ErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(String.Format(ruleErrTpl, invokeRuleCode, fromConfig_ErrorCode, (string)fromRuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}

		//--parse config
		if (!string.IsNullOrWhiteSpace(fromConfig_Result))
		{
			calcFrom = fromConfig_Result;
		}
		else
		{
			ruleLog.Add("WARNING: From Rule didn't return a phone number");
		}
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

//try to find other from phone numbers
if (string.IsNullOrWhiteSpace(calcFrom))
{
	calcFrom = v_From;
}

if (string.IsNullOrWhiteSpace(calcFrom))
{
	calcFrom = ConfPhone;
}

if (string.IsNullOrWhiteSpace(calcFrom))
{
	foundError = true;
	ruleLog.Add("ERROR: No phone number to send SMS from");
	goto Validation;
}
else
{
	ruleLog.Add("INFO: Send from " + calcFrom);
}

//==CALCULATE MESSAGE==
if (!String.IsNullOrWhiteSpace(v_Message_Rule))
{
	var msgRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	msgRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "ProcessorName",
		Value = v_Message_Rule
	});
	msgRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetType",
		Value = v_targetType
	});
	msgRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetId",
		Value = v_targetId
	});

	var msgRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = invokeRuleCode,
		Domain = appDomain,
		Parameters = msgRuleParams,
		Token = token
	});

	//parse response
	try
	{
		Newtonsoft.Json.Linq.JToken toRuleData = Newtonsoft.Json.Linq.JObject.Parse(msgRuleResult.Data.ToJson())["DATA"][invokeRuleCode];
		int toConfig_ErrorCode = Convert.ToInt32((string)toRuleData.SelectToken("ERRORCODE"));
		string toConfig_Result = (string)toRuleData.SelectToken("RESULT");

		//--catch rule error
		if (toConfig_ErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(String.Format(ruleErrTpl, invokeRuleCode, toConfig_ErrorCode, (string)toRuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}

		//--parse config
		if (!string.IsNullOrWhiteSpace(toConfig_Result))
		{
			calcMsg = toConfig_Result;
		}
		else
		{
			ruleLog.Add("WARNING: Message Rule didn't return a message");
		}
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

//attempt to use MessageCode to generate a message if no message exists yet
if (String.IsNullOrWhiteSpace(calcMsg) && !String.IsNullOrWhiteSpace(v_MessageCode))
{
	const string msgTplCode = "root_HIST_genMsgFromTpl";
	var msgTplParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	msgTplParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "MessageCode",
		Value = v_MessageCode
	});
	msgTplParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetType",
		Value = v_targetType
	});
	msgTplParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetId",
		Value = v_targetId
	});

	var msgRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = msgTplCode,
		Domain = appDomain,
		Parameters = msgTplParams,
		Token = token
	});

	//parse response
	try
	{
		Newtonsoft.Json.Linq.JToken toRuleData = Newtonsoft.Json.Linq.JObject.Parse(msgRuleResult.Data.ToJson())["DATA"][msgTplCode];
		int toConfig_ErrorCode = Convert.ToInt32((string)toRuleData.SelectToken("ERRORCODE"));
		string toConfig_Result = (string)toRuleData.SelectToken("RESULT");

		//--catch rule error
		if (toConfig_ErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(String.Format(ruleErrTpl, msgTplCode, toConfig_ErrorCode, (string)toRuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}

		//--parse config
		if (!string.IsNullOrWhiteSpace(toConfig_Result))
		{
			calcMsg = toConfig_Result;
		}
		else
		{
			ruleLog.Add("WARNING: Message Template Evaluator didn't return a message");
		}
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

if (String.IsNullOrWhiteSpace(calcMsg))
{
	calcMsg = v_Message;
}


if (String.IsNullOrWhiteSpace(calcMsg))
{
	foundError = true;
	ruleLog.Add("ERROR: No message to send");
	goto Validation;
}
else
{
	ruleLog.Add("INFO: Message body is = " + calcMsg);
}


//==ATTEMPT TO SEND MESSAGE==
if (!StopSend)
{
	var twilio = new Twilio.TwilioRestClient(ConfAccountSID, ConfAuthToken);
	Twilio.Message twlResponse;
	foreach (var phoneToSend in calcTo)
	{
		twlResponse = twilio.SendMessage(calcFrom, phoneToSend, calcMsg);

		if (twlResponse.RestException != null)
		{
			foundError = true;
			ruleLog.Add("ERROR: Problem sending to " + phoneToSend);
			ruleLog.Add("ERROR: " + twlResponse.RestException.Message);
		}

	}

}


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
	additionalInfo.Add(String.Join("<br>", ruleLog));
	historyMsgCode = "TWILIO_Failure";
}
else
{
	response["ERRORCODE"] = 0;
	response["ERRORMESSAGE"] = String.Empty;
	response["SUCCESSRESPONSE"] = String.Join(System.Environment.NewLine, ruleLog);

	//history info
	historyMsgCode = "TWILIO_Success";
	additionalInfo.Add(String.Format(msgTpl, "From", calcFrom));
	additionalInfo.Add(String.Format(msgTpl, "To", String.Join(", ", calcTo)));
	additionalInfo.Add(String.Format(msgTpl, "Body", calcMsg));
}


var historyParams = new ASF.Framework.Service.Parameters.ParameterCollection();
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetType", Value = v_targetType });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetID", Value = v_targetId });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "MessageCode", Value = historyMsgCode });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "AdditionalInfo", Value = String.Join("", additionalInfo) });
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