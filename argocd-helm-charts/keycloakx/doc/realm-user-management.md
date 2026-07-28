# Realm, User & Authentication Management

This document covers initial Keycloak administration, realm creation, user management, browser authentication flows, WebAuthn/YubiKey 2FA configuration, and SMTP email setup.

---

## Table of Contents
- [Basic Keycloak Setup](#basic-keycloak-setup)
- [User Administration](#user-administration)
- [Make Logins Easier for the User](#make-logins-easier-for-the-user)
- [Set a Specific Client to a Specific Authentication Flow](#set-a-specific-client-to-a-specific-authentication-flow)
- [Enabling and Forcing YubiKey (WebAuthn) Authentication](#enabling-and-forcing-yubikey-webauthn-authentication)
- [Configure Keycloak to Send Email](#configure-keycloak-to-send-email)

---

## Basic Keycloak Setup

* Log into the Keycloak server as admin: `https://keycloak.example.com/auth/admin/`
  * The password can be extracted from the `keycloak-admin` secret.
* Make sure that you are in the `Master` realm
* Create a personal admin user account:
  * Manage -> Users -> Add user
  * Fill out `Username`, `Email`, `First name` and `Last name`
  * Email Verified: `On`
  * Click `Save`
  * Give the user admin rights:
    * Role mappings -> Available Roles -> `admin` -> Add selected
* Set a password for your personal admin account:
  * Click `Credentials`
  * Enter your unique password in both fields
  * Temporary: `Off`
  * Click `Set Password`
* Create a new realm:
  * Skip this step if the `<customer_name>` realm already exists
  * Move the pointer to `Master ∨` in the top left corner, and click `Add realm`
  * Name: `<customer_name>` (without any spaces)

---

## User Administration

### Adding Normal Users to the Customer Realm

* Have the user access `https://keycloak.example.com/auth/realms/<customer_name>/account/`
  * Click `Personal Info` link
  * The basic user account is now created
* Add the user to the group that describes their access needs:
  * Log into the Keycloak server using your personal admin user
  * Go to the `<customer_name>` realm
  * Manage -> Users -> View all users
  * Click `Edit` on the row describing the user
  * Groups -> Available groups
  * Click the group where the user belongs, and click `Join`

### Adding Admin Users in Master Realm

* Select realm `master`
  > **NOTE:** The `master` realm is sacred. Add users wisely. For general devops purposes, use a dedicated realm (such as `devops`).
* From [Keycloak homepage](https://keycloak.your.domain.com/auth/admin/master/console/), go to [users](https://keycloak.your.domain.com/auth/admin/master/console/#/realms/master/users) and click `View all users`
* Click `Add User`
* Fill in user details. Under `Required User Actions`, add `Update Password` (so user changes password on login)
* Click `Save`
* Click `Credentials`, specify a temporary password, and make sure `Temporary` is set to **ON**
* Click `Role Mappings`, and under `Available Roles` select `admin` and click `Add Selected`
  > **NOTE:** The `admin` role in `master` realm is very powerful; assign it with caution.

---

## Make Logins Easier for the User

If users log in to `<customer_name>` primarily using Google OAuth, you can set Google as the default redirector:

* Log into Keycloak using your personal admin account
* Go to the `<customer_name>` realm
* Configure -> Authentication -> Flows -> Browser -> Identity Provider Redirector -> Actions -> Config
  * Alias: `google`
  * Default Identity Provider: `google`

---

## Set a Specific Client to a Specific Authentication Flow

If specific clients (e.g., ArgoCD) need to display multiple OIDC providers on the Keycloak login page:

1. Go to the `<customer_name>` realm
2. Navigate to **Authentication -> Flows -> Browser -> Duplicate flow -> Set name for flow**
3. Ensure **Identity Provider Redirector -> Actions -> Config** has **no** default IdP set
4. Go to the client (e.g., ArgoCD) in the `<customer_name>` realm
5. Select **Clients -> Client details -> Advanced -> Authentication flow overrides -> Select duplicated flow**

---

## Enabling and Forcing YubiKey (WebAuthn) Authentication

By default, Keycloak uses username/password authentication. To enable and prioritize YubiKey 2FA:

1. Go to `<customer_name>` realm, and click on **Authentication**.
2. Navigate to **Authentication -> Flows** and duplicate the default **Browser** flow.
3. In your duplicated flow, set **Browser - Conditional 2FA** to **Required**.
4. Drag **WebAuthn Authenticator** directly *above* the **OTP Form** so hardware keys are prompted first.
5. Set both **WebAuthn Authenticator** and **OTP Form** to **Alternative**.
6. Click the action menu and select **Bind flow** to set this as default **Browser flow**.
7. Go to **Authentication -> Policies -> WebAuthn Policy**.
8. Configure **Require discoverable credential** to **No** (if supporting YubiKey v4).
9. Go back to **Authentication -> Required actions**.
10. Set **Set as default action** in **WebAuthn Register** to **On**.

---

## Configure Keycloak to Send Email

* Extract SMTP username and password from Terraform state:
  * Navigate to your `iac_iam` repository directory
  * Execute `terraform refresh`
  * Execute:

    ```sh
    terraform show -json | jq -e '.values.root_module.child_modules[].resources[] | select(.name=="keycloak-smtp") | select(.type=="aws_iam_access_key")|{cluster:.index,smtp_user:.values.id,smtp_pass:.values.ses_smtp_password_v4}'
    ```

* Log into Keycloak as admin and go to `<customer_name>` realm
* Configure -> Realm Settings -> Email
  * Host: `email-smtp.eu-west-1.amazonaws.com`
  * Port: `587`
  * From Display Name: `<Customer Name> Keycloak`
  * From: `info@<customer_name>.com`
  * Envelope From: `info@<customer_name>.com`
  * Enable StartTLS: `On`
  * Enable Authentication: `On`
  * Username: &lt;*Extracted from Terraform state*&gt;
  * Password: &lt;*Extracted from Terraform state*&gt;
* Click `Test connection` (must succeed)
* Click `Save`
