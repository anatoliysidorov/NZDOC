//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//system info
Boolean foundError = false;
const string invokeRuleCode = "root_UTIL_genericInvoker";
const string ruleErrTpl = "ERROR: There was an error executing rule {0} exiting with code {1} => {2}";
List<String> ruleLog = new List<String>();
ruleLog.Add("==LTR_SendAdvancedEmail==");

//input params
string v_targetId = request.AsString("TargetID");
string v_TargetType = request.AsString("TargetType");
string v_To = request.AsString("To");
string v_To_Rule = request.AsString("ToRule");
string v_CC = request.AsString("Cc");
string v_CC_Rule = request.AsString("CcRule");
string v_BCC = request.AsString("Bcc");
string v_BCC_Rule = request.AsString("BccRule");
string v_From = request.AsString("From");
string v_From_Rule = request.AsString("FromRule");
string v_Attachments = request.AsString("Attachments");
string v_Attachments_Rule = request.AsString("AttachmentsRule");
string v_Template = request.AsString("Template");
string v_Template_Rule = request.AsString("TemplateRule");
string v_Body = request.AsString("Body");
string v_DistributionChannel = request.AsString("DistributionChannel");
string v_Subject = request.AsString("Subject");
string v_Subject_Rule = request.AsString("Subject_Rule");

//calculated fields
string calcFrom = String.Empty;
string calcTemplate = String.Empty;
string calcSubject = String.Empty;
string calcTo = String.Empty;
string calcCC = String.Empty;
string calcBCC = String.Empty;
string calcAttachments = String.Empty;

//==CALCULATE TO EMAIL ADDRESSES==
if (!String.IsNullOrWhiteSpace(v_To))
{
	calcTo = v_To;
}
else if (!String.IsNullOrWhiteSpace(v_To_Rule))
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
		Value = v_TargetType
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
			calcTo = toConfig_Result;
		}
		else
		{
			ruleLog.Add("WARNING: To Rule didn't return any emails");
		}


	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

