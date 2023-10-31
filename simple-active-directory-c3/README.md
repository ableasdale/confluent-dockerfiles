# Windows Server 2022 with Active Directory and Confluent Platform 7.5.1 with C3

This project covers the steps required to set up a test Windows Server with Active Directory and to configure it to be used with Confluent Control Center (C3).

## Getting Started

First, you'll need to download a trial version of Windows Server 2022:

<https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022>

Download the `ISO download`: `64-bit edition`

### Install Windows Server 2022 and Configure Active Directory

Install / Run VirtualBox and create a new VM:

Make sure the path to the ISO file is correct and that the checkbox to skip an unattended installation (`Skip Unattended Installation`) is selected:

![Skip Unattended Windows Server Install](img/configure-virtualbox-unattended.png)

Configure the available memory and CPU resources (and note that you will need to reserve some for running Confluent Platform):

![Configure VM Resources](img/virtualbox-settings.png)

Configure the available disk for the base OS:

![Configure VM Virtual Hard Disk](img/create-vhd.png)

### Configure Virtualbox VM Settings

Now we're going to configure the VM in VirtualBox:

(TODO)