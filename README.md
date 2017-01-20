# EntityImage
## Embeddable element for a Infor CRM QuickForm to allow the user to select an image for the entity.

These files must be added to a folder named "EntityImage" in the SlxClient\SupportFiles\SmartParts folder. You can then add this ImageSelect.aspx file to any quickform using the Web Dynamic Content control. 
Set the control's height and width as needed and set the DynamicURL property to the following (where "EntityName" is the name of the entity):

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
	

Additionally, you can improve the look of this on the deployed form by adding the following to a C# Snippet LoadAction (this assumes you've named the control "frameImage"):

	ScriptManager.RegisterClientScriptBlock(this, GetType(), "imageStyle_Script", "$('head').append('<style type=\"text/css\"> #" + frameImage.ClientID + " div, #" + frameImage.ClientID + " div iframe { overflow-x: hidden !important; overflow-y: hidden !important; border: none; }</style>');", true);

There are two required parameters that must be included in the URL and one optional.

Required Parameters:
* **entityId**: The ID of the record the image is for
* **entity**: The name of the entity for the entityId

If Storing in Database, include Parameters:
* **dataTable**: The name of a table to save the image to (such as "Contact")
* **dataField**: The field on the table specified above to save the image to (such as "ContactImage" - must be a BLOB field)
* **dataId**: The ID of the row the image is for (such as "ContactId" - Note: this is the field name, not the ID value)
(Note: omit these parameters to save image in attachments folder)

Optional Parameters:
* **folder**: The subfolder to store the images in under the attachements folder. Unless otherwise specified the subfolder will be "Images". Note, the entity name will be a subfolder under this one. _Note: The images will be stored in the attachments folder. This will be the subfolder in that directory where images will be stored._

The folder where the images will be stored is:

	{AttachmentsPath}\Images\EntityName\

unless a folder parameter is included in the URL:

	{AttachmentsPath}\FolderParameter\EntityName\

For more info, see http://customerfx.com