//==CALCULATE CC EMAIL ADDRESSES==
if (!String.IsNullOrWhiteSpace(v_CC))
{
	calcCC = v_CC;
}
else if (!String.IsNullOrWhiteSpace(v_CC_Rule))
{
	
	var ccRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	ccRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "ProcessorName",
		Value = v_CC_Rule
	});
	ccRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetType",
		Value = v_TargetType
	});
	ccRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetId",
		Value = v_targetId
	});

	var ccRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = invokeRuleCode,
		Domain = appDomain,
		Parameters = ccRuleParams,
		Token = token
	});

	//parse response
	try
	{
		Newtonsoft.Json.Linq.JToken ccRuleData = Newtonsoft.Json.Linq.JObject.Parse(ccRuleResult.Data.ToJson())["DATA"][invokeRuleCode];
		int ccConfig_ErrorCode = Convert.ToInt32((string)ccRuleData.SelectToken("ERRORCODE"));
		string ccConfig_Result = (string)ccRuleData.SelectToken("RESULT");

		//--catch rule error
		if (ccConfig_ErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(String.Format(ruleErrTpl, invokeRuleCode, ccConfig_ErrorCode, (string)ccRuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}

		//--parse config
		if (!string.IsNullOrWhiteSpace(ccConfig_Result))
		{
			calcCC = ccConfig_Result;
		}
		else
		{
			ruleLog.Add("WARNING:CC Rule didn't return any emails");
		}

	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

//==CALCULATE BCC EMAIL ADDRESSES==
if (!String.IsNullOrWhiteSpace(v_BCC))
{
	calcBCC = v_BCC;
}
else if (!String.IsNullOrWhiteSpace(v_BCC_Rule))
{
	var bccRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	bccRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "ProcessorName",
		Value = v_BCC_Rule
	});
	bccRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetType",
		Value = v_TargetType
	});
	bccRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetId",
		Value = v_targetId
	});

	var bccRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = invokeRuleCode,
		Domain = appDomain,
		Parameters = bccRuleParams,
		Token = token
	});

	//parse response
	try
	{
		Newtonsoft.Json.Linq.JToken bccRuleData = Newtonsoft.Json.Linq.JObject.Parse(bccRuleResult.Data.ToJson())["DATA"][invokeRuleCode];
		int bccConfig_ErrorCode = Convert.ToInt32((string)bccRuleData.SelectToken("ERRORCODE"));
		string bccConfig_Result = (string)bccRuleData.SelectToken("RESULT");

		//--catch rule error
		if (bccConfig_ErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(String.Format(ruleErrTpl, invokeRuleCode, bccConfig_ErrorCode, (string)bccRuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}

		//--parse config
		if (!string.IsNullOrWhiteSpace(bccConfig_Result))
		{
			calcBCC = bccConfig_Result;
		}
		else
		{
			ruleLog.Add("WARNING: BCC Rule didn't return any emails");
		}
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

//==CALCULATE ATTACHMENTS==
if (!String.IsNullOrWhiteSpace(v_Attachments))
{
	calcAttachments = v_Attachments;
}
else if (!String.IsNullOrWhiteSpace(v_Attachments_Rule))
{
	var attchRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	attchRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "ProcessorName",
		Value = v_Attachments_Rule
	});
	attchRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetType",
		Value = v_TargetType
	});
	attchRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetId",
		Value = v_targetId
	});

	var attchRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = invokeRuleCode,
		Domain = appDomain,
		Parameters = attchRuleParams,
		Token = token
	});

	//parse response
	try
	{
		Newtonsoft.Json.Linq.JToken attchRuleData = Newtonsoft.Json.Linq.JObject.Parse(attchRuleResult.Data.ToJson())["DATA"][invokeRuleCode];
		int attchConfig_ErrorCode = Convert.ToInt32((string)attchRuleData.SelectToken("ERRORCODE"));
		string attchConfig_Result = (string)attchRuleData.SelectToken("RESULT");

		//--catch rule error
		if (attchConfig_ErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(String.Format(ruleErrTpl, invokeRuleCode, attchConfig_ErrorCode, (string)attchRuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}

		//--parse config
		if (!string.IsNullOrWhiteSpace(attchConfig_Result))
		{
			calcAttachments = attchConfig_Result;
		}
		else
		{
			ruleLog.Add("WARNING: Attachment Rule didn't return any CMS Urls");
		}


	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}


//==CALCULATE FROM EMAIL ADDRESS== 
if (!String.IsNullOrWhiteSpace(v_From))
{
	calcFrom = v_From;
}
else if (!String.IsNullOrWhiteSpace(v_From_Rule))
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
		Value = v_TargetType
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
			ruleLog.Add("WARNING: From Rule didn't return an email address");
		}
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}

