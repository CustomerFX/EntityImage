<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.OleDb" %>
<%@ Import Namespace="System.Drawing" %>

<!-- 

This can be embedded in a Infor CRM quickform to allow the user to select an image for the entity.

These files must be added to a folder named "EntityImage" in the SlxClient\SupportFiles\SmartParts folder.
You can then add this ImageSelect.aspx file to any quickform using the Web Dynamic Content control. 
Set the control's height and width as needed and set the DynamicURL property to the following (where
"EntityName" is the name of the entity):
    
    NOTE: Replace EntityId and EntityName with the ID and name for the entity
    
    TO STORE IMAGE IN ATTACHMENTS FOLDER USE:
    -----------------------------------------
	SmartParts/EntityImage/ImageSelect.aspx?entityId=EntityId&entity=EntityName
    
    Example (in Load Action for Contact):
    frameImage.DynamicURL = string.Format("SmartParts/EntityImage/ImageSelect.aspx?entityId={0}&entity=Contact", contact.Id);
    

    TO STORE IMAGE IN TABLE IN DATABASE USE:
    ----------------------------------------
	SmartParts/EntityImage/ImageSelect.aspx?entityId=EntityId&entity=EntityName&DataTable=SomeTable&DataField=SomeField&DataId=SomeIdField
    
    Example (in Load Action for Contact to save in CONTACT.CONTACTIMAGE Blob field)
    frameImage.DynamicURL = string.Format("SmartParts/EntityImage/ImageSelect.aspx?entityId={0}&entity=Contact&DataTable=Contact&DataField=ContactImage&DataId=ContactId", contact.Id);
    

Additionally, you can improve the look of this on the deployed form by adding the following to a
C# Snippet LoadAction (this assumes you've named the control "frameImage"):

	ScriptManager.RegisterClientScriptBlock(this, GetType(), "imageStyle_Script", "$('head').append('<style type=\"text/css\"> #" + frameImage.ClientID + " div, #" + frameImage.ClientID + " div iframe { overflow-x: hidden !important; overflow-y: hidden !important; border: none; }</style>');", true);

There are two required parameters that must be included in the URL and one optional.

Required Parameters:
"entityId": The ID of the record the image is for
"entity": The name of the entity for the entityId
    
If Storing in Database, include Parameters:
"dataTable": The name of a table to save the image to (such as "Contact")
"dataField": The field on the table specified above to save the image to (such as "ContactImage" - must be a BLOB field)
"dataId": The ID of the row the image is for (such as "ContactId")
(Note: omit these parameters to save image in attachments folder)

Optional Parameters:
"folder": The subfolder to store the images in under the attachements folder. Unless otherwise specified
	      the subfolder will be "Images". Note, the entity name will be a subfolder under this one.

-->

<html>

<head runat="server">
    <title>Image Select & Upload</title>

    <link rel="stylesheet" type="text/css" href="~/css/themes/inforSoHoXi/inforSoHoXi.css" />
    <link rel="stylesheet" type="text/css" href="~/css/sage-styles.css" />
    <link rel="stylesheet" type="text/css" href="~/css/layout-ie.css" />

    <style>
        .fxthumbnail img {
            max-height: 200px;
            max-width: 200px;
        }
        #fileUpload {
            font-size: 14px;
        }
        #labelError, #labelMessage {
            margin-top: 12px;
            display: block;
            width: 100%;
            white-space: normal;
        }
    </style>
</head>

