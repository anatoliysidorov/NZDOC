var token = HttpUtility.UrlDecode((string)request["token"]);
var domain = request.AsString("domain");
int orgChartId = Int32.Parse(request.AsString("ID"));
var newConfigXML = request.AsString("CONFIG");
var v_chartName = request.AsString("NAME");
var v_chartCode = request.AsString("CODE");

//Rule params
string prevConfigXML = null;

List<Object> listOfNewCaseWorkers = null;
List<Object> listOfPrevCaseWorkers = null;
List<Object> listCWToDelete = null;
List<Object> listCWToAdd = null;
string ruleGetCharts = "root_PPL_ORG_GetCharts";
string ruleModifyChart = "root_PPL_ORG_CreateModifyChart";
string ruleCreateLink = "root_PPL_ORG_CreateWorkerLink";
string ruleDeleteLink = "root_PPL_ORG_DeleteWorkerLink";
string errorCode = ""; 
string errorMessage = "";
string successResponse = "";
ParameterCollection inputParameters = null;

Func<ASF.BDS.WebService.Messages.ExecuteResponse, string, string> getValueFromResponse = (resp, paramName) =>
{
	string result = "";

	ParameterCollection respParams = resp.Data.GetParameters();
	Object obj = "";

	if (respParams != null && respParams.Count > 0) {
		obj = respParams[paramName].Value;

		if (obj != null) {
			result = obj.ToString();
		}
	}

	return result;
};

Func<ASF.BDS.WebService.Messages.ExecuteResponse, string, string, string> getValueFromXMLResponse = (resp, ruleName, value) =>
{
	string result = "";
	System.Xml.XmlNode nodeEl = null;

	try
	{
		var xmlResp = resp.Data.ToXml();

		System.Xml.XmlDocument xmlDoc = new System.Xml.XmlDocument();
		xmlDoc.LoadXml(xmlResp.ToString());

		if (xmlDoc != null)
		{
			nodeEl = xmlDoc.SelectSingleNode(string.Format("//DATA/{0}/ITEMS/{1}", ruleName, value));

			if (nodeEl != null)
			{
				result = nodeEl.InnerText;
			}
		}
	}
	catch (Exception exp)
	{
		string mesText = "Exception on get value from rule {{MESS_RULENAME}} response";

		var typeLargeText = ASF.Framework.Service.Parameters.ParameterType.LargeText();
		object objMessageParams = new { MESS_RULENAME = ruleName };
		var jsonParams = Newtonsoft.Json.JsonConvert.SerializeObject(objMessageParams);
		var i18NParams = new ASF.Framework.Service.Parameters.ParameterCollection();
		i18NParams.AddParameter(new Parameter { Type = typeLargeText, Name = "MessageText", Value = mesText });
		i18NParams.AddParameter(new Parameter { Type = typeLargeText, Name = "MessageParams", Value = jsonParams });
		var i18NResponse = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = "root_LOC_i18n_invocation",
			Domain = domain,
			Parameters = i18NParams,
			Token = token
		});
		var resultI18N = i18NResponse.Data.GetParameters();
		mesText = resultI18N["MessageResult"].Value.ToString();	

		throw new Exception(mesText, exp);
	}

	return result;
};

Func<System.Xml.Linq.XElement, string, string> getAttributeValue = (el, attrName) => {
	string result = "";
	System.Xml.Linq.XAttribute attr = null;

	attr = el.Attribute(attrName);

	if (attr != null) {
		result = attr.Value;
	}

	return result;
};

Func<Object, string, Object> getValueFromObject = (obj, path) => {
	Object result = null;

	try
	{
		System.Reflection.PropertyInfo pi = obj.GetType().GetProperty(path);
		result = pi.GetValue(obj, null);
	}
	catch (Exception exp) {
		throw new Exception("Exception on get value from object", exp);
	}

	return result;
};

Func<List<Object>, string> getXMLFromObject = (listOfObj) =>
{
	string xml = "<ITEMS>";
	Object parentId = null;
	Object childId = null;

	foreach (var item in listOfObj)
	{
		parentId = getValueFromObject(item, "parentId");
		childId = getValueFromObject(item, "childId");

		if (parentId != null && childId != null) {
			xml += string.Format(
			   "<ITEM>" +
				   "<PARENTID>{0}</PARENTID>" +
				   "<CHILDID>{1}</CHILDID>" +
			   "</ITEM>",
			   Int32.Parse(parentId.ToString()),
			   Int32.Parse(childId.ToString())
			);
		}
	}

	xml += "</ITEMS>";

	return xml;
};

