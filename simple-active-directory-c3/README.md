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
