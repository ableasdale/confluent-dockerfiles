# Windows Server 2022 with Active Directory and Confluent Platform 7.5.1 with C3

This project covers the steps required to set up a test Windows Server with Active Directory and to configure it to be used with Confluent Control Center (C3).

## Getting Started

First, you'll need to download a trial version of Windows Server 2022:

<https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022>

Download the `ISO download`: `64-bit edition`

### Configure Virtualbox VM Settings

Now we're going to configure the Display settings for the VM in VirtualBox:

![Configure VM Display](img/vm-display-settings.png)

And we should set the networking to `Bridged Mode` and we'll bind it to our network adaptor:

![Configure Bridged Networking](img/bridged-networking.png)

### Install Windows Server 2022 and Configure Active Directory

Install / Run VirtualBox and create a new VM:

Make sure the path to the ISO file is correct and that the checkbox to skip an unattended installation (`Skip Unattended Installation`) is selected:

![Skip Unattended Windows Server Install](img/configure-virtualbox-unattended.png)

Configure the available memory and CPU resources (and note that you will need to reserve some for running Confluent Platform):

![Configure VM Resources](img/virtualbox-settings.png)

Configure the available disk for the base OS:

![Configure VM Virtual Hard Disk](img/create-vhd.png)

### Begin the Installation

When the ISO boots up, start by configuring the language settings:

![Installer: Language Settings](img/language-settings.png)

And we're going to install the Datacenter edition with the Desktop Experience:

![Installer: Datacenter/Desktop Experience](img/datacenter-desktop.png)

Next, Windows Server will boot and ask you to configure your `Administrator` password:

![Installer: Set Admin Password](img/set-admin-pass.png)

### Log in

In order to log in, you need to issue the `Ctrl+Alt+Delete` key combination; in VirtualBox, you can do this by navigating to the **Input** > **Keyboard** > **Insert Ctrl-Alt-Del** menu option:

![Starting Windows: Login Screen](img/login-screen.png)

As soon as you do this, you'll be able to enter the Administrator password to log in:

![Starting Windows: Login As Administrator](img/adm-password.png)

### Install VirtualBox Guest Additions

In order to install the Guest Additions in Windows, you can navigate to the **Devices** menu and select **Insert Guest Additions CD Image**.  As soon as this is done, you should see ISO mounted in Windows Explorer:

![Starting Windows: Install Guest Additions](img/guest-additions.png)

