var token = HttpUtility.UrlDecode((string)request["token"]);
var appDomain = (string)request["domain"];
var to = request["To"] == null?string.Empty:(string)request["To"];
var distributionChannel = (string)request["notification_DefaultDistributionChannel"];
if(string.IsNullOrEmpty(distributionChannel))
{
	distributionChannel = "root_StandardOutgoing";
}

var templateCode = "root_UTIL_EmailTest";

try
{
	if(string.IsNullOrEmpty(to)){
		throw new System.Exception("Can not send mail without recipient address" );
		
	}	
	
	var recipients = new List<ASF.Distribution.Common.Domain.Recipient>();
	foreach(string recipient in to.Split(new string[] {","}, StringSplitOptions.RemoveEmptyEntries))
	{
		recipients.Add(new ASF.Distribution.Common.Domain.Recipient("", recipient));
	}
	
	var sendRequest = new ASF.Distribution.WebService.Messages.SendRequest()
	{
		Token = token,
		Domain = appDomain,
		Message = new ASF.Distribution.Common.Domain.TemplateMessage(){ 
			TemplateCode = templateCode,
			From = new ASF.Distribution.Common.Domain.Recipient("Do Not Reply", "dcmTemplate@eccentexcloud.com"),
			Recipients = recipients.ToArray()
		},
		Channel = distributionChannel 
				
	};

	using (var client = new ASF.Distribution.WebService.Proxy.DistributionServiceSvc.DistributionServiceClient())
	{
		var sendResult = client.Send(sendRequest);											
	}
	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = string.Empty });
	response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = "Message was succcessfully sent" });
	
}
catch (Exception ex)
{
	var errorMessage = ex.Message;
	response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
	response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = string.Empty });
}