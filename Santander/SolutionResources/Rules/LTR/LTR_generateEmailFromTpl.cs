string errorFormHtml = "<html><head> <style>table, th, td {border: 1px solid black;border-collapse: collapse;font-weight: normal;}td{width: 200px;}label{position: relative;margin: 10px;}.mainLabel{font-weight: bold;text-align: center;background: #E7CC6B;} input{width: 200px;}</style></head><body><table align=\"center\"><tr><td class=\"mainLabel\"><label>Error message:</label></td><th colspan=\"3\"><textarea class=\"error_message_from_rule\" style=\"width: 600px;\">MESSAGE</textarea></th></tr></table></body></html>";
    var token = request.AsString("token");
    var appDomain = request.AsString("domain");
    var address = request.AsString("address");
    var templateId = request.AsString("templateId");
    string errorMessage = string.Empty;
    string successResponse = string.Empty;
    var caseId = request.AsString("caseId");
    var taskId = request.AsString("taskId");
    var externalPartyId = request.AsString("externalPartyId");
    string markup = string.Empty;


    if (string.IsNullOrEmpty(templateId)) { errorMessage = "Error : Template id is empty"; goto Validation; }

    using (var client = new ASF.BDS.WebService.Proxy.DataServiceSvc.DataServiceClient())
    {

        var letterTemplatesParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
        letterTemplatesParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Id", Value = Convert.ToInt64(templateId) });

        var letterTemplatesRequest = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
        {
            DataCommand = "root_LTR_getLetterTemplates",
            Domain = appDomain,
            Parameters = letterTemplatesParameters,
            Token = token
        });

        string letterTemplateXml = letterTemplatesRequest.Data.ToXml().ToString();
        XmlDocument letterTemplateXmlDocument = new XmlDocument();
        letterTemplateXmlDocument.LoadXml(letterTemplateXml);
        var markupData = letterTemplateXmlDocument.SelectSingleNode("DATA/root_LTR_getLetterTemplates/ITEMS/MARKUP");

        if (markupData != null)
        {
            markup = markupData.InnerText;
            System.Text.RegularExpressions.MatchCollection matches = System.Text.RegularExpressions.Regex.Matches(markup, "@@[a-zA-Z0-9]+@@", System.Text.RegularExpressions.RegexOptions.IgnoreCase);

            foreach (var match in matches)
            {
                string placeholder = match.ToString(); //With '@' characters
                string placeholderName = match.ToString().Replace("@", ""); //Without '@' characters
                string placeholderValue = "{Cannot find placeholder}";

                //[Start]----Right here we are get data for current placeholder-----
                var getPlaceHolderFunctionParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
                getPlaceHolderFunctionParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Placeholder_Name", Value = placeholderName });

                var getPlaceHolderFunctionRequest = client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
                {
                    DataCommand = "root_STP_getMessagePlaceHolder",
                    Domain = appDomain,
                    Parameters = getPlaceHolderFunctionParameters,
                    Token = token
                });
                string placeHolderFunctionXml = getPlaceHolderFunctionRequest.Data.ToXml().ToString();
                XmlDocument placeHolderFunctionXmlDocument = new XmlDocument();
                placeHolderFunctionXmlDocument.LoadXml(placeHolderFunctionXml);
                var processorCode = placeHolderFunctionXmlDocument.SelectSingleNode("DATA/root_STP_getMessagePlaceHolder/ITEMS/PROCESSORCODE");

                if (processorCode == null)
                {
                    markup = markup.Replace(placeholder, placeholderValue);
                    continue;
                }

                var getPlaceHolderValueByProcessorParameters = new ASF.Framework.Service.Parameters.ParameterCollection();
                getPlaceHolderValueByProcessorParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "Function_Name", Value = processorCode.InnerText });
                getPlaceHolderValueByProcessorParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Case_Id", Value = string.IsNullOrEmpty(caseId) ? null : caseId });
                getPlaceHolderValueByProcessorParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "Task_Id", Value = string.IsNullOrEmpty(taskId) ? null : taskId });
                getPlaceHolderValueByProcessorParameters.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Number(), Name = "ExternalParty_Id", Value = string.IsNullOrEmpty(externalPartyId) ? null : externalPartyId });
                try
                {
                    var getPlaceHolderValueByProcessorRequest =
                        client.Execute(new ASF.BDS.WebService.Messages.ExecuteRequest()
                        {
                            DataCommand = "root_LTR_getPlhValue",
                            Domain = appDomain,
                            Parameters = getPlaceHolderValueByProcessorParameters,
                            Token = token
                        });
                    var getPlaceHolderValueByProcessorResponse = getPlaceHolderValueByProcessorRequest.Data.GetParameters();

                    placeholderValue = getPlaceHolderValueByProcessorResponse["PLACEHOLDER"] == null
                        ? "{Error when return data from function}"
                        : getPlaceHolderValueByProcessorResponse["PLACEHOLDER"].Value.ToString();

                    markup = markup.Replace(placeholder, placeholderValue);
                }
                catch (Exception ex)
                {
                    placeholderValue = "{Error when run function}";
                    markup = markup.Replace(placeholder, placeholderValue);
                }
                //[End]----Right here we are get data for current placeholder------
            }
            
            
        }
        else
        {
            errorMessage = "Error : Template is empty";
        }


    }
Validation:
    if (!string.IsNullOrEmpty(errorMessage))
    {
        response["SYS_BINARY_RESPONSE"] = errorFormHtml.Replace("MESSAGE", errorMessage); 
        response["SYS_BINARY_CONTENT_TYPE"] = "text/html";
    }
    else
    {
        response["SYS_BINARY_RESPONSE"] = !string.IsNullOrEmpty(markup) ? markup : errorFormHtml.Replace("MESSAGE", "Template is empty"); 
        response["SYS_BINARY_CONTENT_TYPE"] = "text/html";
    }