string errorMessage = string.Empty;
string newCmsPath = string.Empty;

try
{
    var token = HttpUtility.UrlDecode((string)request["token"]);
    var domain = (string)request["domain"];
    string CMSServiceRest = ConfigurationManager.AppSettings["CMSServiceRest"];
    string cmsUrl = request.AsString("cmsUrl");

    if (string.IsNullOrEmpty(cmsUrl)) { errorMessage = "Url can not be empty for this operation"; goto Validation; }


    //---------------------------------------------
    //		Get old file
    //---------------------------------------------
    var oldFileResp = ASF.CoreLib.APIHelper.GetCmsResource(new ASF.CoreLib.Messages.GetCmsResourceRequest()
    {
        Domain = domain,
        Token = token,
        Url = cmsUrl
    });

    //---------------------------------------------
    //		Calculated fields
    //---------------------------------------------
    string ext = System.IO.Path.GetExtension(oldFileResp.Resource.FullFileSystemPath);
    string newName = string.Format("{0}{1}", Guid.NewGuid().ToString(), ext);
    newCmsPath = string.Format("cms:///{0}", newName);
    
    //---------------------------------------------
    //		Create CMS resource with new name
    //---------------------------------------------
    var createResourceResponse = ASF.CoreLib.APIHelper.CreateCmsResource(new ASF.CoreLib.Messages.CreateCmsResourceRequest()
    {
        Domain = domain,
        Token = token,
        FileName = newName,
        OverrideUrl = newCmsPath,
        Stream = oldFileResp.Resource.Stream
    });

    oldFileResp.Resource.Stream.Close();
}
catch (Exception e)
{
    errorMessage = e.ToString();
    goto Validation;
}

Validation:
response["URL"] = newCmsPath;
response["ErrorMessage"] = errorMessage;