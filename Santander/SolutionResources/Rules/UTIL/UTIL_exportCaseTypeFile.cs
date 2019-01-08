var token = HttpUtility.UrlDecode((string)request["token"]);
var appDomain = (string)request["domain"];
var to = "";//(string)request["To"];
var distributionChannel = (string)request["notification_DefaultDistributionChannel"];

//var Case_Id = 0;//(string)request["CaseId"];
var CaseType_Id = (string)request["CaseType_Id"];
var CaseType_Code = string.Empty;
var rule_exportCaseTypeXML = "root_UTIL_exportCaseTypeXML";
var rule_getCaseTypeInfo = "root_STP_getCaseTypes";
string cmsFileName = string.Empty; 
response["FileName"] = cmsFileName;
string cmsUri = "";
string caseTypeXML = "";
var errorCode = 0;
	
try
{
	using (var dsClientCode = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
       var reqParamCode = new ParameterCollection();
	   reqParamCode.AddParameter(new Parameter("CaseType_Id", ParameterType.Number(), ParameterDirection.Input, CaseType_Id));
	   var requestCode = new ASF.BDS.WebService.Messages.ExecuteRequest()
       {
          DataCommand = rule_getCaseTypeInfo, Domain = appDomain, Token = token, Parameters = reqParamCode,
       };
       var responseCode = dsClientCode.Execute(requestCode);
	   var ResultJson = responseCode.Data.ToJson();
		Newtonsoft.Json.Linq.JObject jObject = Newtonsoft.Json.Linq.JObject.Parse(ResultJson );
		var item = jObject["DATA"][rule_getCaseTypeInfo ]["ITEMS"][0]["CODE"];			
		var resParamsCode = responseCode.Data.GetParameters();
        response["Code"] = item.ToString().Replace("\"", string.Empty);
	    CaseType_Code = item.ToString().Replace("\"", string.Empty);
	}
     cmsFileName = "CaseType_"+CaseType_Code+"_"+DateTime.Now.ToString("yyyy-MMM-dd-HH-mm")+".xml";
	 cmsUri = "cms:///" + cmsFileName;
	using (var dsClient0 = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
       var reqParam1 = new ParameterCollection();
	   reqParam1.AddParameter(new Parameter("CaseType_Id", ParameterType.Number(), ParameterDirection.Input, CaseType_Id));
	   var request1 = new ASF.BDS.WebService.Messages.ExecuteRequest()
       {
          DataCommand = rule_exportCaseTypeXML, Domain = appDomain, Token = token, Parameters = reqParam1,
       };
       var response1 = dsClient0.Execute(request1);
       var resParams1 = response1.Data.GetParameters();
       response["CaseTypeXML"] = resParams1["CaseTypeXML"].Value;
	   response["ErrorCode"] = resParams1["ErrorCode"].Value;
	   response["ErrorMessage"] = resParams1["ErrorMessage"].Value;
	   response["SuccessResponse"] = resParams1["SuccessMessage"].Value;
       errorCode = Convert.ToInt32(resParams1["ErrorCode"].Value);
	   caseTypeXML = (string) response["CaseTypeXML"];
	}
	if (errorCode == 0) {
		var fileContent = caseTypeXML;
		//response.Result.AddParameter(new Parameter() { Name = "CMSFileName", Value = cmsFileName });
		var cmsRequest = new ASF.CMS.WebService.Messages.CreateResourceRequest()
		{
			Token = token,
			Domain = appDomain,
			Url = cmsUri,
			Resource = new ASF.CMS.Common.Domain.Resource()
			{
				Buffer = System.Text.Encoding.UTF8.GetBytes(fileContent),
				ContentType = "text/plain",
				Length = fileContent.Length,
				OriginalFileName = cmsFileName
			}
		};

		using (var cmsClient = new ASF.CMS.WebService.Proxy.CMSServiceSvc.CMSServiceClient())
		{
			var res = cmsClient.CreateResource(cmsRequest);
			string resultUrl  = res.Url;
			response.Result.AddParameter(new Parameter() { Name = "CaseType_CMS_URL", Value = resultUrl });
		}
		
	}
	
}
catch (Exception ex)
{
	var errorMessage = ex.ToString();
	response.Result.AddParameter(new Parameter() { Name = "Error", Value = errorMessage });
}

