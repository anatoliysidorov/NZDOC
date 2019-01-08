if (request == null) throw new ArgumentNullException("request", "'request' parameter is null.");
var zip = request.Parameters["ZIP"].Value.ToString();
var UserID = request.Parameters["UserID"].Value.ToString();
string upsResponseXml = "";
try
 { 
    var url = "http://production.shippingapis.com/ShippingAPI.dll?API=CityStateLookup&USERID=" + UserID;
    System.Net.WebRequest innerRequest = System.Net.WebRequest.Create(url);
    innerRequest.Method = System.Net.WebRequestMethods.Http.Post;
    innerRequest.ContentType = "application/x-www-form-urlencoded; charset=UTF-8";
    var data = "XML=<CityStateLookupRequest USERID='" + UserID + "'><ZipCode ID='0'><Zip5>" + zip + "</Zip5></ZipCode></CityStateLookupRequest>";
    byte[] byteArray = System.Text.Encoding.UTF8.GetBytes(data);
    innerRequest.ContentLength = byteArray.Length;
    System.IO.Stream dataStream = innerRequest.GetRequestStream();
    dataStream.Write(byteArray, 0, byteArray.Length);
    dataStream.Close();
    System.Net.WebResponse innerResponse = innerRequest.GetResponse();
    System.IO.StreamReader upsResponseStream = new System.IO.StreamReader(innerResponse.GetResponseStream());
    upsResponseXml = upsResponseStream.ReadToEnd();
    upsResponseStream.Close();
    var doc = System.Xml.Linq.XDocument.Parse(upsResponseXml);
    var items = from item in doc.Descendants("ZipCode")  select item;
    String Zip5 = "";
    String City = "";
    String State = "";
    foreach (System.Xml.Linq.XElement item in items)
    {
        Zip5 = item.Element("Zip5").Value;
        City = item.Element("City").Value;
        State = item.Element("State").Value;
    }
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "UPSRESPONSEXML", Value = upsResponseXml });
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "ZIP5", Value = Zip5 });
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "CITY", Value = City });
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "STATE", Value = State });
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "ERRORCODE", Value = "0" });
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "ERRORMESSAGE", Value = "" });
    return response;
 }
catch (Exception ex)
 {
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "UPSRESPONSEXML", Value = upsResponseXml });
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "ZIP5", Value = "" });
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "CITY", Value = "" });
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "STATE", Value = "" });
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "ERRORCODE", Value = "91" });
    response.Result.AddParameter(new ASF.Framework.Service.Parameters.Parameter { Name = "ERRORMESSAGE", Value = ex.Message });
    return response;
 }