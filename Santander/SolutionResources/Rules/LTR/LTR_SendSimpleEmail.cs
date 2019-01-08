//------------------------------------Start rule ------------------------------------
var token = request.AsString("token");
var appDomain = request.AsString("domain");

//system info
Boolean foundError = false;
List<String> ruleLog = new List<String>();
ruleLog.Add("==LTR_SendSimpleEmail==");

//input params
string v_targetId = request.AsString("TargetID");
string v_TargetType = request.AsString("TargetType").ToLower();
string v_To = request.AsString("To");
string v_CC = request.AsString("Cc");
string v_BCC = request.AsString("Bcc");
string v_From = request.AsString("From");
string v_Attachments = request.AsString("Attachments");
string v_Template = request.AsString("Template");
string v_Subject = request.AsString("Subject");
string v_Body = request.AsString("Body");
string v_DistributionChannel = request.AsString("DistributionChannel");
var v_testMode = 0;
if(!string.IsNullOrWhiteSpace(request.AsString("TestMode"))){
	v_testMode = Convert.ToInt32(request.AsString("TestMode"));
}


//calculated fields
string calcFrom = String.Empty;
var calcRecipients = new List<ASF.CoreLib.Messages.RecipientInfo>();
var calcAttachments = new List<ASF.Framework.Service.Content.StorageContent>();
var calcTplParams = new ASF.Framework.Service.Parameters.ParameterCollection();
string genPDFofEmail = String.Empty;


//==PARAMETER PRE-CHECK==
if (string.IsNullOrWhiteSpace(v_To) && string.IsNullOrWhiteSpace(v_CC) && string.IsNullOrWhiteSpace(v_BCC))
{
	foundError = true;
	ruleLog.Add("ERROR: Can't send email because neither TO, CC or BCC is provided");
	goto Validation;
}
if (string.IsNullOrWhiteSpace(v_Template) && string.IsNullOrWhiteSpace(v_Body))
{
	foundError = true;
	ruleLog.Add("ERROR: Can't send email because both TEMPLATE and BODY is missing");
	goto Validation;
}
if (string.IsNullOrWhiteSpace(v_DistributionChannel))
{
	foundError = true;
	ruleLog.Add("ERROR: Can't send email because the Distribution Channel is missing");
	goto Validation;
}

//==POPULATE TO, CC and BCC==
ASF.CoreLib.Messages.RecipientInfo recItem;
string[] toArray = v_To.Split(new string[] { ",", ";", "|||" }, StringSplitOptions.RemoveEmptyEntries);
foreach (string toItem in toArray)
{
	calcRecipients.Add(new ASF.CoreLib.Messages.RecipientInfo(toItem, ASF.CoreLib.Messages.RecipientType.To));
	ruleLog.Add("INFO: Sending TO - " + toItem);
}

string[] ccArray = v_CC.Split(new string[] { ",", ";", "|||" }, StringSplitOptions.RemoveEmptyEntries);
foreach (string ccItem in ccArray)
{
	calcRecipients.Add(new ASF.CoreLib.Messages.RecipientInfo(ccItem, ASF.CoreLib.Messages.RecipientType.Cc));
	ruleLog.Add("INFO: Sending CC - " + ccItem);
}

string[] bccArray = v_BCC.Split(new string[] { ",", ";", "|||" }, StringSplitOptions.RemoveEmptyEntries);
foreach (string bccItem in bccArray)
{
	calcRecipients.Add(new ASF.CoreLib.Messages.RecipientInfo(bccItem, ASF.CoreLib.Messages.RecipientType.Bcc));
	ruleLog.Add("INFO: Sending BCC - " + bccItem);
}


//==POPULATE ATTACHMENTS==
string[] attchArray = v_Attachments.Split(new string[] { ",", ";", "|||" }, StringSplitOptions.RemoveEmptyEntries);
foreach (string attchItem in attchArray)
{
	calcAttachments.Add(new ASF.Framework.Service.Content.StorageContent(attchItem));
	ruleLog.Add("INFO: Sending attachment - " + attchItem);
}


