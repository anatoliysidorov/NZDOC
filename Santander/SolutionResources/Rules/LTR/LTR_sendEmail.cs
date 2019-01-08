string errorMessage = string.Empty;

var token = HttpUtility.UrlDecode((string)request["token"]);
var appDomain = (string)request["domain"];

var filesPaths = (string)request["filesPaths"];
var filesNames = (string)request["filesNames"];
var adminServiceUrl = ConfigurationManager.AppSettings["AdministrationServiceRest"];
string file = string.Empty;
List<string> filesForDelete = new List<string>();
List<string> directoriesForDelete = new List<string>();
var server = request["smtp_server"] == null ? (string)request["EMAIL_SMTP_SERVER"] : (string)request["smtp_server"];
var from = request["from"] == null ? (string)request["EMAIL_SENDER"] : (string)request["from"];
var user_name = request["user_name"] == null ? (string)request["EMAIL_USERNAME"] : (string)request["user_name"];
var pass = request["pass"] == null ? (string)request["EMAIL_PASSWORD"] : (string)request["pass"];
int port = request["port"] == null ? Int32.Parse((string)request["EMAIL_PORT"]) : Int32.Parse((string)request["port"]);
bool enableSsl = (port != 25);

var to = request["to"] == null ? string.Empty : (string)request["to"];
string body = request["html"] == null ? string.Empty : (string)request["html"];
string subject = request["subject"] == null ? "Test Email" : (string)request["subject"]; ;


if (string.IsNullOrEmpty(to)) { errorMessage = "Error: address is empty"; goto Validation; }
if (string.IsNullOrEmpty(body)) { errorMessage = "Error: body of message is empty"; goto Validation; }

try
{
    //Create mail
    System.Net.Mail.MailMessage mail = new System.Net.Mail.MailMessage();
    mail.From = new System.Net.Mail.MailAddress(from);
    mail.To.Add(new System.Net.Mail.MailAddress(to));
    mail.Subject = subject;
    mail.SubjectEncoding = System.Text.Encoding.UTF8;
    mail.Body = body;
    mail.IsBodyHtml = true;
    //------------

    if (!string.IsNullOrEmpty(filesPaths))
    {
        string[] filesPathsArr = filesPaths.Split(',');
        string[] filesNamesArr = string.IsNullOrEmpty(filesNames) ? new string[]{}: filesNames.Split(',');

        for (int i = 0; i < filesPathsArr.Length; i++)
        {
            string filePath = string.Empty;
            string fileName = string.Empty;

            string newFilePath = string.Empty;
            //Download file 
            string tmpFileName = string.Empty;

           // filePath = Ecx.Rule.Helpers.DocumentHelper.DownloadDocument(token, appDomain, HttpUtility.UrlDecode(filesPathsArr[i]));
            var fileResp = ASF.CoreLib.APIHelper.GetCmsResource(new ASF.CoreLib.Messages.GetCmsResourceRequest()
            {
                Domain = appDomain,
                Token = token,
                Url = HttpUtility.UrlDecode(filesPathsArr[i])
            });
            filePath = fileResp.Resource.FullFileSystemPath;
              //   filePath = Ecx.Rule.Helpers.DocumentHelper.DownloadDocument(token, appDomain, HttpUtility.UrlDecode(filesPathsArr[i]));

            fileName = System.IO.Path.GetFileName(filePath);

            // string fileDirectory = System.IO.Path.GetDirectoryName(filePath);
            // if (filesNamesArr.Count() > 0)
            // {
            //     string tmpDir = string.Format("{0:yyyy_MMMM_dd_H_mm_ss_fff}", DateTime.Now);
            //     if (!System.IO.Directory.Exists(string.Format("{0}\\{1}", fileDirectory, tmpDir)))
            //     {
            //         System.IO.Directory.CreateDirectory(string.Format("{0}\\{1}", fileDirectory, tmpDir));
            //         directoriesForDelete.Add(string.Format("{0}\\{1}", fileDirectory, tmpDir));
            //     }
            //     newFilePath = string.Format("{0}\\{1}\\{2}", fileDirectory, tmpDir, filesNamesArr[i]);
            //     System.IO.File.Move(filePath, newFilePath);

            //     fileName = System.IO.Path.GetFileName(newFilePath);
            //     filePath = newFilePath;
            // }
            
           // filesForDelete.Add(filePath);
            fileResp.Resource.Stream.Close();
            
            //------------

            //Create attachment 
            System.Net.Mail.Attachment inline = new System.Net.Mail.Attachment(filePath);
            inline.ContentDisposition.Inline = true;
            inline.ContentDisposition.DispositionType = System.Net.Mime.DispositionTypeNames.Inline;
            inline.ContentId = fileName;
            inline.ContentType.Name = fileName;
            //------------
            
            mail.Attachments.Add(inline);

        }
    }

    //Send mail
    System.Net.Mail.SmtpClient client = new System.Net.Mail.SmtpClient();
    client.Host = server;
    client.Port = port;
    client.EnableSsl = enableSsl;
    client.Credentials = new NetworkCredential(user_name, pass);
    client.DeliveryMethod = System.Net.Mail.SmtpDeliveryMethod.Network;
    client.Send(mail);
    mail.Dispose();
    //------------

    //Delete files after send
    //string isDeleted = string.Empty;
    /*foreach (var fileName in filesForDelete)
    {
        try{
            isDeleted = string.Format("{0} {1}", isDeleted, Ecx.Rule.Helpers.Utils.TryToDeleteFile(fileName).ToString());
        } catch(Exception exp){
            errorMessage = "An error occurred during executing Ecx.Rule.Helpers.Utils.TryToDeleteFile";
            throw new ApplicationException(exp.ToString());
        }
    }
    response["isFileDeleted"] = isDeleted;*/
    //------------

    //Delete dirs after send
    // isDeleted = string.Empty;
    // try
    // { 
    //     foreach (var dirName in directoriesForDelete)
    //     {
    //         System.IO.Directory.Delete(dirName);
    //         isDeleted = "True";
    //         response["isDirsDeleted"] = isDeleted;
    //     }
        
    // }
    // catch {
    //     response["isDirsDeleted"] = "Error";
    // }
    //------------

}
catch (Exception ex)
{
    errorMessage = string.Format("Exception: {0}", ex.Message.ToString());
}
Validation:
if (string.IsNullOrEmpty(errorMessage))
{
    response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = string.Empty });
    var typeLargeText = ASF.Framework.Service.Parameters.ParameterType.LargeText();
    string successResponse = "Message was successfully sent to {{MESS_TO}}";
    object objMessageParams = new { MESS_TO = to };
    var jsonParams = Newtonsoft.Json.JsonConvert.SerializeObject(objMessageParams);
    var i18NParams = new ASF.Framework.Service.Parameters.ParameterCollection();
    i18NParams.AddParameter(new Parameter { Type = typeLargeText, Name = "MessageText", Value = successResponse });
    i18NParams.AddParameter(new Parameter { Type = typeLargeText, Name = "MessageParams", Value = jsonParams });
    var i18NResponse = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
    {
        DataCommand = "root_LOC_i18n_invocation",
        Domain = appDomain,
        Parameters = i18NParams,
        Token = token
    });
    var resultI18N = i18NResponse.Data.GetParameters();
    response["SuccessResponse"] = resultI18N["MessageResult"].Value.ToString();	
    //response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = string.Format("Message was successfully sent to '{0}'", to)});
}
else
{
    response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
    response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = string.Empty });
}