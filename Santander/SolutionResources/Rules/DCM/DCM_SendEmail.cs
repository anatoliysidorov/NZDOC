var token = HttpUtility.UrlDecode((string)request["token"]);
var appDomain = (string)request["domain"];
var subject = (string)request["Subject"];
var body = (string)request["Body"];
var to = (string)request["To"];
var distributionChannel = (string)request["DistributionChannel"];
var attachmentURIs = (string)request["AttachmentURIs"];
var caseSysTypeId 	= (string)request["CaseSysType_Id"];     
var caseId 			= (string)request["Case_Id"];        
var taskId 			= (string)request["Task_Id"];

try
{
	var recipients = new List<ASF.Distribution.Common.Domain.Recipient>(){new ASF.Distribution.Common.Domain.Recipient("", to)};
	var attachments = new List<ASF.Framework.Service.Content.StorageContent>();
	
	foreach(string attachmentUrl in attachmentURIs.Split(new string[] {"|||"}, StringSplitOptions.RemoveEmptyEntries))
	{
		attachments.Add(new ASF.Framework.Service.Content.StorageContent(attachmentUrl));
	}
		
	var sendRequest = new ASF.Distribution.WebService.Messages.SendRequest()
	{
		Token = token,
		Domain = appDomain,
		Message = new ASF.Distribution.Common.Domain.ContentMessage(){ 
			From = new ASF.Distribution.Common.Domain.Recipient("TestMailer", "TestMailer@gmail.com"),
			Recipients = recipients.ToArray(),
			Body = new ASF.Framework.Service.Content.StringContent(body),
			Subject = new ASF.Framework.Service.Content.StringContent(subject),
			Attachments = attachments.ToArray()
		},
		Channel = distributionChannel
	};
	
	//-----------------------------------------------------
	// 						Send email
	//-----------------------------------------------------
	using (var client = new ASF.Distribution.WebService.Proxy.DistributionServiceSvc.DistributionServiceClient())
	{
		var sendResult = client.Send(sendRequest);											
	}
	
	
	//-----------------------------------------------------
	// 			Create HTML file and save it in CMS
	//-----------------------------------------------------
	
	
   var cmsFileName = "Email_" +Guid.NewGuid() + ".html";
		
	var cmsUri = "cms:///" + cmsFileName;
	var resultUrl = "";
	
	var fileContent = 
		@"<html><head><title>Email Description</title></head><body>
		<table>
			<tr><td style=""font-weight:bold"" width=""100px"">From: </td><td>@@FROM@@</td></tr>
			<tr><td style=""font-weight:bold"">Sent: </td><td>@@DATE@@</td></tr>
			<tr><td style=""font-weight:bold"">To: </td><td>@@TO@@</td></tr>
			<tr><td style=""font-weight:bold"">Subject: </td><td>@@SUBJECT@@</td></tr>
		</table>
		<br />
		@@BODY@@
		<br />
		<p style=""margin: 0in 0in 0.0001pt; font-size: 12pt; font-weight:bold;"">Attachments:</p>
		<table>
		@@ATTACHMENTS@@
		</table>
		</body>
		</html>";
		
	fileContent = fileContent.Replace("@@FROM@@", "TestMailer@gmail.com");
	fileContent = fileContent.Replace("@@DATE@@", DateTime.Now.ToString());
	fileContent = fileContent.Replace("@@TO@@", to);
	fileContent = fileContent.Replace("@@SUBJECT@@", subject);
	fileContent = fileContent.Replace("@@BODY@@", body);
	
	System.Text.StringBuilder sb = new System.Text.StringBuilder();
	foreach(string attachmentUrl in attachmentURIs.Split(new string[] {"|||"}, StringSplitOptions.RemoveEmptyEntries))
	{
		sb.Append(string.Format("<tr><td>- </td><td>{0}</td></tr>", attachmentUrl));
	}
	fileContent = fileContent.Replace("@@ATTACHMENTS@@", sb.ToString());
		
	
	response.Result.AddParameter(new Parameter() { Name = "CMSFileName", Value = cmsFileName });
		
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
		resultUrl = res.Url;
		response.Result.AddParameter(new Parameter() { Name = "ResultUrl", Value = resultUrl });
	}
	
	//-----------------------------------------------------
	// 				Create document
	//-----------------------------------------------------
	var rule_add_documents = "root_DOC_addDocuments";
	
	using (var dsClient = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
		var docParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "CaseSysType_Id", Value = caseSysTypeId });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "Case_Id", Value = caseId });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "Task_Id", Value = taskId });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "ParentFolder_Id", Value = null });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "fileNames_SV", Value = "Email_" + DateTime.Now.ToString("dd-MMM-yy")+".html" });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "urls_SV", Value = resultUrl });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "DocLocation_Code", Value = "CMS" });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "DocSource_Code", Value = "GENERATED" });
		
		var createDocResult = dsClient.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
												{
													DataCommand = rule_add_documents, 
													Domain = appDomain, 
													Parameters = docParameters, 
													Token = token
												});											
		var getPropertyResultJson = createDocResult.Data.ToJson();
		Newtonsoft.Json.Linq.JObject jObject = Newtonsoft.Json.Linq.JObject.Parse(getPropertyResultJson);
		var recordIdValue = jObject["DATA"][rule_add_documents]["RECORDID"];
		response.Result.AddParameter(new Parameter() { Name = "DocumentId", Value = (string)recordIdValue });
	}
	

	
}
catch (Exception ex)
{
	var errorMessage = "Unfortunately an error occurred during sending email ---- " + ex.ToString();
	response.Result.AddParameter(new Parameter() { Name = "Error", Value = errorMessage });
}