//==ADD ADDITIONAL PARAMETER CONTEXT TO TEMPLATE GENERATOR==
calcTplParams.AddRange(request.Parameters); //add all input params into this rule as well
switch (v_TargetType)
{
	case "case":
		calcTplParams.AddParameter(new Parameter("CaseId", ParameterType.btype_text, 255, ParameterDirection.Input, v_targetId));
		break;
	case "task":
		calcTplParams.AddParameter(new Parameter("TaskId", ParameterType.btype_text, 255, ParameterDirection.Input, v_targetId));
		break;
	case "externalparty":
		calcTplParams.AddParameter(new Parameter("ExternalPartyId", ParameterType.btype_text, 255, ParameterDirection.Input, v_targetId));
		break;
}
ruleLog.Add("INFO: Context " + v_TargetType + " with ID " + v_targetId);

//==SEND EMAIL==
try
{
	var sendEmailRequest = new ASF.CoreLib.Messages.SendEmailRequest();
	sendEmailRequest.Domain = appDomain;
	sendEmailRequest.Token = token;
	sendEmailRequest.Channel = v_DistributionChannel;
	sendEmailRequest.Subject = v_Subject;
	sendEmailRequest.Recipients = calcRecipients.ToArray();
	sendEmailRequest.From = v_From;
	sendEmailRequest.IsBodyHtml = true;
	sendEmailRequest.Parameters = calcTplParams;
	sendEmailRequest.Attachments = calcAttachments.ToArray();
	sendEmailRequest.UploadConvertedToPDFEmailToCMS = true;

	if (!string.IsNullOrWhiteSpace(v_Body))
	{
		ruleLog.Add("INFO: The email body was provided");
		sendEmailRequest.Body = v_Body;
	}
	else
	{
		ruleLog.Add("INFO: The email body will be generated from the Letter Template " + v_Template);
		sendEmailRequest.TemplateCode = v_Template;
	}

	ruleLog.Add("INFO: Attempting to send email");
	var sendResponse = ASF.CoreLib.APIHelper.SendEmail(sendEmailRequest);
	genPDFofEmail = sendResponse.ConvertedToPDFEmailCMSUrl;
	ruleLog.Add("INFO: Email sent and saved to " + genPDFofEmail);
}
catch (Exception e)
{
	foundError = true;
	ruleLog.Add("ERROR: There was an error sending the email most likely because of incorrect SMTP settings");
	ruleLog.Add("<code>" + e.ToString().Replace(System.Environment.NewLine, "<br>") + "</code>");
	goto Validation;
}

Validation:
const string msgTpl = "<p><b>{0}:</b> {1}</p>";
string historyMsgCode = String.Empty;
List<String> additionalInfo = new List<String>();

//set response information
if (foundError)
{
	response["ERRORCODE"] = 101;
	response["ERRORMESSAGE"] = HttpUtility.HtmlEncode(String.Join(System.Environment.NewLine, ruleLog));
	response["SUCCESSRESPONSE"] = String.Empty;

	//history info
	additionalInfo.Add(String.Format(msgTpl, "Error Code", 101));
	additionalInfo.Add(HttpUtility.HtmlEncode(String.Join(System.Environment.NewLine, ruleLog)));
	historyMsgCode = "EMAIL_FAILURE";
}
else
{
	response["ERRORCODE"] = 0;
	response["ERRORMESSAGE"] = String.Empty;
	
	if(v_testMode == 1){
		response["SUCCESSRESPONSE"] = "Email sent to " + v_To + " from " + v_From;
	} else {
		response["SUCCESSRESPONSE"] = HttpUtility.HtmlEncode(String.Join(System.Environment.NewLine, ruleLog));
	}

	//history info
	historyMsgCode = "EMAIL_SUCCESS";
	additionalInfo.Add("{[this.GET_CMS_URL('" + genPDFofEmail + "')]}");
}

var historyParams = new ASF.Framework.Service.Parameters.ParameterCollection();
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TargetType", Value = v_TargetType });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "targetId", Value = v_targetId });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "MessageCode", Value = historyMsgCode });
historyParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "AdditionalInfo", Value = String.Join("", additionalInfo) });
var historyResponse = ASF.CoreLib.APIHelper.BDSExecute(
	new ASF.BDS.WebService.Messages.ExecuteRequest()
	{
		DataCommand = "root_HIST_createHistory",
		Domain = appDomain,
		Parameters = historyParams,
		Token = token
	}
);


//------------------------------------End rule ------------------------------------