Begin the installation by clicking on the necessary installer for your architecture (in our case, it's `amd64`):

![Starting Windows: Install 64-bit Guest Additions](img/vm-additions-install.png)

Note that you will need to reboot after these have been installed.

### Configure Active Directory

On restart, we can now set up Active Directory and prepare the stage for configuring Confluent Platform and Confluent Control Center.

Starting up, you'll see the `Server Manager` GUI:

![Configure Active Directory: Server Manager](img/add-roles-and-features.png)

This will start the **Add Roles and Features Wizard**:

![Configure Active Directory: Add Roles and Features Wizard](img/add-roles-wizard-1.png)

From there, select **Role-based or feature-based installation**:

![Configure Active Directory: Installation Type](img/add-roles-wizard-2.png)

In our case, the server is already selected (it's a pool of one..):

![Configure Active Directory: Server Selection](img/add-roles-wizard-3.png)

The next stage will be to add more roles - and we're going to add **Active Directory Domain Services**.  Note that there will be an additional window opened as soon as you select this; confirm by clicking on **Add Features** and finally click **Next**:

![Configure Active Directory: Server Roles](img/add-roles-wizard-4.png)

Now we can choose any additional features; in this case, we can just click **Next**:

![Configure Active Directory: Features](img/add-roles-wizard-5.png)

In the next section, you'll see some general information about **Active Directory Domain Services**, so click **Next**:

![Configure Active Directory: AD DS](img/add-roles-wizard-6.png)

Finally, check **Restart the destination server if required** and click **Install**:

![Configure Active Directory: Confirmation](img/add-roles-wizard-7.png)

You can see the progress indicator as all the components are installed and configured:s

![Configure Active Directory: Installation Progress](img/add-roles-wizard-8.png)

### Post Install: Deployment Configuration

Note that after the installation is complete, you'll see an alert for post-deployment:

![Configure Active Directory: Post Deployment](img/post-deployment.png)

First, we're going to select **Add a new Forest** and then give your domain an appopriate name (in this example, we're using `adtest.confluent.io`):

![Configure Active Directory: Domain Name](img/post-install-deployment-1b.png)

Next we need to set up a password:

![Configure Active Directory: Domain Controller Options](img/post-install-deployment-2.png)

Next, we'll set up DNS - just click Next in this case:

![Configure Active Directory: DNS Options](img/post-install-deployment-3.png)

Next, verify the `NetBIOS` name:

![Configure Active Directory: Additional Options](img/post-install-deployment-4.png)

Confirm the default paths:

![Configure Active Directory: Paths](img/post-install-deployment-5.png)

Now we're going to review everything that we have set so far:

![Configure Active Directory: Review Options](img/post-install-deployment-6.png)

This will be followed by a prerequisites check - this may take some time to complete.  If everything worked as expected, you should see a message stating that **"All prerequisite checks passed successfully"**.  If so, you can click on **Install**:

![Configure Active Directory: Prerequisites Check](img/post-install-deployment-7.png)

You should see that the process ran to completion; the server will now restart for all the changes to take effect:

![Configure Active Directory: Status and Reboot](img/post-install-deployment-8.png)

After restarting, log in and search for `dsa` and select `Active Directory Users and Computers`:

![Active Directory Users and Computers](img/dsa.png)

This will give us the view of the directory:

![Active Directory Users and Computers](img/ad-users.png)

Let's test the connection using `ldapsearch`. First, we need to determine the ip address of the VM - open Powershell and run `ipconfig` and note the IP address next to the IPv4 Address, From there, substitute the IP address and run the command below to search the directory as the `Administrator` user:

```bash
ldapsearch -x -b "CN=Users,DC=ad-test,DC=confluent,dc=io" -H ldap://<IP_ADDR> -D "cn=Administrator,CN=Users,DC=ad-test,DC=confluent,DC=io" -W
```

For example:

```bash
ldapsearch -x -b "CN=Users,DC=ad-test,DC=confluent,dc=io" -H ldap://192.168.1.248 -D "cn=Administrator,CN=Users,DC=ad-test,DC=confluent,DC=io" -W
```

In order to confirm the values for the `-b` and `-D` switches in the above example, we can use `Active Directory Users and Computers`; first we need to enable `Advanced Features` under the `View` menu:

![Active Directory Users and Computers](img/ad-advanced-features.png)

From there, select the `Administrator` user and look at the `distinguishedName` field under the `Attribute Editor`:

![Active Directory: Administrator distinguishedName](img/distinguished-name.png)

## Testing Confluent Platform and Confluent Control Center (C3)

The `docker-compose.yaml` file sets up C3 with all the necessary lines of configuration:

```yaml
      # For LDAP
      CONTROL_CENTER_REST_AUTHENTICATION_ROLES: Administrators,Guests
      CONTROL_CENTER_AUTH_RESTRICTED_ROLES: Guests
      CONTROL_CENTER_REST_AUTHENTICATION_METHOD: BASIC
      CONTROL_CENTER_REST_AUTHENTICATION_REALM: c3
      CONTROL_CENTER_OPTS: "-Djava.security.auth.login.config=/tmp/control-center-jaas.conf -Djava.security.debug=all -Djava.security.auth.debug=all -Dorg.eclipse.jetty.util.log.IGNORED=true"
```

Note that the `CONTROL_CENTER_OPTS` flags are for debug level logging:

```java
-Djava.security.debug=all -Djava.security.auth.debug=all -Dorg.eclipse.jetty.util.log.IGNORED=true
```

And the `control-center-jaas.conf` file contains all the necessary configuration to allow C3 to intercept the initial connection and to hand over the lookup to Active Directory:

```javascript
c3 {
  org.eclipse.jetty.jaas.spi.LdapLoginModule required
  
  useLdaps="false"
  contextFactory="com.sun.jndi.ldap.LdapCtxFactory"
  hostname="<YOUR_IP_ADDR_HERE>"
  port="389"
  bindDn="CN=Administrator,CN=Users,DC=ad-test,DC=confluent,dc=io"
  bindPassword="<ADMINISTRATOR_PASSWORD_HERE>"
  authenticationMethod="simple"
  forceBindingLogin="true"
  userBaseDn="CN=Users,DC=ad-test,DC=confluent,DC=io"
  userRdnAttribute="sAMAccountName"
  userIdAttribute="sAMAccountName"
  userPasswordAttribute="userPassword"
  userObjectClass="person" 
  roleBaseDn="CN=Builtin,DC=ad-test,DC=confluent,DC=io"
  roleNameAttribute="cn"
  roleMemberAttribute="member"
  roleObjectClass="group"
  debug="true";
};
```

At the very least, you will need to modify the `hostname` (to match the IP address for your Windows instance) and the `bindPassword` (used to query the Active Directory).

You will also need to change the `bindDn`, the `userBaseDn` and the `roleBaseDn` to make these match your Active Directory Domain Name.

When you're ready to start the Confluent components:

```bash
docker-compose -d up
```

After a short while, you should be able to access C3:

<http://localhost:9021/>

And you'll see an authentication dialog box:

![C3 Basic Auth Login](img/dialog.png)

In the C3 log, you'll see some logged messages that look like this:

```log
control-center   | [2023-10-31 13:50:37,928] INFO Attempting authentication: CN=Administrator,CN=Users,DC=ad-test,DC=confluent,DC=io (org.eclipse.jetty.jaas.spi.LdapLoginModule)
control-center   | 	[LoginContext]: org.eclipse.jetty.jaas.spi.LdapLoginModule login success
control-center   | 	[LoginContext]: org.eclipse.jetty.jaas.spi.LdapLoginModule commit success
```
