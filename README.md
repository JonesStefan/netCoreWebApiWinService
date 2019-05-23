netCoreWebApiWinService
below is taken from the MS docs: https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/windows-service?view=aspnetcore-2.2

// note that we use SCD in the project:
# Prerequisites
PowerShell 6.2+: https://github.com/PowerShell/PowerShell

# Setup
0. started a new webApi Project with the net core framework.
0.1 build the sulotion and skip to the step [#Publish The App]
1. we change the propertyGroup in Api.Csproj
	- we replace the propertygroup with:
	
-(FDD):

```xml
<PropertyGroup>
  <TargetFramework>netcoreapp2.2</TargetFramework>
  <RuntimeIdentifier>win7-x64</RuntimeIdentifier>
  <SelfContained>false</SelfContained>
  <IsTransformWebConfigDisabled>true</IsTransformWebConfigDisabled>
</PropertyGroup>
```

-(SCD)

```xml
<PropertyGroup>    
    <TargetFramework>netcoreapp2.2</TargetFramework>    
    <RuntimeIdentifier>win10-x64</RuntimeIdentifier>
    <IsTransformWebConfigDisabled>true</IsTransformWebConfigDisabled>    
</PropertyGroup>
```
	// it is possible to not include the RID (runtime inditifiers)

2. we add the package: Microsoft.AspNetCore.Hosting.WindowsServices
	// recomended to use the package manager
	- run cmd: Install-Package Microsoft.AspNetCore.Hosting.WindowsServices

	-- if we want logging we add: Microsoft.Extensions.Logging.EventLog
		cmd: Install-Package Microsoft.Extensions.Logging.EventLog
	
# Code

now we are ready to do the code changes in program.Main we make the requried changes to have the 

```csharp
using System.Diagnostics;
using System.IO;
using System.Linq;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Hosting.WindowsServices;
using Microsoft.Extensions.Logging;
{....}

public class Program
{
    public static void Main(string[] args)
    {
        var isService = !(Debugger.IsAttached || args.Contains("--console"));
        
        if (isService)
        {
            var pathToExe = Process.GetCurrentProcess().MainModule.FileName;
            var pathToContentRoot = Path.GetDirectoryName(pathToExe);
            Directory.SetCurrentDirectory(pathToContentRoot);
        }

        var builder = CreateWebHostBuilder(
            args.Where(arg => arg != "--console").ToArray());

        var host = builder.Build();

        if (isService)
        {
            // To run the app without the CustomWebHostService change the
            // next line to host.RunAsService();
            host.RunAsService();
        }
        else
        {
            host.Run();
        }
    }

    public static IWebHostBuilder CreateWebHostBuilder(string[] args) =>
        WebHost.CreateDefaultBuilder(args)
            .ConfigureLogging((hostingContext, logging) =>
            {
                logging.AddEventLog();
            })
            .ConfigureAppConfiguration((context, config) =>
            {
                // Configure the app here.
            })
            .UseStartup<Startup>();
}
```

# Publish the app

in the example from MS we use a folder (c:/svc) to publish the app in
	- create a folder for the
	- in cmdPromt navigate to the project folder.
	- publish the app with cmd:
	-- FDD
	```
	dotnet publish --configuration Release --output c:\svc
	```
	-- SCD
	```
	dotnet publish --configuration Release --runtime win10-x64 --output c:\svc
	```
This builds the project to the folder and is now ready to be used

# Creating a user account (powershell)
-Create User
Open powerShell 6.2
run cmd: ```New-LocalUser -Name ApiServiceUser```
and provide a strong password

- Grant user access to publish folder
cmd: ```icacls "c:\svc" /grant "ApiServiceUser:(OI)(CI)WRX" /t```

# Create the Service
In /Script, we have RegisterService.ps1 Script that enables us to register the service on the machine.
- open powershell
- navigate to {sourceFolder}/script
- run cmd: ```.\RegisterService.ps1```
	- provide the needed parameters
		-Name {NAME}  --> (the serviceName: Api)
		-DisplayName "{DISPLAY NAME}" 
		-Description "{DESCRIPTION}" 
		-Exe "{PATH TO EXE}\\{ASSEMBLY NAME}.exe" 
		-User {DOMAIN\USER}

- run cmd: ```Start-Service -Name Api```
// if we get an error make sure that the user account (ApiServiceUser) has 'logon as a service'.

# check if the service is working
open a browser on the computer and navigate to: http://localhost:5000/api/values

ALL DONE - HAPPY HACKIGN!
