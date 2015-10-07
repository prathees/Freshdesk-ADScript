Freshservice-ADScript
==================


When you are getting started with your Freshservice account, you probably want to bring in all your employees into your new service desk as requesters.

Instead of adding them one by one manually, or importing them with a CSV, you can use your existing Active Directory setup to authenticate users into your support portal easily. This involves setting up Single Sign On (SSO) for your service desk by using a Classic ASP script. 

This article talks about configuring Simple SSO in Freshservice using the Active Directory. The script will be hosted in the IIS server and will have access to the Active Directory to authenticate users in Freshservice.

If you’d like to configure SSO using SAML universal standard, refer to the article on SAML SSO.

#Steps to configure SSO in Freshservice using Active Directory

##STEP 1: Installing Internet Information Services (IIS)
Internet Information Server (IIS Manager) should be configured on Windows Server to host the Classic ASP script file which will access user information from the Active directory.

You can follow the steps given in this article to install IIS 8 on Windows Server 2012. Please choose the following options while installing IIS role on the Server.

	*Web Server (IIS)*
		*Security*
			*Windows Authentication*
		*Application Development*
			*ASP*
		*Management Tools*
	*IIS Management Console*

You need ASP to host the Classic ASP script and Windows Authentication to authenticate users in the Active Directory for Freshservice. So if you’ve already installed IIS, make sure that these features are installed.

##STEP 2: Editing the Classic ASP script file
1. Download the ADScript.asp and Constants.asp files attached below.
2. Open the Constants.asp file and assign these values to the variables 
  a. sLdapReaderUsername: Username of the AD account which has at least read privilege to all the users in the AD
  b. sLdapReaderPassword: Password of that user account
  c. sToken: Shared secret copied from Freshservice. Admin → Security → Single Sign On → Simple SSO → Shared Secret
  d. sReturnURL: Freshservice URL in the format "http://domain.freshservice.com/login/sso"
Example
 sLdapReaderUsername = "FRESHSERVICE\admin"
 sLdapReaderPassword = "xxxxxxxxx"
 sToken = "xxxxxxxxxxxxxxxxxxxxxxxxxx"
 sReturnURL = "http://example.freshservice.com/login/sso"
3. Save the Constants.asp file.

##STEP 3: Configuring the ASP script in the IIS
1. Create a site or use the existing site available in IIS. To create a new website in IIS, go through the Create a new Web site section in this article.
2. Click on the site and double click ASP on the right pane. Set Enable Parent Paths to true.
3. Click on the site again and double click Authentication. Right click Windows Authentication and click Enable. Disable all the other authentication types. IIS will use the integrated Windows authentication. To make it possible, IIS Server should be installed on the Active Directory Domain which contains the users.
4. Now right click on the site, click Explore and paste the 2 files- ADScript.asp and Constants.asp which are configured already.
5. Navigate to the ADScript.asp path. You will be authenticated and logged into Freshservice.

###Prerequisites
The Classic ASP script uses your mail attribute as an email holder. It will fetch the email address from your mail attribute. So it is mandatory to have the mail attribute populated in User Attributes to successfully log into Freshservice.

So if you get the error “Couldn't login to Freshdesk. Please contact your administrator”, check whether the email address is configured for you in the Active directory.

##STEP 4: Setting up SSO in Freshservice
1. Go to the Admin tab and click on the Security icon.
2. Toggle the switch to enable Single Sign On.
3. Remote Login URL - Enter the URL which Freshservice will call when users attempt to login to the help desk. This should point to your Active Directory script page. Paste the ADScript.asp IIS navigation path here.
4. Remote logout URL - Enter the URL to which users need to be redirected to, after they log out of Freshservice. Leaving it empty will take users to the homepage of the support portal.

Once you are done, please try to access the script from the URL you specified inside Freshservice. Also, make sure that all IIS calls made to this script are with integrated authentication and not anonymously. If you face any issues while setting this up, please get in touch with us at support@freshservice.com.