Func<System.Xml.Linq.XDocument, List<Object>> getConnectionList = (xml) => {
	List<Object> listConn = new List<Object>();

	//Get only connections
	foreach (System.Xml.Linq.XElement item in xml.Descendants("mxCell")
												.Where(e => (string)e.Attribute("type") == "connection"))
	{

		int sourceCWId,
			source = -1,
			target = -1,
			targetCWId;

		string sourceCWName = "",
				targetCWName = "",
				sSource = "",
				sTarget = "";

		sSource = getAttributeValue(item, "source");
		sTarget = getAttributeValue(item, "target");

		if (!String.IsNullOrEmpty(sSource)) {
			source = Int32.Parse(sSource);
		}

		if (!String.IsNullOrEmpty(sTarget))
		{
			target = Int32.Parse(sTarget);
		}

		if (source != -1 && target != -1) {
			var sourceAttr = xml.Descendants("mxCell")
							   .First(e => (int)e.Attribute("id") == source);

			var targetAttr = xml.Descendants("mxCell")
							   .First(e => (int)e.Attribute("id") == target);

			if (sourceAttr != null && targetAttr != null)
			{
				try
				{
					sourceCWId = Int32.Parse(sourceAttr.Descendants("Object")
								   .Select(e => e.Attribute("cwid").Value)
								   .FirstOrDefault());
					targetCWId = Int32.Parse(targetAttr.Descendants("Object")
										.Select(e => e.Attribute("cwid").Value)
										.FirstOrDefault());
				 
					listConn.Add(
						new
						{
							parentId = sourceCWId,
							childId = targetCWId
						}
					);
				}
				catch (Exception exp)
				{
					Ecx.Rule.Helpers.BDSHelper.LogError("ErrorMessage: " + exp.ToString(), null);
				}
			}
		}
	}

	return listConn;
};

try
{
	// 1. Call rule root_PPL_ORG_GetCharts, and get previous config xml.
	inputParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
	inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "OrgChart_Id", Value = orgChartId });

	var getChartsResp = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = ruleGetCharts,
		Domain = domain,
		Parameters = inputParameters,
		Token = token
	});

	prevConfigXML = getValueFromXMLResponse(getChartsResp, ruleGetCharts, "CONFIG");
	prevConfigXML = System.Web.HttpUtility.HtmlDecode(prevConfigXML);

	//2. Get All Case Workers from previous configuration XML
	if (!String.IsNullOrEmpty(prevConfigXML))
	{
		System.Xml.Linq.XDocument xmlPrev = System.Xml.Linq.XDocument.Parse(prevConfigXML);
		listOfPrevCaseWorkers = getConnectionList(xmlPrev);
	}

	//3. Get All Case Workers from new configuration XML
	if (!String.IsNullOrEmpty(newConfigXML))
	{
		System.Xml.Linq.XDocument xmlNew = System.Xml.Linq.XDocument.Parse(newConfigXML);
		listOfNewCaseWorkers = getConnectionList(xmlNew);
	}

	//4. Compare new and previous configuration XML 
	if (listOfPrevCaseWorkers != null && listOfNewCaseWorkers != null)
	{
		listCWToAdd = listOfNewCaseWorkers.Except(listOfPrevCaseWorkers).ToList();
		listCWToDelete = listOfPrevCaseWorkers.Except(listOfNewCaseWorkers).ToList();
	}
	else {
		if (listOfNewCaseWorkers != null)
		{
			listCWToAdd = listOfNewCaseWorkers;
		}

		if (listOfPrevCaseWorkers != null)
		{
			listCWToDelete = listOfPrevCaseWorkers;
		}
	}

	//5.1. Add records
	if (listCWToAdd != null && listCWToAdd.Count > 0) {

		inputParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
		inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "OrgChartId", Value = orgChartId });
		inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "DATAXML", Value = getXMLFromObject(listCWToAdd) });

		var respCreateLink = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = ruleCreateLink,
			Domain = domain,
			Parameters = inputParameters,
			Token = token
		});

	}

	//5.2. Remove records
	if (listCWToDelete != null && listCWToDelete.Count > 0)
	{
		inputParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
		inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "OrgChartId", Value = orgChartId });
		inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "DATAXML", Value = getXMLFromObject(listCWToDelete) });

		var respDeleteLink = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
		{
			DataCommand = ruleDeleteLink,
			Domain = domain,
			Parameters = inputParameters,
			Token = token
		});
	}

	//5.3. Update config
	inputParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
	inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CONFIG", Value = newConfigXML });
	inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "NAME", Value = v_chartName });
	inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CODE", Value = v_chartCode });
	inputParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "ID", Value = orgChartId });

	var respModifyChart = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = ruleModifyChart,
		Domain = domain,
		Parameters = inputParameters,
		Token = token
	});

	errorMessage = getValueFromResponse(respModifyChart, "ERRORMESSAGE");
	errorCode = getValueFromResponse(respModifyChart, "ERRORCODE");
	successResponse = getValueFromResponse(respModifyChart, "SUCCESSRESPONSE");

	//Exit with error if rule returns an error
	if (!string.IsNullOrEmpty(errorMessage))
	{
		throw new Exception(errorMessage);
	}

	response["SuccessResponse"] = successResponse;
} catch (Exception exp) {
	response["ErrorCode"] = !String.IsNullOrEmpty(errorCode) ? errorCode: "101";
	response["ErrorMessage"] = exp.ToString();
	response["SuccessResponse"] = string.Empty;
}