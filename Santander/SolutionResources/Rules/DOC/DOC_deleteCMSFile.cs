var token = HttpUtility.UrlDecode((string)request["token"]);
var appDomain = (string)request["domain"];
var url = (string)request["CMS_URL"];

try
{
	var cmsRequest = new ASF.CMS.WebService.Messages.DeleteResourceRequest()
	{
		Token = token,
		Domain = appDomain,
		Url = url		
	};
	
	using (var cmsClient = new ASF.CMS.WebService.Proxy.CMSServiceSvc.CMSServiceClient())
	{
		var res = cmsClient.DeleteResource(cmsRequest);
		response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = res.ErrorCode });
		response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = res.ErrorMessage });
	}
		
}
catch (Exception ex)
{
	var errorMessage = "Unfortunately an error occurred deleting file from CMS ---- " + ex.ToString();
	response.Result.AddParameter(new Parameter() { Name = "Error", Value = errorMessage });
}