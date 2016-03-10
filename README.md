# EntityImage
## Embeddable element for a Infor CRM QuickForm to allow the user to select an image for the entity.

These files must be added to a folder named "EntityImage" in the SlxClient\SupportFiles\SmartParts folder. You can then add this ImageSelect.aspx file to any quickform using the Web Dynamic Content control. 
Set the control's height and width as needed and set the DynamicURL property to the following (where "EntityName" is the name of the entity):

	SmartParts/EntityImage/ImageSelect.aspx?entityId=${Id}&entity=EntityName

Additionally, you can improve the look of this on the deployed form by adding the following to a C# Snippet LoadAction (this assumes you've named the control "frameImage"):

	ScriptManager.RegisterClientScriptBlock(this, GetType(), "imageStyle_Script", "$('head').append('<style type=\"text/css\">" + frameImage.ControlID + " div, " + frameImage.ControlID + " div iframe { overflow-x: hidden !important; overflow-y: hidden !important; border: none; }</style>');", true);

There are two required parameters that must be included in the URL and one optional.

Required Parameters:
* **entityId**: The ID of the record the image is for
* **entity**: The name of the entity for the entityId

Optional Parameters:
* **folder**: The subfolder to store the images in under the attachements folder. Unless otherwise specified the subfolder will be "Images". Note, the entity name will be a subfolder under this one. _Note: The images will be stored in the attachments folder. This will be the subfolder in that directory where images will be stored._

The folder where the images will be stored is:

	{AttachmentsPath}\Images\EntityName\

unless a folder parameter is included in the URL:

	{AttachmentsPath}\FolderParameter\EntityName\

For more info, see http://customerfx.com
