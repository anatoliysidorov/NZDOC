string errorMessage = string.Empty;
string zipUrl = string.Empty;
var token = HttpUtility.UrlDecode((string)request["token"]);
var domain = (string)request["domain"];
string CMSServiceRest = ConfigurationManager.AppSettings["CMSServiceRest"];

var caseTypeId = request.AsString("CaseType_Id");
var caseId = request.AsString("Case_Id");
var taskId = request.AsString("Task_Id");
var extpartyId = request.AsString("ExtParty_Id");
var teamId = request.AsString("Team_Id");
var caseworkerId = request.AsString("CaseWorker_Id");
var folderId = request.AsString("FolderId");
var isGlobalResource = request.AsString("IsGlobalResource");
var prefix = request.AsString("filePrefix");

string currentProcess = Ecx.Rule.Helpers.Utils.GetTempFolder(string.Format("{0}\\{1}", domain, string.Format("{0:M_d_yyyy_H_mm_ss}", DateTime.Now)));

try
{
    var getFolderTreeParams = new ASF.Framework.Service.Parameters.ParameterCollection();
    getFolderTreeParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CASETYPE_ID", Value = caseTypeId });
    getFolderTreeParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CASE_ID", Value = caseId });
    getFolderTreeParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TASK_ID", Value = taskId });
    getFolderTreeParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "EXTPARTY_ID", Value = extpartyId });
    getFolderTreeParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TEAM_ID", Value = teamId });
    getFolderTreeParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CASEWORKER_ID", Value = caseworkerId });
    getFolderTreeParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "FOLDERID", Value = folderId });
    getFolderTreeParams.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "ISGLOBALRESOURCE", Value = isGlobalResource });
    var getFolderTreeRequest = ASF.CoreLib.APIHelper.BDSExecute(
        new ASF.BDS.WebService.Messages.ExecuteRequest()
        {
            DataCommand = "root_DOC_getFolderTree",
            Domain = domain,
            Parameters = getFolderTreeParams,
            Token = token
        }
    );

    var getFolderTreeResponse = getFolderTreeRequest.Data.ToXml();
    XmlDocument doc = new XmlDocument();
    doc.LoadXml(getFolderTreeResponse.ToString());

    var items = doc.SelectNodes("//DATA/root_DOC_getFolderTree/ITEMS");
    if (items != null && items.Count != 0)
    {
        //--Download all files and create directory
        for (int i = 0; i < items.Count; i++)
        {
            var currentItem = items[i];
            var branchPath = currentItem.SelectSingleNode("BRANCHPATH");
            var url = currentItem.SelectSingleNode("DOCUMENTURL");
            var isFolder = currentItem.SelectSingleNode("ISFOLDER");
            var id = currentItem.SelectSingleNode("BRANCHID");
            if (isFolder == null || branchPath == null)
            {
                errorMessage = "Some required field is invalid";
                goto Validation;
            }

            if (isFolder.InnerXml == "1")
            {
                System.IO.Directory.CreateDirectory(string.Format("{0}{1}", currentProcess, branchPath.InnerXml));
            }

            if (isFolder.InnerXml == "0" && url != null)
            {
                string urlForFile = string.Format("{0}getresource/{1}?t={2}&u={3}", CMSServiceRest, domain, token, url.InnerXml);
                WebClient myWebClient = new WebClient();
                string filePath = string.Format("{0}{1}", currentProcess, branchPath.InnerXml);
                int lastPoint = filePath.LastIndexOf('.');
                filePath = filePath.Insert(lastPoint, "_" + id.InnerXml);
                myWebClient.DownloadFile(urlForFile, filePath);
            }
        }
        //------------------------------------
    }

    //Create zip  
    var childDir = System.IO.Directory.GetDirectories(currentProcess);
    if (childDir.Length == 0)
    {
        errorMessage = "Cannot find parend directory";
        goto Validation;
    }
    string folderForZip = childDir[0];
    string fileForZip = folderForZip.ToLower() + ".zip";


    var zipFile = Ecx.Rule.Helpers.Utils.ZipFolder(domain, folderForZip, fileForZip, null);
    var processDirectory = System.IO.Path.GetDirectoryName(zipFile);

    var filePrefix = string.IsNullOrEmpty(prefix)
        ? System.IO.Path.GetFileNameWithoutExtension(fileForZip)
        : prefix;

    string zipName = processDirectory + "\\" + filePrefix + "_" + string.Format("{0:yyyy_MMMM_dd_H_mm_ss_fff}", DateTime.Now) + ".zip";
    System.IO.File.Move(zipFile, zipName);
    string originalZipName = System.IO.Path.GetFileName(zipName);
    string newZipUrl = "cms://temp/" + originalZipName;
    // zipUrl = Ecx.Rule.Helpers.DocumentHelper.CreateAndUploadDocument(token, domain, zipName, newZipUrl);

    using (var fileStream = new System.IO.FileStream(zipName, System.IO.FileMode.Open))
    {
        var createResourceResponse = ASF.CoreLib.APIHelper.CreateCmsResource(new ASF.CoreLib.Messages.CreateCmsResourceRequest()
        {
            Domain = domain,
            Token = token,
            FileName = originalZipName,
            OverrideUrl = newZipUrl,
            Stream = fileStream
        });

        zipUrl = createResourceResponse.FileUrl;
    }

    try
    {
        System.IO.Directory.Delete(currentProcess, true);
        System.IO.File.Delete(zipFile);
        System.IO.File.Delete(zipName);
        response["DirectoryDeleted"] = "true";
    }
    catch (Exception del)
    {
        response["DirectoryDeleted"] = "false";
    }
    //---------
}
catch (Exception ecx)
{
    errorMessage = ecx.ToString();
}
Validation:
response["URL"] = zipUrl;
response["ErrorMessage"] = errorMessage;