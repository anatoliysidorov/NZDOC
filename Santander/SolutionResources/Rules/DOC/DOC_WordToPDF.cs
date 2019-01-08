    var token = HttpUtility.UrlDecode((string)request["token"]);
    var domain = (string)request["domain"];
    var documentId = request.AsString("DocumentId");

    var deleteOld = request.AsString("DeleteOldVersion");

    var caseTypeId = request.AsString("CaseType_Id");
    var caseId = request.AsString("Case_Id");
    var taskId = request.AsString("Task_Id");
    var extpartyId = request.AsString("ExtParty_Id");
    var teamId = request.AsString("Team_Id");
    var caseworkerId = request.AsString("CaseWorker_Id");
    var calcParentId = request.AsString("CalcParentId");
    var isGlobalResource = request.AsString("IsGlobalResource");

    const string getDocumentRule = "root_DOC_getDocument";

    const string updateDocumentUrlRule = "root_DOC_UpdateDocumentURL";
    const string createDocumentUrlRule = "root_DOC_CreateModifyDocument";

    string url = string.Empty;
    string originalFileName = string.Empty;
    string newCmsUrl = string.Empty;

    int errorCode = 0;
    string errorMessage = string.Empty;
    string successResponse = string.Empty;

    if (!string.IsNullOrEmpty(documentId))
    {
        // Download Content
        try
        {
            var getDocumentParametersRequest = new ASF.Framework.Service.Parameters.ParameterCollection();
            getDocumentParametersRequest.AddParameter(new Parameter
            {
                Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
                Name = "Id",
                Value = documentId
            });
            getDocumentParametersRequest.AddParameter(new Parameter
            {
                Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
                Name = "Case_Id",
                Value = caseId
            });
            getDocumentParametersRequest.AddParameter(new Parameter
            {
                Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
                Name = "Task_Id",
                Value = taskId
            });
            var getDocumentRuleRequest = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
            {
                DataCommand = getDocumentRule,
                Domain = domain,
                Parameters = getDocumentParametersRequest,
                Token = token
            });
            var getDocumentParametersResponse = getDocumentRuleRequest.Data.ToXml();

            XmlDocument getDocumentParametersResponseXml = new XmlDocument();
            getDocumentParametersResponseXml.LoadXml(getDocumentParametersResponse.ToString());
            var items =
                getDocumentParametersResponseXml.SelectSingleNode("//DATA/root_DOC_getDocument/ITEMS");
            if (items != null)
            {
                if (items.HasChildNodes == false)
                {
                    errorCode = 105;
                    errorMessage = "Document record was not found";
                    goto Validation;
                }
                if (items.SelectSingleNode("URL") == null)
                {
                    errorCode = 106;
                    errorMessage = "Document URL was not found";
                    goto Validation;
                }
                if (items.SelectSingleNode("NAME") == null)
                {
                    errorCode = 107;
                    errorMessage = "Document NAME was not found";
                    goto Validation;
                }
                if (Convert.ToInt32(items.SelectSingleNode("STATE_ISFINISH").InnerText.ToString()) == 1)
                {
                    errorCode = 108;
                    if (string.IsNullOrEmpty(taskId)) {
                      errorMessage = "Case is finished. You can not convert Case Documents";
                    } else {
                      errorMessage = "Task is finished. You can not convert Task Documents";
                    }
                    goto Validation;
                }
                else
                {
                    string documentUrl = items.SelectSingleNode("URL").InnerText.ToString();
                    string nameFromRule = items.SelectSingleNode("NAME").InnerText.ToString();

                    nameFromRule = nameFromRule.Split('.').Length > 1 ? string.Join("", (from i in nameFromRule.Split('.') select i).Take(nameFromRule.Split('.').Length - 1).ToArray()) : nameFromRule.Split('.')[0];

                    // Try to convert
                    var fileExtension = AppBaseHelpers.CmsHelper.GetCmsUrlExtension(documentUrl);
                    if (AppBaseHelpers.CmsHelper.GetSupportedFormatsForConvertToPDF().Contains(fileExtension))
                    {
                        try
                        {
                            var fileContent = new ASF.Framework.Service.Content.StorageContent(documentUrl);
                            var fileContentPDF = new ASF.Content.Common.Domain.Convert(fileContent, ASF.Framework.Util.MimeHelper.MIME_APPLICATION_PDF);
                            originalFileName =  string.Format("{0}_{1}{2}", nameFromRule, Guid.NewGuid().ToString(), ".pdf");

                            newCmsUrl = "cms:///" + originalFileName;
                            var saveOperation = new ASF.Content.Common.Domain.Save(fileContentPDF, newCmsUrl);

                            var generateRequest = new ASF.Content.WebService.Messages.ExecuteRequest()
                            {
                                Token = token,
                                Domain = domain,
                                Operation = saveOperation
                            };

                            var generateResponse = ASF.Content.WebService.Proxy.ContentServiceClientSync.ExecuteSync(generateRequest);   

                            if (!string.IsNullOrEmpty(deleteOld))//DELETE DOCUMENT
                            {
                                var deleteResourceResponse = ASF.CoreLib.APIHelper.DeleteCmsResource(new ASF.CoreLib.Messages.DeleteCmsResourceRequest()
                                {
                                    Domain = domain,
                                    Token = token,
                                    Url = documentUrl
                                });
                            }
                        }
                        catch (Exception ex)
                        {
                            errorCode = 101;
                            errorMessage = ex.ToString();
                            successResponse = string.Empty;
                            goto Validation;
                        }

                        if (!string.IsNullOrEmpty(deleteOld)) //DELETE DOCUMENT
                        {
                            var updateDocumentUrlParametersRequest =
                                new ASF.Framework.Service.Parameters.ParameterCollection();
                            updateDocumentUrlParametersRequest.AddParameter(new Parameter
                            {
                                Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
                                Name = "DocumentId",
                                Value = documentId
                            });
                            updateDocumentUrlParametersRequest.AddParameter(new Parameter
                            {
                                Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
                                Name = "NewUrl",
                                Value = newCmsUrl
                            });
                            updateDocumentUrlParametersRequest.AddParameter(new Parameter
                            {
                                Type = ASF.Framework.Service.Parameters.ParameterType.Text(),
                                Name = "NewName",
                                Value = nameFromRule + ".pdf"
                            });
                            var updateDocumentUrlRuleRequest =
                                ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
                                {
                                    DataCommand = updateDocumentUrlRule,
                                    Domain = domain,
                                    Parameters = updateDocumentUrlParametersRequest,
                                    Token = token
                                });

                            successResponse = "File " + nameFromRule + " was converted to PDF. Old document was deleted.";
                            
                        }
                        else
                        {
                            var createDocumentUrlParametersRequest =
                                new ASF.Framework.Service.Parameters.ParameterCollection();
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CASETYPE_ID", Value = caseTypeId });
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CASE_ID", Value = caseId });
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TASK_ID", Value = taskId });
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "EXTPARTY_ID", Value = extpartyId });
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "TEAM_ID", Value = caseTypeId });
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CASEWORKER_ID", Value = caseworkerId });
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "ISFOLDER", Value = "0" });
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "NAME", Value = nameFromRule + ".pdf" });
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "URL", Value = newCmsUrl });
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "CALCPARENTID", Value = calcParentId });
                            createDocumentUrlParametersRequest.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "ISGLOBALRESOURCE", Value = isGlobalResource });


                            var updateDocumentUrlRuleRequest =
                                ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
                                {
                                    DataCommand = createDocumentUrlRule,
                                    Domain = domain,
                                    Parameters = createDocumentUrlParametersRequest,
                                    Token = token
                                });

                              successResponse = "File " + nameFromRule + " was converted to PDF";
                            
                        }
                          
                        errorCode = 0;
                        errorMessage = string.Empty;
                        goto Validation;
                    }
                    else
                    {
                        successResponse = string.Empty;
                        errorCode = 102;
                        errorMessage = "Could not covert to PDF";
                        goto Validation;
                    }
                
                }
            }
        }
        catch (Exception ex)
        {
            successResponse = string.Empty;
            errorCode = 103;
            errorMessage = ex.ToString();
            goto Validation;
        }
    }
    else
    {
        errorCode = 104;
        errorMessage = "Document Id must not be empty";
        successResponse = string.Empty;
    }

    Validation:
    if (errorCode != 0)
    {
        response["ErrorCode"] = errorCode;
        response["ErrorMessage"] = errorMessage;
    }
    response["SuccessResponse"] = successResponse;