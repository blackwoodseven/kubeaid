# Identity Provider (IdP) Integrations

This document covers configuring Keycloak with external identity providers (Google, Azure AD, and Keycloak-to-Keycloak identity brokering) and mapping external provider groups to local Keycloak roles.

---

## Table of Contents
- [Setup Keycloak with Google as its Identity Provider](#setup-keycloak-with-google-as-its-identity-provider)
- [Setup Keycloak with Azure AD as its Identity Provider](#setup-keycloak-with-azure-ad-as-its-identity-provider)
- [Setup Keycloak as Identity Provider on a Keycloak](#setup-keycloak-as-identity-provider-on-a-keycloak)
- [Allow Group from external Identity provider to mapper with local keycloak](#allow-group-from-external-identity-provider-to-mapper-with-local-keycloak)

---

## Setup Keycloak with Google as its Identity Provider

* Log into the keycloak server, using your personal admin account
* Switch to the `<customer_name>` realm
* Follow this description:
  * <https://access.redhat.com/documentation/en-us/red_hat_single_sign-on/7.3/html/server_administration_guide/identity_broker#google>
    * There is a backup of the documentation [here](../static/GoogleSetup.pdf).
  * Google project name: `Keycloak`
  * Hint: Enable `Trust Email`
* Create roles: Configure -> Roles -> Add Role
  * Create `kube_admin` role
  * Create `kube_developer` role
  * *ToDo*: Add more user roles
* Create groups, and their role mappings
  * Manage -> Groups -> New
  * Create `SRE` group, with role mappings to `kube_admin`
  * Create `Developer` group, with role mappings to `kube_developer`
  * *ToDo*: Add more user groups

---

## Setup Keycloak with Azure AD as its Identity Provider

### Configure Azure App Registration
1.  Create an App Registration in Azure AD:
    - Navigate to Azure AD and create a new app registration

    ![azure](../static/1.png)
    - Register Keycloak as an Application in Azure AD

    ![azure](../static/2.png)
    - Save the Client ID and Client Secret from Azure AD. This information will be needed later in Keycloak.
2. Obtain Client ID and Client Secret
    - After the registration is complete, go to the app's overview page and copy the "Application (client) ID".
    - Navigate to "Certificates & secrets" and create a new client secret. Copy the value of the client secret as it will not be shown again.

    ![azure](../static/3.png)
3. Configure API Permissions:
    - Go to "API permissions" and add the required Microsoft Graph API permissions. Typically, you need `User.Read` and `openid`, `profile`, and `email` permissions.

    ![azure](../static/4.png)

    ![azure](../static/5.png)
4. On click Add a permission, the above similar pane will be displayed as shown and you will click on Add permission. Then, after Add permission, you will have similar configuration to the below image.

    ![azure](../static/6.png)
5. First, let’s create a realm for this purpose and choose after the realm is selected.
    ![azure](../static/7.png)
6. Next, we are going to create the OpenID Connect configuration with the Azure App Registration details already created above.
    ![azure](../static/8.png)
    - In the detail page, fill out the details as required below:
    * Enter the alias of your choice. Enable Use discovery endpoint, if not already enabled
    * Input the Discovery URL from Azure (copied before) into the Discovery endpoint
    * Input the Client ID. This is the application (client) ID copied from Azure app registration.
    * Input Client Secret. This is the application secret copied from Azure app registration
    ![azure](../static/9.png)
    - Next, copy the redirect URL. This needs to be updated in the Azure app registration.
    - Go back to the Azure registered app, and click “Add a Redirect URL” → “Add a platform” → “Web”. Input the redirect URL in the required field and click Configure.
    ![azure](../static/10.png)
    - To make sure this integration works, we need to see whether the default account URL redirects to Azure AD SSO as we configured. For this, go to Keycloak interface, choose your realm and go to “Clients” from the left panel and click on “account-console”.
    ![azure](../static/11.png)
    - Click on Settings tab
      * for “Valid Redirect URIs”, fill the appropriate redirect URI for your UI app
      * for “Web origins”, fill * for all origins (for production, use private secured client network)
      * click Save.
    ![azure](../static/12.png)

---

## Setup Keycloak as Identity Provider on a Keycloak

> For the full walk-through — brokering with group sync into NetBird and Kubernetes (ClusterProxy), without creating local groups — see [Keycloak-to-Keycloak identity brokering](keycloak-to-keycloak-idp.md).

* Log into the keycloak server, using your personal admin account
* Switch to the `<customer_name>` realm
* Click on Identity Provider -> Add provider -> Keycloak OIDC
* Set the alias and displayname
* Set the `Authorization Url` as `https://keycloakx.kam.obmondo.com/auth/realms/Obmondo/protocol/openid-account/auth`
* Set the `Token Url` as `https://keycloakx.kam.obmondo.com/auth/realms/Obmondo/protocol/openid-account/token`
* Set the `Client Authentication` as `Client secret sent as basic auth`
* Set the `Client ID` as `kubeaid-employee`
* Set the `Client Secret` as `secret-from-obmondo`
* Toggle the `pass login hint`
* Save

---

## Allow Group from external Identity provider to mapper with local keycloak

* Select the relevant realm
* Select the external Identity Provider (You want groups from this ID to map with local groups)
* Select Mappers from the tabs
* Click on "Add mapper" [here](../static/identity_provider_mapper.png)
* Add a [local group](../static/create_local_group.png), Make sure the group name is same with the external ID.
* Add a mapper on the client.
  * Select the relevant client, for example (argocd)
  * Click on Client Scope
  * Click on 'argocd-dedicated' (this is created by keycloak for you automatically)
  * Click on 'Add mapper' and 'By configuration'
  * Fill in the name and 'Token Claim Name' [here](../static/mapper.png)
* Save
