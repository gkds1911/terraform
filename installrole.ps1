<powershell>
    $admin = [adsi]("WinNT://./administrator, user")
    $admin.psbase.invoke("SetPassword", "${admin_password}")
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument
</powershell>