<body class="inforSoHoXi">
    <form id="FormMain" runat="server">
        
		<asp:PlaceHolder runat="server" ID="upload">
			<b>Select an image for this <%= Entity %>:</b><br />
			<asp:FileUpload ID="fileUpload" runat="server" onchange="javascript:__doPostBack('buttonUpload','')" accept="image/png, image/jpeg, image/gif, image/tiff, image/bmp" /><br />
			<asp:LinkButton ID="buttonUpload" runat="server" Text="Set Product Image" OnClick="buttonUpload_Click" style="display:none;"></asp:LinkButton>
			<br />
		</asp:PlaceHolder>

		<asp:PlaceHolder runat="server" ID="content">
			<asp:HyperLink runat="server" ID="LinkImage" Target="_blank" CssClass="fxthumbnail"></asp:HyperLink>
			<br />
			<asp:HyperLink runat="server" ID="linkView" Text="View" Target="_blank"></asp:HyperLink> &nbsp;
			<asp:LinkButton runat="server" ID="ButtonRemove" Text="Remove Image" OnClick="ButtonRemove_Click"></asp:LinkButton> 
		</asp:PlaceHolder>

		<asp:PlaceHolder runat="server" ID="error">
			<asp:Label runat="server" ID="labelError" ForeColor="Red"></asp:Label>
			<asp:Label runat="server" ID="labelMessage" Font-Italic="true"></asp:Label>
		</asp:PlaceHolder>
			
    </form>
</body>

