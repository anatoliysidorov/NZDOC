            var token = HttpUtility.UrlDecode((string)request["token"]);
            var domain = (string)request["domain"];
            string url = (string)request["URL"];
            //url = @"d:\Temp\ru.xlsx|||d:\Temp\en.xlsx|||d:\Temp\uk.xlsx";
            //url = "cms:///1497016568938_201706091656938.xlsx";

            Func<DocumentFormat.OpenXml.Packaging.SpreadsheetDocument, DocumentFormat.OpenXml.Spreadsheet.Cell, string> GetCellValue = (doc, cell) =>
            {
                if (cell.CellValue == null)
                {
                    return string.Empty;
                }
                string value = cell.CellValue.InnerText;
                if (cell.DataType != null && cell.DataType.Value == DocumentFormat.OpenXml.Spreadsheet.CellValues.SharedString)
                {
                    return doc.WorkbookPart.SharedStringTablePart.SharedStringTable.ChildElements.GetItem(int.Parse(value)).InnerText;
                }
                return value;
            };

            Func<string, System.Data.DataTable, bool> ReadFileToDataTable = (fileName, dt) =>
            {
                using (DocumentFormat.OpenXml.Packaging.SpreadsheetDocument doc = DocumentFormat.OpenXml.Packaging.SpreadsheetDocument.Open(fileName, false))
                {
                    //Read the first Sheets
                    int count = doc.WorkbookPart.Workbook.Sheets.Descendants().Count();
                    for (int indSheet = 0; indSheet < count; indSheet++)
                    {
                        //DocumentFormat.OpenXml.Spreadsheet.Sheet sheet = doc.WorkbookPart.Workbook.Sheets.GetFirstChild<DocumentFormat.OpenXml.Spreadsheet.Sheet>();
                        DocumentFormat.OpenXml.Spreadsheet.Sheet sheet = doc.WorkbookPart.Workbook.Sheets.Descendants<DocumentFormat.OpenXml.Spreadsheet.Sheet>().ElementAt(indSheet);
                        DocumentFormat.OpenXml.Spreadsheet.Worksheet worksheet = (doc.WorkbookPart.GetPartById(sheet.Id.Value) as DocumentFormat.OpenXml.Packaging.WorksheetPart).Worksheet;
                        IEnumerable<DocumentFormat.OpenXml.Spreadsheet.Row> rows = worksheet.GetFirstChild<DocumentFormat.OpenXml.Spreadsheet.SheetData>().Descendants<DocumentFormat.OpenXml.Spreadsheet.Row>();

                        for (int i = 0; i < rows.Count(); i++)
                        {
                            var row = rows.ElementAt(i);

                            //Read the first row as header
                            if (i == 0)
                            {
                                if (dt.Columns.Count > 0)
                                {
                                    continue;
                                }
                                var j = 1;
                                foreach (DocumentFormat.OpenXml.Spreadsheet.Cell cell in row.Descendants<DocumentFormat.OpenXml.Spreadsheet.Cell>())
                                {
                                    var colunmName = GetCellValue(doc, cell);
                                    dt.Columns.Add(colunmName);
                                }
                            }
                            else
                            {
                                // check for all cells is not empty
                                int contCell = row.Descendants<DocumentFormat.OpenXml.Spreadsheet.Cell>().Count();
                                if (dt.Columns.Count > contCell)
                                {
                                    continue;
                                }
                                
                                dt.Rows.Add();
                                int k = 0;
                                foreach (DocumentFormat.OpenXml.Spreadsheet.Cell cell in row.Descendants<DocumentFormat.OpenXml.Spreadsheet.Cell>())
                                {
                                    if (dt.Columns[k].ColumnName == "VALUE") 
                                    {
                                        string text = GetCellValue(doc, cell);
                                        char[] chars = HttpUtility.HtmlEncode(text).ToCharArray();
                                        System.Text.StringBuilder result = new System.Text.StringBuilder(text.Length + (int)(text.Length * 0.1));
                                        foreach (char c in chars)
                                        {
                                            int value = Convert.ToInt32(c);
                                            if (value > 127)
                                                result.AppendFormat("&#{0};", value);
                                            else
                                                result.Append(c);
                                        }
                                        //dt.Rows[dt.Rows.Count - 1][k] = HttpUtility.HtmlEncode(GetCellValue(doc, cell));
                                        dt.Rows[dt.Rows.Count - 1][k] = result.ToString();
                                    } else
                                    {
                                        dt.Rows[dt.Rows.Count - 1][k] = GetCellValue(doc, cell);
                                    }
                                    k++;
                                }
                            }
                        }
                    }
                }
                return true;
            };

            try
            {
                if (string.IsNullOrEmpty(url)) { throw new Exception("The URL can not be empty"); }

                string fileName = String.Empty;
                System.Data.DataTable dt = new System.Data.DataTable();
                List<string> tempFiles = new List<string>();

                // reading XLS files
                if (url.Contains("|||"))
                {
                    var arrayOfURL = url.Split(new string[] { "|||" }, StringSplitOptions.RemoveEmptyEntries);
                    for (var i = 0; i < arrayOfURL.Length; i++)
                    {
                        var fileResp = ASF.CoreLib.APIHelper.GetCmsResource(new ASF.CoreLib.Messages.GetCmsResourceRequest()
                        {
                            Domain = domain,
                            Token = token,
                            Url = arrayOfURL[i]
                        });
                        fileName = fileResp.Resource.FullFileSystemPath;

                        //fileName = Ecx.Rule.Helpers.DocumentHelper.DownloadDocument(token, domain, arrayOfURL[i]);
                        //fileName = arrayOfURL[i];
                        ReadFileToDataTable(fileName, dt);
                        fileResp.Resource.Stream.Close();
                        tempFiles.Add(fileName);
                    }
                }
                else
                {
                    var fileResp = ASF.CoreLib.APIHelper.GetCmsResource(new ASF.CoreLib.Messages.GetCmsResourceRequest()
                    {
                        Domain = domain,
                        Token = token,
                        Url = url
                    });
                    fileName = fileResp.Resource.FullFileSystemPath;
                    //fileName = url;
                    ReadFileToDataTable(fileName, dt);
                    fileResp.Resource.Stream.Close();
                    tempFiles.Add(fileName);
                }

                // create a XML parameter
                System.Xml.Linq.XElement xmlElements = new System.Xml.Linq.XElement("Translations");
                foreach (System.Data.DataRow row in dt.Rows)
                {
                    xmlElements.Add(new System.Xml.Linq.XElement("Translation", 
                        dt.Columns.Cast<System.Data.DataColumn>().Select(col =>
                        new System.Xml.Linq.XElement(col.ColumnName, new System.Xml.Linq.XCData(row[col].ToString()))
                        ))
                    );
                }

                //Call the rule for import data
                var param = new ASF.Framework.Service.Parameters.ParameterCollection();
                param.AddParameter(new Parameter { Type = ASF.Framework.Service.Parameters.ParameterType.LargeText(), Name = "XML_INPUT", Value = xmlElements.ToString() });
                var importDataToDB = ASF.CoreLib.APIHelper.BDSExecute(new ASF.BDS.WebService.Messages.ExecuteRequest()
                {
                    DataCommand = "root_LOC_ImportTranslation",
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
                response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = "The dictionary translations was successfully import" });
                response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 0 });
            }
            catch (Exception ex)
            {
                var errorMessage = ex.Message;
                response.Result.AddParameter(new Parameter() { Name = "ErrorMessage", Value = errorMessage });
                response.Result.AddParameter(new Parameter() { Name = "SuccessResponse", Value = string.Empty });
                response.Result.AddParameter(new Parameter() { Name = "ErrorCode", Value = 101 });
            }
