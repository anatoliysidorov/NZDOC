var token = HttpUtility.UrlDecode((string)request["token"]);
var appDomain = (string)request["domain"];
var to = (string)request["To"];
var distributionChannel = (string)request["DistributionChannel"];
var attachmentURIs = (string)request["AttachmentURIs"] ?? "";
var templateCode = (string)request["TemplateCode"];

// relationship id's
var Case_Id = (string)request["Case_Id"];
var Task_Id = (string)request["Task_Id"];
var DocLocation_Code = "CMS";
var DocSource_Code = "EMAIL_OUT";

try
{
	var recipients = new List<ASF.Distribution.Common.Domain.Recipient>(){new ASF.Distribution.Common.Domain.Recipient("", to)};
	var attachments = new List<ASF.Framework.Service.Content.StorageContent>();
	
	foreach(string attachmentUrl in attachmentURIs.Split(new string[] {"|||"}, StringSplitOptions.RemoveEmptyEntries))
	{
		attachments.Add(new ASF.Framework.Service.Content.StorageContent(attachmentUrl));
	}
	var bkParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
        bkParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "Case_Id", Value = Case_Id  });	
	var sendRequest = new ASF.Distribution.WebService.Messages.SendRequest()
	{
		Token = token,
		Domain = appDomain,
		Message = new ASF.Distribution.Common.Domain.TemplateMessage(){ 
			TemplateCode = templateCode,
			From = new ASF.Distribution.Common.Domain.Recipient("Do Not Reply", "dcmTemplate@eccentexcloud.com"),
			Recipients = recipients.ToArray(),
			Attachments = attachments.ToArray(),
                        Parameters = bkParameters
		},
		Channel = distributionChannel//, 
                
	};
        
        //sendRequest.Parameters.AddRange(request.Parameters);
	
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
	
	
	// get subject and body from template
	ParameterCollection prms = new ParameterCollection();
        prms.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "Case_Id", Value = Case_Id  });
	var previewRequest = new ASF.CoreLib.Messages.EmailPreviewRequest()
	{
		Token = token,
		Domain = appDomain,
		TemplateCode = templateCode,
		Parameters = prms
	};
				
	//generate emailPreview
	ASF.CoreLib.Messages.EmailPreviewResponse resolvedEmail = ASF.CoreLib.APIHelper.GenerateEmailPreview(previewRequest);
	
		
	// generate html file 
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
		
	fileContent = fileContent.Replace("@@FROM@@", "dcmTemplate@eccentexcloud.com");
	fileContent = fileContent.Replace("@@DATE@@", DateTime.Now.ToString());
	fileContent = fileContent.Replace("@@TO@@", to);
	fileContent = fileContent.Replace("@@SUBJECT@@", resolvedEmail.Subject);
	fileContent = fileContent.Replace("@@BODY@@", resolvedEmail.Body);
	
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
	// 				Create document record
	//-----------------------------------------------------
	var rule_add_documents = "root_DOC_addDocuments2";
	
	using (var dsClient = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
	{
		var docParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "fileNames_SV", Value = cmsFileName });
		//docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "ParentFolder_Id", Value = "375" });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "urls_SV", Value = resultUrl });
		//docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "Task_Id", Value = Task_Id  });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "Case_Id", Value = Case_Id  });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "DocLocation_Code", Value = DocLocation_Code   });
		docParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "DocSource_Code", Value = DocSource_Code   });		
		
		var createDocResult = dsClient.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
												{
													DataCommand = rule_add_documents, 
													Domain = appDomain, 
													Parameters = docParameters, 
													Token = token
												});											
		var getPropertyResultJson = createDocResult.Data.ToJson();
		Newtonsoft.Json.Linq.JObject jObject = Newtonsoft.Json.Linq.JObject.Parse(getPropertyResultJson);
		var recordIdValue = jObject["DATA"][rule_add_documents]["RECORDIDS"];
		response.Result.AddParameter(new Parameter() { Name = "DocumentId", Value = (string)recordIdValue });
	}
	
	
	
	
}
catch (Exception ex)
{
	var errorMessage = "Unfortunately an error occurred during sending email ---- " + ex.ToString();
	response.Result.AddParameter(new Parameter() { Name = "Error", Value = errorMessage });
}