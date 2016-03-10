<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.OleDb" %>
<%@ Import Namespace="System.Drawing" %>

<!-- 

This can be embedded in a Infor CRM quickform to allow the user to select an image for the entity.
There are two required parameters that must be included in the URL and one optional.

Required Parameters:
"entityId": The ID of the record the image is for
"entity": The name of the entity for the entityId

Optional Parameters:
"folder": The subfolder to store the images in under the attachements folder. Unless otherwise specified
	      the subfolder will be "Images". Note, the entity name will be a subfolder under this one.

--!>

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
        
        if (!Page.IsPostBack)
        {
            if (string.IsNullOrEmpty(EntityId))
            {
                upload.Visible = false;
                content.Visible = false;
                error.Visible = true;
                labelMessage.Text = string.Format("You must first save the {0}.", Entity);
                return;
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
    }

    private string EntityId
    {
        get { return Request.QueryString["entityId"]; }
    }
	
	private string Entity
    {
        get { return Request.QueryString["entity"]; }
    }
    
    private string GetImageLink()
    {
		return (!ImageExists ? "" : string.Format("~/SmartParts/Image/ImageHandler.ashx?file={0}", HttpContext.Current.Server.UrlEncode(ImageSubFolder + "/" + ImageFile)));
    }
    
    private string ImageFile
    {
        get { return EntityId + ".png" }
    }
	
	private string FullImagePath
	{
		get { Path.Combine(ImageFolder, ImageFile); }
	}
	
	private bool ImageExists
	{
		get { return File.Exists(FullImagePath); }
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
			if (!string.IsNullOrEmpty(Entity)) folder = folder + "\" + Entity;
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
                using (var cmd = new OleDbCommand("select attachmentpath from branchoptions where sitecode = 'NOSYNCSERVER'", conn))
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
            var dataSvc = Sage.Platform.Application.ApplicationContext.Current.Services.Get<Sage.Platform.Data.IDataService>() as Sage.Platform.Data.IDataService;
            return dataSvc.GetConnectionString();
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
                string filename = Path.Combine(ImageFolder, EntityId + Path.GetExtension(fileUpload.FileName));
                fileUpload.SaveAs(filename);
                
				if (Path.GetExtension(filename).ToLower() != "png")
				{
					var bitmap = Bitmap.FromFile(filename);
					bitmap.Save(Path.GetFileName(imagename) + ".png", ImageFormat.Png);
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
            File.Delete(FullImagePath);

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