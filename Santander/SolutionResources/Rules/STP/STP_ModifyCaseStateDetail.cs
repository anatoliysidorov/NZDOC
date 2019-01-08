var token = HttpUtility.UrlDecode((string)request["token"]);
var domain = request.AsString("domain");
int v_stateConfigId = 0;
string v_xmlConfig = request.AsString("CONFIG");
string v_stateConfigName = request.AsString("NAME");
string v_stateConfigCode = request.AsString("CODE");
string v_stateConfigIconCode = request.AsString("ICONCODE");
string s_stateConfigIsDeleted = request.AsString("IsDeleted");
bool v_stateConfigIsDeleted = false;

Int32.TryParse(request.AsString("Id"), out v_stateConfigId);
Boolean.TryParse(request.AsString("IsDeleted"), out v_stateConfigIsDeleted);

//Calculated
int errorCode = 0;
string errorMessage = "";
System.Xml.Linq.XDocument xmlDoc = null;
ParameterCollection inputParameters = null;
Dictionary<int, int> dCaseStates = new Dictionary<int, int>();

/*
	  1. Check input parameters
	  1.1. If Config is null then return an error: Milestone Data is missing
	  1.2. If IsDeleted is 1 then return an error: Milestone is disabled
  */
if (v_stateConfigId == 0)
{
	response["ErrorCode"] = 101;
	response["ErrorMessage"] = "Id is required field.";
	return response;
}

if (String.IsNullOrEmpty(v_xmlConfig))
{
	response["ErrorCode"] = 101;
	response["ErrorMessage"] = "Milestone data is missing.";
	return response;
}

if (v_stateConfigIsDeleted == true)
{
	response["ErrorCode"] = 101;
	response["ErrorMessage"] = "Milestone is disabled. We can't modify it.";
	return response;
}

Func<ASF.BDS.WebService.Messages.ExecuteResponse, string, string, string> getValueFromResponse = (resp, ruleName, paramName) =>
{
	string result = "";
	System.Xml.XmlNode nodeEl = null;

	try
	{
		ParameterCollection respParams = resp.Data.GetParameters();

		if (respParams != null && respParams.Count > 0)
		{
			Object obj = respParams[paramName].Value;

			if (obj != null)
			{
				result = obj.ToString();
			}
		}
		else {
			var xmlResp = resp.Data.ToXml();

			System.Xml.XmlDocument xmlDocTemp = new System.Xml.XmlDocument();
			xmlDocTemp.LoadXml(xmlResp.ToString());

			if (xmlDocTemp != null)
			{
				nodeEl = xmlDocTemp.SelectSingleNode(string.Format("//DATA/{0}/ITEMS/{1}", ruleName, paramName));

				if (nodeEl != null)
				{
					result = nodeEl.InnerText;
				}
			}
		}
		
	}
	catch (Exception exp)
	{
		throw new Exception(string.Format("Exception on get value from rule {0} response", ruleName), exp);
	}

	return result;
};

Func<System.Xml.Linq.XElement, string, string> getValueFromMxCell = (item, attrName) => {
	string v = null;

	try
	{
		v = item.Descendants("Object")
			.Select(e => e.Attribute(attrName).Value)
			.FirstOrDefault();
	}
	catch (Exception exp) {
	}

	return v;
};

Func<System.Xml.Linq.XElement, string, string> getAttributeValueFromXML = (el, attrName) => {
	string result = "";
	System.Xml.Linq.XAttribute attr = null;

	attr = el.Attribute(attrName);

	if (attr != null)
	{
		result = attr.Value;
	}

	return result;
};

