#Windows 11 Readiness PowerShell Module

## Overview

In order to help you prepare for your journey to Windows 11, we’ve developed a
PowerShell module that returns the status of devices that are enrolled in
Intune. You can export the results or add them to an Azure AD group as well.
Devices returned can be separated by devices ready for upgrade, not ready for
upgrade, or not ready for upgrade because a specific requirement is not met.

This will allow you to get a good overall picture of your environment and what
actions you can take now and what actions you can take in the future if device
hardware is upgraded. For instance, you can get a list of all devices that don’t
meet drive space requirements and add them to an Azure AD group. You can then
create a plan to upgrade those device’s drives or free up space on the drives.
As you move through that plan, you can rerun the command again and the devices
that have been changed to meet the drive requirements will be removed from the
group, leaving behind devices that still don’t meet the drive requirements. This
will help track progress throughout the project.

## Installing the module

The Win11Readiness module is published on www.PowerShellGallery.com. To install
this module, use the command ‘Import-Module Win11Readiness -Scope CurrentUser’.
If you have not added PowerShell Gallery as a trusted repository, you will be
prompted to confirm the installation.

## Permissions

For the module to access and modify groups in your tenant, permissions must be
granted to the “application”. This module uses the well-known Microsoft.Graph
PowerShell SDK that is registered in the Microsoft tenant.

The first time you use the module, you’ll be prompted to accept these
permissions after signing in. The user signing in must have an AAD role that
allows them to accept, such as Global administrator, or Application
administrator. If the “Consent on behalf of your organization” is checked,
future users will not be prompted to accept the permissions, but this does not
mean that future users won’t need the permissions to run the script. It just
means that they will not have to accept the permissions requested.

The permissions requested are read devices Microsoft Intune devices, View your
basic profile, read and write group memberships, read all devices, and Maintain
access to data you have given it access to. As these permissions are “delegated”
type permissions, the user will also need to have the same permissions. If the
user does not have these permissions, they will not be able to use the module
even though the permissions have been accepted by an admin. This is by design
and used as an extra layer of security, preventing users that don’t have these
permissions from using the module to make changes.

Once the permissions have been accepted, it will create an Enterprise app in
your tenant called Microsoft Graph Powershell. In that Enterprise app, you can
verify the permissions granted to the app as well as adjust the app settings to
suit your organization’s needs.

![User Consent Prompt](https://github.com/portaldotjay/blob/blob/main/consentPrompt.png?raw=true)

## Using the commands

The command used is Get-Win11ReadinessStatus. The command ran alone will return
the results of all devices in Intune and their statuses. There are three
switches that can be used as well; status, exportCSV, and addToGroup. Using
these switches allows you to get devices that match a specific status, and
export the results to a CSV, and add the results to a group. To get examples and
details of the command, including statuses uses, run get-help
Get-Win11ReadinessStatus -Detailed in PowerShell.

There are a couple of Important things to note. The exportCSV switch must
contain the full path, including the name followed by .CSV. Using addToGroup
does not create a group, only modifies an existing group. You must create the
group and use it’s ID prior to trying to add devices to it. This will also
remove objects from the group that don’t match the status used. Please use care
when using this switch.

## Conclusion

We believe that Windows 11 will help keep your organization and your users safe
and secure while providing a more modern, yet familiar, user experience. We hope
that this helps you get greater insights into your environment as you plan your
organization’s journey to Windows 11. Please reach out to your account manager
if you’d like assistance getting this setup in your environment or if you’d like
guidance from Microsoft on your journey to Windows 11. We look forward to
working with you.
