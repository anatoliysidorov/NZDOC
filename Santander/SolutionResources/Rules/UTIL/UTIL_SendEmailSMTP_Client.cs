try
{
    var token = HttpUtility.UrlDecode((string)request["token"]);
    var appDomain = (string)request["domain"];
    
    var to = request["to"] == null ? string.Empty : (string)request["to"];
    var server = request["smtp_server"] == null ? (string)request["EMAIL_SMTP_SERVER"] : (string)request["smtp_server"];
    var from = request["from"] == null ? (string)request["EMAIL_SENDER"] : (string)request["from"];
	var user_name = request["user_name"] == null ? (string)request["EMAIL_USERNAME"] : (string)request["user_name"];
    var pass = request["pass"] == null ? (string)request["EMAIL_PASSWORD"] : (string)request["pass"];
    int port = request["port"] == null ? Int32.Parse((string)request["EMAIL_PORT"]) : Int32.Parse((string)request["port"]);
    bool enableSsl = (port != 25);
    
    string subject = "Test Email";
    string body = "This is a test email was sent by client mail with settings for SMTP server from the System Variables.";

    System.Net.Mail.MailMessage mail = new System.Net.Mail.MailMessage();
    mail.From = new System.Net.Mail.MailAddress(from);
    mail.To.Add(new System.Net.Mail.MailAddress(to));
    mail.Subject = subject;
    mail.Body = body;
    System.Net.Mail.SmtpClient client = new System.Net.Mail.SmtpClient();
    client.Host = server;
    client.Port = port;
    client.EnableSsl = enableSsl;
    client.Credentials = new NetworkCredential(user_name, pass);
    client.DeliveryMethod = System.Net.Mail.SmtpDeliveryMethod.Network;
    
    client.Send(mail);
    mail.Dispose();
    
    response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = string.Empty });
    response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = "Message was successfully sent" });
}
catch (Exception ex)
{
    var errorMessage = ex.Message;
    response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 101});
    response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
    response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = string.Empty });
}