try
{           

	/*
		2. Check if Milestone has links with CaseType (that has cases), if it exists then call rule STP_cloneStateConfig
	*/
	inputParameters = new ParameterCollection();
	inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "Id", Value = v_stateConfigId });

	var resGetStateConf = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_STP_getStateConfig",
		Domain = domain,
		Parameters = inputParameters,
		Token = token
	});

	int v_casesCount = 0;
	Int32.TryParse(getValueFromResponse(resGetStateConf, "root_STP_getStateConfig", "CASESCOUNT"), out v_casesCount);

	if (v_casesCount > 0) {
		inputParameters = new ParameterCollection();
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "SOURCEID", Value = v_stateConfigId });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "NAME", Value = v_stateConfigName });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "CODE", Value = v_stateConfigCode });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "ICONCODE", Value = v_stateConfigIconCode });	
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "isCloneWithOptions", Value = 1 });

		var resCloneStateConfig = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = "root_STP_cloneStateConfig",
			Domain = domain,
			Parameters = inputParameters,
			Token = token
		});
		
		Int32.TryParse(getValueFromResponse(resCloneStateConfig, "root_STP_cloneStateConfig", "ERRORCODE"), out errorCode);
		errorMessage = getValueFromResponse(resCloneStateConfig, "root_STP_cloneStateConfig", "ERRORMESSAGE");

		if (errorCode > 0 && !String.IsNullOrEmpty(errorMessage)) {
			throw new Exception(errorMessage);
		}
	}

	/*
		3. Clean CaseSetup and CaseTransition
	*/
	inputParameters = new ParameterCollection();
	inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "STATECONFIG", Value = v_stateConfigId });

	var respCleanMilestoneDetail = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_STP_WrapDestroyCaseStateDetail",
		Domain = domain,
		Parameters = inputParameters,
		Token = token
	});

	Int32.TryParse(getValueFromResponse(respCleanMilestoneDetail, "root_STP_WrapDestroyCaseStateDetail", "ERRORCODE"), out errorCode);
	errorMessage = getValueFromResponse(respCleanMilestoneDetail, "root_STP_WrapDestroyCaseStateDetail", "ERRORMESSAGE");

	if (errorCode > 0 && !String.IsNullOrEmpty(errorMessage)) {
		throw new Exception(errorMessage);
	}

	// Get XDocument Object
	xmlDoc = System.Xml.Linq.XDocument.Parse(v_xmlConfig);

	/*
		4. For each mxCell = milestone, call rule STP_CreateCaseState
	*/
	foreach (System.Xml.Linq.XElement item in xmlDoc.Descendants("mxCell")
											.Where(e => (string)e.Attribute("type") == "milestone")) {
		
		inputParameters = new ParameterCollection();
		
		string v_tmpName = getValueFromMxCell(item, "NAME");
		string v_tmpCode = getValueFromMxCell(item, "CODE");
		string v_tmpDesc = getValueFromMxCell(item, "DESCRIPTION");
		string v_tmpIsDefaultOnCreate = getValueFromMxCell(item, "ISDEFAULTONCREATE") ?? "0";
		string v_tmpFlag = getValueFromMxCell(item, "FLAG");
		int v_tmpIsStart = v_tmpFlag == "ISSTART"? 1: 0;
		int v_tmpIsFinish = v_tmpFlag == "ISFINISH" ? 1 : 0;

		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "NAME", Value = v_tmpName });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "CODE", Value = v_tmpCode });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "DESCRIPTION", Value = v_tmpDesc });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "ISDEFAULTONCREATE", Value = v_tmpIsDefaultOnCreate});
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "ISSTART", Value = v_tmpIsStart });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "ISFINISH", Value = v_tmpIsFinish });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "STATECONFIG", Value = v_stateConfigId });
		
		var respCreateCaseState = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = "root_STP_CreateCaseState",
			Domain = domain,
			Parameters = inputParameters,
			Token = token
		});

		Int32.TryParse(getValueFromResponse(respCreateCaseState, "root_STP_CreateCaseState", "ERRORCODE"), out errorCode);
		errorMessage = getValueFromResponse(respCreateCaseState, "root_STP_CreateCaseState", "ERRORMESSAGE");

		if (errorCode > 0 && !String.IsNullOrEmpty(errorMessage))
		{
			throw new Exception(errorMessage);
		}

		//Save created case state Id, and map it with MxCell Id
		int v_tmpStateId = 0;
		int v_tmpMxCellId = 0;
		Int32.TryParse(getValueFromResponse(respCreateCaseState, "root_STP_CreateCaseState", "OUTPUT_STATEID"), out v_tmpStateId);
		Int32.TryParse(getAttributeValueFromXML(item, "id"), out v_tmpMxCellId);                        

		if (v_tmpStateId > 0 && v_tmpMxCellId > 0) {
			dCaseStates.Add(v_tmpMxCellId, v_tmpStateId);
		}
	}

	/*
		5. For each mxCell = connection, call rule STP_CreateCaseTransition
	*/
	foreach (System.Xml.Linq.XElement item in xmlDoc.Descendants("mxCell")
											.Where(e => (string)e.Attribute("type") == "connection"))
	{

		inputParameters = new ParameterCollection();

		string v_tmpName = getValueFromMxCell(item, "NAME");
		string v_tmpCode = getValueFromMxCell(item, "CODE");
		string v_tmpDesc = getValueFromMxCell(item, "DESCRIPTION");
		string v_tmpIsNextDefault = getValueFromMxCell(item, "ISDEFAULT");
		int v_tmpSourceStateId = 0;
		int v_tmpTargetStateId = 0;
		int mxCellSourceId = 0;
		int mxCellTargetId = 0;

		Int32.TryParse(getAttributeValueFromXML(item, "source"), out mxCellSourceId);
		Int32.TryParse(getAttributeValueFromXML(item, "target"), out mxCellTargetId);
		dCaseStates.TryGetValue(mxCellSourceId, out v_tmpSourceStateId);
		dCaseStates.TryGetValue(mxCellTargetId, out v_tmpTargetStateId);

		if (v_tmpSourceStateId == 0 || v_tmpTargetStateId == 0) {
			throw new Exception("Case Transition doestn't have source or target.");
		}

		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "NAME", Value = v_tmpName });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "CODE", Value = v_tmpCode });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "DESCRIPTION", Value = v_tmpDesc });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "SOURCESTATE", Value = v_tmpSourceStateId });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "TARGETSTATE", Value = v_tmpTargetStateId });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "ISNEXTDEFAULT", Value = v_tmpIsNextDefault });
		inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "STATECONFIG", Value = v_stateConfigId });

			var respCreateCaseTransition = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
			{
				DataCommand = "root_STP_CreateCaseTransition",
				Domain = domain,
				Parameters = inputParameters,
				Token = token
			});

			Int32.TryParse(getValueFromResponse(respCreateCaseTransition, "root_STP_CreateCaseTransition", "ERRORCODE"), out errorCode);
			errorMessage = getValueFromResponse(respCreateCaseTransition, "root_STP_CreateCaseTransition", "ERRORMESSAGE");

			if (errorCode > 0 && !String.IsNullOrEmpty(errorMessage))
			{
				throw new Exception(errorMessage);
			}
	}

	/*
		6. Call rule STP_CreateModifyStateConfig with params:
	*/
	inputParameters = new ParameterCollection();
	inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "Id", Value = v_stateConfigId });
	inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "ISUPDATECONFIG", Value = 1 });
	inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "Config", Value = v_xmlConfig });
	
	var respModifyStateConfig = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_STP_CreateModifyStateConfig",
		Domain = domain,
		Parameters = inputParameters,
		Token = token
	});

	Int32.TryParse(getValueFromResponse(respModifyStateConfig, "root_STP_CreateModifyStateConfig", "ERRORCODE"), out errorCode);
	errorMessage = getValueFromResponse(respModifyStateConfig, "root_STP_CreateModifyStateConfig", "ERRORMESSAGE");

	if (errorCode > 0 && !String.IsNullOrEmpty(errorMessage))
	{
		throw new Exception(errorMessage);
	}

	response["MESS_MILESTONE_NAME"] = v_stateConfigName;
	response["SuccessResponse"] = "Milestone {{MESS_MILESTONE_NAME}} was successfully modified";
}
catch (Exception exp)
{
	//If we will get an error then we need  to clean all created data
	inputParameters = new ParameterCollection();
	inputParameters.AddParameter(new Parameter { Type = ParameterType.Text(), Name = "STATECONFIG", Value = v_stateConfigId });

	var respCleanMilestoneDetail = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_STP_WrapDestroyCaseStateDetail",
		Domain = domain,
		Parameters = inputParameters,
		Token = token
	});
	
	response["ErrorCode"] = errorCode == 0? 101: errorCode;
	response["ErrorMessage"] = exp.ToString();
	response["SuccessResponse"] = string.Empty;
}