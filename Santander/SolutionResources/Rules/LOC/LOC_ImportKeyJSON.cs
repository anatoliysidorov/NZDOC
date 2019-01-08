            var token = HttpUtility.UrlDecode((string)request["token"]);
            var domain = (string)request["domain"];
            string url = (string)request["URL"];
            string _namespace = (string)request["NAMESPACE"];
            string jsonString = (string)request["JSONSTRING"];
            string sourceType = (string)request["SourceType"];
            string sourceId   = (string)request["SourceId"];
            string separatorIsPlurar = " #:plural"; // the value for isPlurar must be getting like true if separator is present
            string separatorContext = " %:";        // the value for context must be getting like suffix 
            System.Type type = null;
            string path = String.Empty;

            try
            {
                if (String.IsNullOrWhiteSpace(jsonString))
                {
                    if (string.IsNullOrEmpty(url)) { throw new Exception("The URL or JSON string can not be empty"); }
                    else
                    {
                        var fileResp = ASF.CoreLib.APIHelper.GetCmsResource(new ASF.CoreLib.Messages.GetCmsResourceRequest()
                        {
                            Domain = domain,
                            Token = token,
                            Url = url
                        });
                        path = fileResp.Resource.FullFileSystemPath;

                        // reading a JSON file
                        jsonString = System.IO.File.ReadAllText(path);
                        fileResp.Resource.Stream.Close();
                    }
                }

                if (string.IsNullOrEmpty(_namespace)) { throw new Exception("The Namespace can not be empty"); }

                List<object> anonymousKeys = new List<object>();
                Dictionary<string, string> dictJSON = Newtonsoft.Json.JsonConvert.DeserializeObject<Dictionary<string, string>>(jsonString);
                foreach (var data in dictJSON)
                {
                    // Parse the key value
                    string keyValue = data.Key;
                    string contextValue = "";
                    bool isPlurarValue = false;
                    int _index = 0;
                    _index = keyValue.IndexOf(separatorIsPlurar);
                    if (_index > 0)
                    {
                        keyValue = keyValue.Replace(separatorIsPlurar, "");
                        isPlurarValue = true;
                    }
                    _index = 0;
                    _index = keyValue.IndexOf(separatorContext);
                    if (_index > 0)
                    {

                        contextValue = keyValue.Substring(_index, keyValue.Length - _index);
                        contextValue = contextValue.Replace(separatorContext, "");
                        keyValue = keyValue.Substring(0, _index);
                    }

                    // Add new key to the list or modify the property for current key
                    string uniqueKey = keyValue + "(o)(o)" + contextValue;
                    object key = null;
                    foreach (var anonymousKey in anonymousKeys)
                    {
                        type = anonymousKey.GetType();
                        string x = (string)type.GetProperty("uniqueKey").GetValue(anonymousKey, null);
                        if (x == uniqueKey)
                        {
                            key = anonymousKey;
                            break;
                        }
                    }

                    //var key = anonymousKeys.FirstOrDefault(x => x.uniqueKey == uniqueKey));
                    if (key != null)
                    {
                        bool isPlural = (bool)type.GetProperty("isPlural").GetValue(key, null);
                        if (!isPlural & isPlurarValue)
                        {
                            anonymousKeys.Remove(key);
                        }
                    }
                    var anonymousObject = new { uniqueKey = uniqueKey, keyName = keyValue, isPlural = isPlurarValue, context = contextValue };
                    anonymousKeys.Add(anonymousObject);
                }

                System.Xml.Linq.XElement xmlElements = new System.Xml.Linq.XElement("Keys");
                foreach (var row in anonymousKeys)
                {
                    xmlElements.Add(new System.Xml.Linq.XElement("row",
                        new System.Xml.Linq.XElement("namespace", new System.Xml.Linq.XCData(_namespace)),
                        new System.Xml.Linq.XElement("keyName", new System.Xml.Linq.XCData((string)row.GetType().GetProperty("keyName").GetValue(row, null))),
                        new System.Xml.Linq.XElement("isPlural", new System.Xml.Linq.XCData(Convert.ToInt32((bool)row.GetType().GetProperty("isPlural").GetValue(row, null)).ToString())),
                        new System.Xml.Linq.XElement("context", new System.Xml.Linq.XCData((string)row.GetType().GetProperty("context").GetValue(row, null)))
                        )
                    );
                }

                // Delete temporary file
                // if (!String.IsNullOrEmpty(path))
                // {
                //     Ecx.Rule.Helpers.Utils.TryToDeleteFile(path);
                // }
                /*response["xmlElements"] = xmlElements.ToString();*/
                //Call the rule for import data
                var param = new ASF.Framework.Service.Parameters.ParameterCollection();
                param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "NAMESPACE", Value = _namespace });
                param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.LargeText(), Name = "XML_INPUT", Value = xmlElements.ToString() });
                param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Text(), Name = "SourceType", Value = sourceType });
                param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.Integer(), Name = "SourceId", Value = sourceId });
                var importDataToDB = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
                {
                    DataCommand = "root_LOC_ImportKey",
                    Domain = domain,
                    Parameters = param,
                    Token = token
                });
                var outParameters = importDataToDB.Data.GetParameters();
                /*if (outParameters["ERRORCODE"].Value != null)
                {
                    response["ErrorCode"] = outParameters["ERRORCODE"].Value.ToString();
                }*/

                if (!String.IsNullOrEmpty(outParameters["ERRORMESSAGE"].Value.ToString()))
                {
                    //response["ErrorMessage"] = outParameters["ERRORMESSAGE"].Value.ToString();
                    throw new Exception(outParameters["ERRORMESSAGE"].Value.ToString());
                }

                response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = string.Empty });
                response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = "The dictionary keys was successfully import" });
                response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 0 });
            }
            catch (Exception ex)
            {
                var errorMessage = ex.Message;
                response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
                response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = string.Empty });
                response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 101 });
            }