<script language="c#" runat="server">

    private static string _DEFAULTFOLDER = "Images";

    public void Page_Load(object sender, EventArgs e)
    {
        fileUpload.Attributes.Add("onchange", "__doPostBack('buttonUpload','')");

        if (Page.IsPostBack) return;

        if (string.IsNullOrEmpty(EntityId))
        {
            ShowError(string.Format("You must first save the {0}.", Entity));
            return;
        }

        if (!IsForFileSystem)
        {
            if (!ValidateField(DataTable, DataField) || !ValidateField(DataTable, DataId))
            {
                ShowError("Error validating the database field for images.");
                return;
            }
        }

        if (ImageExists)
        {
            upload.Visible = false;
            content.Visible = true;
            ShowImage();
        }
        else
        {
            upload.Visible = true;
            content.Visible = false;
        }
    }

    private string EntityId
    {
        get { return Request.QueryString["entityId"]; }
    }

    private string Entity
    {
        get { return Request.QueryString["entity"]; }
    }

    private string DataTable
    {
        get { return Request.QueryString["dataTable"]; }
    }

    private string DataField
    {
        get { return Request.QueryString["dataField"]; }
    }

    private string DataId
    {
        get { return Request.QueryString["dataId"]; }
    }

    private bool IsForFileSystem
    {
        get { return (string.IsNullOrEmpty(DataTable) || string.IsNullOrEmpty(DataField) || string.IsNullOrEmpty(DataId)); }
    }

    private string GetImageLink()
    {
        return (!ImageExists
            ? string.Empty
            : IsForFileSystem
                ? string.Format("~/SmartParts/EntityImage/ImageHandler.ashx?file={0}", HttpContext.Current.Server.UrlEncode(ImageSubFolder + "/" + ImageFile))
                : string.Format("~/SmartParts/EntityImage/ImageHandler.ashx?dataTable={0}&dataField={1}&dataId={2}&entityId={3}", DataTable, DataField, DataId, EntityId)
            );
    }

    private string ImageFile
    {
        get { return EntityId + ".png"; }
    }

    private string FullImagePath
    {
        get { return Path.Combine(ImageFolder, ImageFile); }
    }

    private bool ImageExists
    {
        get
        {
            return (IsForFileSystem
                ? File.Exists(FullImagePath)
                : HasDataImage());
        }
    }

    private string ImageFolder
    {
        get
        {
            var folder = Path.Combine(AttachmentPath, ImageSubFolder);
            if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
            return folder;
        }
    }

    private string ImageSubFolder
    {
        get
        {
            var folder = Request.QueryString["folder"];
            if (string.IsNullOrEmpty(folder)) folder = _DEFAULTFOLDER;
            if (!string.IsNullOrEmpty(Entity)) folder = folder + @"\" + Entity;
            return folder;
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

    private bool HasDataImage()
    {
        using (var conn = new OleDbConnection(ConnectionString))
        {
            conn.Open();
            using (var cmd = new OleDbCommand(string.Format("select {0} from {1} where {2} = ?", DataField, DataTable, DataId), conn))
            {
                cmd.Parameters.AddWithValue("@id", EntityId);
                var data = cmd.ExecuteScalar();
                return (data != null && data != DBNull.Value);
            }
        }
    }

    private bool HasDataRecord()
    {
        using (var conn = new OleDbConnection(ConnectionString))
        {
            conn.Open();
            using (var cmd = new OleDbCommand(string.Format("select count(*) as cnt from {0} where {1} = ?", DataTable, DataId), conn))
            {
                cmd.Parameters.AddWithValue("@id", EntityId);
                return (Convert.ToInt32(cmd.ExecuteScalar()) > 0);
            }
        }
    }

    private bool SaveDataImage(byte[] ImageBytes)
    {
        if (!HasDataRecord())
        {
            ShowError("Record must first be saved.");
            return false;
        }

        using (var conn = new OleDbConnection(ConnectionString))
        {
            conn.Open();
            using (var cmd = new OleDbCommand(string.Format("update {0} set {1} = ? where {2} = ?", DataTable, DataField, DataId), conn))
            {
                cmd.Parameters.AddWithValue("@field", ImageBytes);
                cmd.Parameters.AddWithValue("@id", EntityId);
                cmd.ExecuteNonQuery();
            }
        }
        return true;
    }

    private void RemoveDataImage()
    {
        SaveDataImage(null);
    }

    private string ConnectionString
    {
        get
        {
            var dataSvc = Sage.Platform.Application.ApplicationContext.Current.Services.Get<Sage.Platform.Data.IDataService>() as Sage.Platform.Data.IDataService;
            return dataSvc.GetConnectionString();
        }
    }

    private void ShowError(string Message)
    {
        upload.Visible = false;
        content.Visible = false;
        error.Visible = true;
        labelMessage.Text = Message;
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

    private void ShowImage()
    {
        var image = GetImageLink();
        if (string.IsNullOrEmpty(image))
        {
            upload.Visible = true;
            content.Visible = false;
            return;
        }

        upload.Visible = false;
        content.Visible = true;

        LinkImage.ImageUrl = image;
        LinkImage.NavigateUrl = image;
        linkView.NavigateUrl = image;
    }

    protected void buttonUpload_Click(object sender, EventArgs e)
    {
        error.Visible = false;

        if (fileUpload.HasFile)
        {
            try
            {
                var fileName = Path.Combine(ImageFolder, EntityId + ".png");
                var ext = Path.GetExtension(fileUpload.FileName).ToLower().Replace(".", "");

                if (ext != "png" && ext != "jpg" && ext != "gif" && ext != "bmp" && ext != "tiff")
                    throw new Exception("Please select an image file.");

                if (IsForFileSystem)
                {
                    var bitmap = Bitmap.FromStream(fileUpload.PostedFile.InputStream);
                    bitmap.Save(fileName, System.Drawing.Imaging.ImageFormat.Png);
                }
                else
                {
                    using (var stream = fileUpload.PostedFile.InputStream)
                    {
                        var imageBytes = new byte[(int)stream.Length + 1];
                        stream.Read(imageBytes, 0, (int)stream.Length);
                        stream.Close();
                        if (!SaveDataImage(imageBytes)) return;
                    }
                }

                upload.Visible = false;
                content.Visible = true;
                ShowImage();

            }
            catch (Exception ex)
            {
                content.Visible = false;
                upload.Visible = false;
                error.Visible = true;
                labelError.Text = "Error uploading image. " + ex.Message;
            }
        }

    }

    protected void ButtonRemove_Click(object sender, EventArgs e)
    {
        try
        {
            if (IsForFileSystem)
                File.Delete(FullImagePath);
            else
                RemoveDataImage();

            upload.Visible = true;
            content.Visible = false;

        }
        catch (Exception ex)
        {
            content.Visible = false;
            upload.Visible = false;
            error.Visible = true;
            labelError.Text = "Error deleting image. " + ex.Message;
        }
    }

</script>
   
</html>