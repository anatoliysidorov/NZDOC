var token = HttpUtility.UrlDecode((string)request["token"]);
var appDomain = (string)request["domain"];
var CaseType_CMS_URL = (string)request["ImportURL"];
var rule_importDataXML = "root_UTIL_importDCMDataXML";
var rule_addToQueue = "root_QUEUE_addToQueue";
int fileSize = 0;
string xmlBody = "";
string xml_id = "";

try
{
    // get xml data from CMS file
    using (var dsClient1 = new ASF.CMS.WebService.Proxy.CMSServiceSvc.CMSServiceClient())
    {
        var req = new ASF.CMS.WebService.Messages.GetResourceRequest()  
        {
            Token = token,
            Domain = appDomain,
            Url = CaseType_CMS_URL
        };
    
        var resp = dsClient1.GetResource(req);
        fileSize = Convert.ToInt32(resp.Resource.Length);
        xmlBody = System.Text.Encoding.UTF8.GetString(resp.Resource.Buffer, 0, fileSize);
    }

    // insert a xml data into InsertXML table and return the new ID
    var dsClient0 = ASF.CoreLib.APIHelper.GetDataService(appDomain);
    var reqParam2 = new ASF.Framework.Service.Parameters.ParameterCollection();
    
    reqParam2.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.LargeText(), Name = "inputXML", Value  = xmlBody });
	reqParam2.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.LargeText(), Name = "cmsPath", Value  = CaseType_CMS_URL });
    var response_XMLID = dsClient0.Execute(
        ASF.Framework.Security.SecurityToken.GetSecurityTokenFromString(token),
        appDomain,
        string.Empty,
        "root_UTIL_insertXML", 
        reqParam2 
    );
    var resParams = response_XMLID.GetParameters();
    xml_id = resParams["newId"].Value == null? string.Empty:resParams["newId"].Value.ToString();
    response["XMLID"]  = xml_id.ToString();

    // insert into Queue Event table
    var reqParam1 = new ASF.Framework.Service.Parameters.ParameterCollection();
    var JSONParams = "[{name:\"XMLID\",\"value\" : \""+xml_id+"\"}]";
    
    reqParam1.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.LargeText(), Name = "Parameters", Value  = JSONParams });
    reqParam1.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "RuleCode", Value  = rule_importDataXML });
    var response1 = dsClient0.Execute(
        ASF.Framework.Security.SecurityToken.GetSecurityTokenFromString(token),
        appDomain,
        string.Empty,
        rule_addToQueue, 
        reqParam1 
    );
    var resParams1 = response1.GetParameters();
    response["ErrorCode"]       = resParams1["ERRORCODE"].Value      == null? string.Empty:resParams1["ERRORCODE"].Value.ToString();
    response["ErrorMessage"]    = resParams1["ERRORMESSAGE"].Value   == null? string.Empty:resParams1["ERRORMESSAGE"].Value.ToString();
    response["QUEUEID"]    =resParams1["RECORDID"].Value   == null? string.Empty:resParams1["RECORDID"].Value.ToString();
    response["SuccessMessage"]  = resParams1["SUCCESSMESSAGE"].Value == null? string.Empty:resParams1["SUCCESSMESSAGE"].Value.ToString();
}
catch (Exception ex)
{
    var errorMessage = ex.ToString();
    response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
    response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = "101" });
}