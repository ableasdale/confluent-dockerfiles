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

