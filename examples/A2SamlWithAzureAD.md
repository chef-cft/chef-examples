# HowTo - Setting up SAML Auth in A2 with Azure AD

#### Before You Start
##### Assumptions
- This guide assumes you have the following set up:
    - Azure AD
        - Admin Rights to the Instance
    - Chef Automate 2.0

##### Versions Tested On
- Chef Automate | [2.x]

#### References
- https://www.brittanynwoods.com/blog/automate-2-saml

#### Azure AD Config
1. In azure ad portal (https://portal.azure.com) under azure active directory and then under enterprise apps. Create a new Non-Gallery Application
2. After naming it, Click on single signon and select SAML
3. In section 1 – Basic SAML Configuration, enter following:
   1. Identifier (Entity ID): https://serverfqdn/dex/callback
   1. Reply URL (Assertion Consumer Service URL): https://serverfqdn/dex/callback
4. In section 2: User Attributes and Claims check the defaults that are there.
   1. Keep:
      1. Required Claim:
         - Unique User Identifier (Name ID)
         - Source attribute: `user.userprincipalname`
      2. Additional Claims 
         1. givenname
            - Namespace:  http://schemas.xmlsoap.org/ws/2005/05/identity/claims
            - Source attribute: `user:givenname`
         1. name
            - Namespace:  http://schemas.xmlsoap.org/ws/2005/05/identity/claims
            - Source attribute: `user:userprincipalname`
         1. surname
            - Namespace:  http://schemas.xmlsoap.org/ws/2005/05/identity/claims
            - Source attribute: `user:surname`
      3. Add the following additional claims (may need to delete existing entries for emailaddress and username if they already exist).
         1. emailaddress
            - Namespace: leave namespace blank
            - Source attribute: `user.mail`
         1. username
            - Namespace: leave namespace blank
            - Source attribute: `user.mail`
5. In section 3 – SAML Signing certificate. 
   1. Download the certificate (Base64).
6. Note the following values from Section 4:
   1. Login URL.
   1. Azure AD Identifier.
   1. Logout URL.

#### Chef Automate V2

1. SSH to your A2 instance.
2. Create a file called `saml.toml` where we will put in configuration information.
3. In the `saml.toml` file, you will need to add the following information in the example format listed:
   1. `ca_contents`: this is the X.509 Certificate from step 5 above. Copy this and paste as the value for ca_contents. Use three double quotes to indicate a multiline string. (ex: `"""`)
   1. `sso_url`: This is the value for Identity Provider Single Sign-On URL using the Login URL Value from step 6 above.
   1. `email_attr`: The value for this should be `emailaddress`
   1. `username_attr`: The value for this should be `username`
   1. `entity_issuer`: This should be the URL for your automate server plus `/dex/callback`. (ex: https://serverfqdn/dex/callback)
   1. Save and close the file.
