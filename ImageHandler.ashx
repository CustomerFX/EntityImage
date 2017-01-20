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
        var file = context.Request.QueryString["file"];
        var dataTable = context.Request.QueryString["dataTable"];
        var dataField = context.Request.QueryString["dataField"];
        var dataId = context.Request.QueryString["dataId"];
        var entityId = context.Request.QueryString["entityId"];

        if (string.IsNullOrEmpty(file) && (string.IsNullOrEmpty(dataTable) || string.IsNullOrEmpty(dataField) || string.IsNullOrEmpty(dataId) || string.IsNullOrEmpty(entityId)))
        {
            ShowMessage("Incorrect parameters passed.", context);
            return;
        }

        if (!string.IsNullOrEmpty(file))
        {
            var filePath = Path.Combine(AttachmentPath, context.Server.UrlDecode(file));
            if (!File.Exists(filePath))
            {
                ShowMessage("The requested file no longer exists: " + filePath, context);
                return;
            }
            var fileInfo = new FileInfo(filePath);

            context.Response.Clear();
            context.Response.AddHeader("content-dispostion", string.Format("attachment; filename=\"{0}\"", fileInfo.Name));
            context.Response.ContentType = GetMimeType(fileInfo.Extension);
            context.Response.WriteFile(fileInfo.FullName, false);
        }
        else
        {
            if (!ValidateField(dataTable, dataField) || !ValidateField(dataTable, dataId))
            {
                ShowMessage("Invalid database information passed.", context);
                return;
            }

            var imageBytes = GetDataImage(dataTable, dataField, dataId, entityId);
            if (imageBytes == null)
            {
                ShowMessage("The requested image does not exist.", context);
                return;
            }

            context.Response.Clear();
            context.Response.AddHeader("content-dispostion", string.Format("attachment; filename=\"{0}.png\"", entityId));
            context.Response.ContentType = GetMimeType(".png");
            context.Response.OutputStream.Write(imageBytes, 0, imageBytes.Length);
        }


    }

    private void ShowMessage(string message, HttpContext context)
    {
        context.Response.Clear();
        context.Response.ContentType = "text/plain";
        context.Response.Write(message);
    }

    private byte[] GetDataImage(string DataTable, string DataField, string DataId, string EntityId)
    {
        using (var conn = new OleDbConnection(ConnectionString))
        {
            conn.Open();
            using (var cmd = new OleDbCommand(string.Format("select {0} from {1} where {2} = ?", DataField, DataTable, DataId), conn))
            {
                cmd.Parameters.AddWithValue("@id", EntityId);
                return (byte[])cmd.ExecuteScalar();
            }
        }
    }

    private bool ValidateField(string Table, string Field)
    {
        using (var conn = new OleDbConnection(ConnectionString))
        {
            conn.Open();
            using (var cmd = new OleDbCommand("select count(*) as cnt from sectabledefs where tablename = ? and fieldname = ?", conn))
            {
                cmd.Parameters.AddWithValue("@tablename", Table);
                cmd.Parameters.AddWithValue("@fieldname", Field);
                return (Convert.ToInt32(cmd.ExecuteScalar()) > 0);
            }
        }
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

    private static IDictionary<string, string> _mappings = new Dictionary<string, string>(StringComparer.InvariantCultureIgnoreCase)
    {
        {".jpg", "image/jpeg"},
        {".png", "image/png"},
        {".gif", "image/gif"},
        {".tiff", "image/tiff"},
        {".bmp", "image/bmp"}
    };

    public bool IsReusable { get { return false; } }
}