<%@ WebHandler Language="C#" Class="ImageHandler" %>

using System;
using System.Web;
using System.IO;
using System.Collections.Generic;
using System.Data;
using System.Data.OleDb;
using System.Web.SessionState;
using Sage.Platform.Application;

public class ImageHandler : IHttpHandler, IRequiresSessionState
{
    public void ProcessRequest(HttpContext context)
    {
        var fileReq = context.Request.QueryString["file"];
        if (string.IsNullOrEmpty(fileReq))
        {
            ShowMessage("No file parameter passed.", context);
            return;
        }

        var filePath = Path.Combine(AttachmentPath, context.Server.UrlDecode(fileReq));
        if (!File.Exists(filePath))
        {
            ShowMessage("The requested file no longer exists: " + filePath, context);
            return;
        }

        var file = new FileInfo(filePath);
        context.Response.Clear();
        context.Response.AddHeader("content-dispostion", string.Format("attachment; filename=\"{0}\"", file.Name));
        context.Response.ContentType = GetMimeType(file.Extension);
        context.Response.WriteFile(file.FullName, false);
    }

    private void ShowMessage(string message, HttpContext context)
    {
        context.Response.Clear();
        context.Response.ContentType = "text/plain";
        context.Response.Write(message);
    }

    private string AttachmentPath
    {
        get
        {
            using (var conn = new OleDbConnection(ConnectionString))
            {
                conn.Open();
                using (var cmd = new OleDbCommand("select top 1 attachmentpath from branchoptions where sitecode = (select primaryserver from systeminfo where systeminfoid = 'PRIMARY')", conn))
                {
                    return cmd.ExecuteScalar().ToString();
                }
            }
        }
    }

    private string ConnectionString
    {
        get
        {
            var dataSvc = ApplicationContext.Current.Services.Get<Sage.Platform.Data.IDataService>() as Sage.Platform.Data.IDataService;
            return dataSvc.GetConnectionString();
        }
    }

    public static string GetMimeType(string extension)
    {
        if (!extension.StartsWith(".")) extension = "." + extension;

        string mime;
        return _mappings.TryGetValue(extension, out mime) ? mime : "application/octet-stream";
    }

    private static IDictionary<string, string> _mappings = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase) {
        #region Mime-Types list
        {".jpg", "image/jpeg"},
        {".png", "image/png"},
        {".gif", "image/gif"},
        {".tiff", "image/tiff"},
		{".bmp", "image/bmp"}
    };

    public bool IsReusable { get { return false; } }
}