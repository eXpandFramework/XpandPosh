[string[]]$global:pipelineTasksSet=@("ClearProjectDirectories","RemoveNugetImportTargets","RemoveProjectLicenseFile","RemoveProjectInvalidItems",
"UpdateProjectAutoGeneratedBindingRedirects","UpdateAppendTargetFrameworkToOutputPath","UpdateGeneratedAssemblyInfo","UpdateProjectTargetFramework",
"UpdateOutputPath","RemoveProjectReferences","UpdateAssemblyInfoVersion")
function Add-PipelineTasks {
    [CmdletBinding()]
    [CmdLetTag(("#Azure","AzureDevOps"))]
    param (
        [parameter(Mandatory,ValueFromPipeline)]
        [System.IO.FileInfo]$ProjectFile,
        [ValidateScript({$_ -in $global:pipelineTasksSet})]
        [parameter()]
        [ArgumentCompleter({
            [OutputType([System.Management.Automation.CompletionResult])]  # zero to many
            param(
                [string] $CommandName,
                [string] $ParameterName,
                [string] $WordToComplete,
                [System.Management.Automation.Language.CommandAst] $CommandAst,
                [System.Collections.IDictionary] $FakeBoundParameters
            )
            $global:pipelineTasksSet
        })]
        [string[]]$Task=$global:pipelineTasksSet,
        [ValidateSet("4.5.2","4.6.1","4.7.1","4.7.2","4.8")]
        [string]$TargetFramework="4.7.2",
        [string]$OutputPath,
        [version]$AssemblyInfoVersion
    )
    
    begin {
        $PSCmdlet|Write-PSCmdLetBegin
    }
    
    process {
        
        Invoke-Script{
            Push-Location $ProjectFile.DirectoryName
            Write-HostFormatted "Analyzing $($ProjectFile.BaseName)" -Section -ForegroundColor Yellow -Stream Verbose
            if ("ClearProjectDirectories" -in $global:pipelineTasksSet){
                $currentDir=(Get-Item $ProjectFile).Name
                Clear-ProjectDirectories 
            }
            
            if ("RemoveNugetImportTargets" -in $global:pipelineTasksSet){
                Remove-NugetImportsTargets $ProjectFile|Out-Null
            }
            
            
            if ("RemoveProjectLicenseFile" -in $global:pipelineTasksSet){
                Remove-ProjectLicenseFile -FilePath $ProjectFile.FullName|Out-Null    
            }
            
            if ("RemoveProjectInvalidItems" -in $global:pipelineTasksSet){
                Remove-ProjectInvalidItems $ProjectFile|Out-Null    
            }
    
            [xml]$csproj = Get-XmlContent $ProjectFile.FullName
            if ("UpdateProjectAutoGeneratedBindingRedirects" -in $global:pipelineTasksSet){
                Update-ProjectAutoGenerateBindingRedirects $csproj $false    
            }
            
            if ("UpdateAppendTargetFrameworkToOutputPath" -in $global:pipelineTasksSet){
                Update-AppendTargetFrameworkToOutputPath $csproj    
            }
            
            if ("UpdateGeneratedAssemblyInfo" -in $global:pipelineTasksSet){
                Update-GenerateAssemblyInfo  $csproj
            }
            
            if ("UpdateProjectTargetFramework" -in $global:pipelineTasksSet){
                Update-ProjectTargetFramework $TargetFramework $csproj
            }
            
            if ("UpdateOutputPath" -in $global:pipelineTasksSet -and $OutputPath){
                Update-OutputPath $csproj $ProjectFile.FullName $OutputPath
            }
            
            $csproj | Save-Xml $ProjectFile.FullName|Out-Null
    
            if ("RemoveProjectReferences" -in $global:pipelineTasksSet){
                Remove-ProjectReferences $ProjectFile.FullName -InvalidHintPath|Out-Null    
            }
            
            if ("UpdateAssemblyInfoVersion" -in $global:pipelineTasksSet){
                Update-AssemblyInfoVersion $AssemblyInfoVersion "$($ProjectFile.DirectoryName)\Properties\AssemblyInfo.cs"    
            }
            
            Pop-Location
        }

    }
    
    end {
        
    }
}