//==CALCULATE SUBJECT== 
if (!String.IsNullOrWhiteSpace(v_Subject))
{
	calcSubject = v_Subject;
}
else if (!String.IsNullOrWhiteSpace(v_Subject_Rule))
{
	var subjectRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	subjectRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "ProcessorName",
		Value = v_From_Rule
	});
	subjectRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetType",
		Value = v_TargetType
	});
	subjectRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetId",
		Value = v_targetId
	});

	var subjectRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = invokeRuleCode,
		Domain = appDomain,
		Parameters = subjectRuleParams,
		Token = token
	});

	//parse response
	try
	{
		Newtonsoft.Json.Linq.JToken subjectRuleData = Newtonsoft.Json.Linq.JObject.Parse(subjectRuleResult.Data.ToJson())["DATA"][invokeRuleCode];
		int subjectConfig_ErrorCode = Convert.ToInt32((string)subjectRuleData.SelectToken("ERRORCODE"));
		string subjectConfig_Result = (string)subjectRuleData.SelectToken("RESULT");

		//--catch rule error
		if (subjectConfig_ErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(String.Format(ruleErrTpl, invokeRuleCode, subjectConfig_ErrorCode, (string)subjectRuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}

		//--parse config
		if (!string.IsNullOrWhiteSpace(subjectConfig_Result))
		{
			calcSubject = subjectConfig_Result;
		}
		else
		{
			ruleLog.Add("WARNING: Subject Rule didn't return anything");
		}
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}


//==CALCULATE TEMPLATE OR MESSAGE==
if (!String.IsNullOrWhiteSpace(v_Template))
{
	calcTemplate = v_Template;
}
else if (!String.IsNullOrWhiteSpace(v_Template_Rule))
{
	var tplRuleParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	tplRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "ProcessorName",
		Value = v_Template_Rule
	});
	tplRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetType",
		Value = v_TargetType
	});
	tplRuleParams.AddParameter(new Parameter
	{
		Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
		Name = "TargetId",
		Value = v_targetId
	});

	var tplRuleResult = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = invokeRuleCode,
		Domain = appDomain,
		Parameters = tplRuleParams,
		Token = token
	});

	//parse response
	try
	{
		Newtonsoft.Json.Linq.JToken tplRuleData = Newtonsoft.Json.Linq.JObject.Parse(tplRuleResult.Data.ToJson())["DATA"][invokeRuleCode];
		int tplConfig_ErrorCode = Convert.ToInt32((string)tplRuleData.SelectToken("ERRORCODE"));
		string tplConfig_Result = (string)tplRuleData.SelectToken("RESULT");

		//--catch rule error
		if (tplConfig_ErrorCode != 0)
		{
			foundError = true;
			ruleLog.Add(String.Format(ruleErrTpl, invokeRuleCode, tplConfig_ErrorCode, (string)tplRuleData.SelectToken("ERRORMESSAGE")));
			goto Validation;
		}

		//--parse config
		if (!string.IsNullOrWhiteSpace(tplConfig_Result))
		{
			calcTemplate = tplConfig_Result;
		}
		else
		{
			ruleLog.Add("WARNING: Template Rule didn't return a template code");
		}
	}
	catch (Exception ex)
	{
		foundError = true;
		ruleLog.Add("ERROR: " + ex.ToString());
		goto Validation;
	}
}



//==CALL SEND EMAIL RULE==

const string sendEmailRule = "root_LTR_SendSimpleEmail";

var sendEmailParams = new ASF.Framework.Service.Parameters.ParameterCollection();
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "DistributionChannel", Value = v_DistributionChannel });
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetType", Value = v_TargetType });
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetId", Value = v_targetId });
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "From", Value = calcFrom });
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "To", Value = calcTo });
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Cc", Value = calcCC });
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Bcc", Value = calcBCC });
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Subject", Value = calcSubject });
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Template", Value = calcTemplate });
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Body", Value = v_Body });
sendEmailParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Attachments", Value = calcAttachments });

ruleLog.Add("INFO: Pushing to send rule");
var sendEmailResponse = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
{
	DataCommand = sendEmailRule,
	Domain = appDomain,
	Parameters = sendEmailParams,
	Token = token
});

//parse response
try
{
	Newtonsoft.Json.Linq.JToken sendRuleData = Newtonsoft.Json.Linq.JObject.Parse(sendEmailResponse.Data.ToJson())["DATA"][sendEmailRule];
	int sendConfig_ErrorCode = Convert.ToInt32((string)sendRuleData.SelectToken("ERRORCODE"));
	string sendConfig_Success = (string)sendRuleData.SelectToken("SUCCESSRESPONSE");

	//--catch rule error
	if (sendConfig_ErrorCode != 0)
	{
		foundError = true;
		ruleLog.Add(String.Format(ruleErrTpl, sendEmailRule, sendConfig_ErrorCode, (string)sendRuleData.SelectToken("ERRORMESSAGE")));
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
	ruleLog.Add(String.Format(msgTpl, "Error Code", 201));

	response["ERRORCODE"] = 201;
	response["ERRORMESSAGE"] = String.Join(System.Environment.NewLine, ruleLog);
	response["SUCCESSRESPONSE"] = String.Empty;

	//history info
	var historyParams = new ASF.Framework.Service.Parameters.ParameterCollection();
	historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetType", Value = v_TargetType });
	historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetId", Value = v_targetId });
	historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "MessageCode", Value = "EMAIL_FAILURE" });
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