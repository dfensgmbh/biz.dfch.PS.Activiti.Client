$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

function Stop-Pester($message = "EMERGENCY: Script cannot continue.")
{
	$msg = $message;
	$e = New-CustomErrorRecord -msg $msg -cat OperationStopped -o $msg;
	$PSCmdlet.ThrowTerminatingError($e);
}

Describe -Tags "Activiti.Tests" "Activiti.Tests" {

	Mock Export-ModuleMember { return $null; }
	
	. "$here\$sut"
	
	$WaitTimeoutSeconds = 30;
	
	# uncomment this line to ask for credentials at run time
	# $cred = Get-Credential;
	$settings =Get-ApcManagementCredential -Name biz.dfch.PS.Activiti.Client.Setting;
	$secpasswd = ConvertTo-SecureString $settings.Password -AsPlainText -Force

	$cred = New-Object System.Management.Automation.PSCredential ($set.Username, $secpasswd);
		
	Context "#CLOUDTCL-1895-ActivitiBaseTests" {

		It "Activiti-ModuleListSucceeds" -Test {
		
			# Arrange
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			
			# Act
			$result = Get-Module -ListAvailable | sls $moduleName
			
			# Assert
			$result | Should Not Be $null;
		}

		It "Activiti-ModuleLoadSucceeds" -Test {
		
			# Arrange
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			Remove-Module $moduleName -ErrorAction:SilentlyContinue;
			Import-Module $moduleName;
			
			# Act
			# N/A
			
			# Assert
			$biz_dfch_PS_Activiti_Client.ProcessEngine | Should Be $null;
		}

		It "Activiti-VersionCheckSucceeds" -Test {
		
			# Arrange
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			Remove-Module $moduleName -ErrorAction:SilentlyContinue;
			Import-Module $moduleName;
			[Version] $ver = '1.0.0';
			
			# Act
			$m = Get-Module biz.dfch.PS.Activiti.Client
			
			# Assert
			$ver -le $m.Version | Should Be $true;
		}
	}
	
	Context "#CLOUDTCL-1896-ActivitiLogin" {

		It "Activiti-LoginSucceeds" -Test {
		
			# Arrange
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			Remove-Module $moduleName -ErrorAction:SilentlyContinue;
			Import-Module $moduleName;
			
			# Act
			$svc = Enter-Activiti -Credential $cred;
			
			# Assert
			$svc | Should Not Be $null;
			$svc.ApplicationName | Should Be $biz_dfch_PS_Activiti_Client.ApplicationName;
			$svc | Should Be $biz_dfch_PS_Activiti_Client.ProcessEngine;
		}

		It "Activiti-LoginWithEmptyCredentialThrowsException" -Test {
		
			# Arrange
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			Remove-Module $moduleName -ErrorAction:SilentlyContinue;
			Import-Module $moduleName;
			
			try
			{
				# Act
				$svc = Enter-Activiti;
				'Statement returned without exception' | Should Be 'An exception should have been thrown';
			}
			catch
			{
				# Assert
				$result = $error[0].Exception.Message -match 'Login.+FAILED';
				$result | Should Be $true
				$svc | Should Be $null;
			}
		}

		It "Activiti-LoginWithInvalidCredentialThrowsException" -Test {
		
			# Arrange
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			Remove-Module $moduleName -ErrorAction:SilentlyContinue;
			Import-Module $moduleName;
			
			$username = 'invalid-username';
			$password = 'invalid-password' | ConvertTo-SecureString -asPlainText -Force
			$invalidCredential = New-Object System.Management.Automation.PSCredential($username,$password)
			
			try
			{
				# Act
				$svc = Enter-Activiti -cred $invalidCredential;
				'Statement returned without exception' | Should Be 'An exception should have been thrown';
			}
			catch
			{
				# Assert
				$result = $error[0].Exception.Message -match 'Login.+FAILED';
				$result | Should Be $true
				$svc | Should Be $null;
			}
		}

		It "Activiti-LoginWithApplicationNameSucceeds" -Test {
		
			# Arrange
			$applicationName = 'PesterTest-{0}' -f [guid]::NewGuid().Guid;
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			Remove-Module $moduleName -ErrorAction:SilentlyContinue;
			Import-Module $moduleName;
			
			# Act
			$svc = Enter-Activiti -ApplicationName $applicationName -Credential $cred;
			
			# Assert
			$svc | Should Not Be $null;
			$svc.ApplicationName | Should Be $applicationName;
		}

		It "Activiti-LoginWithApplicationNamePropertySucceeds" -Test {
		
			# Arrange
			$applicationName = 'PesterTest-{0}' -f [guid]::NewGuid().Guid;
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			Remove-Module $moduleName -ErrorAction:SilentlyContinue;
			Import-Module $moduleName;
			$biz_dfch_PS_Activiti_Client.ApplicationName = $applicationName;
			
			# Act
			$svc = Enter-Activiti -Credential $cred;
			
			# Assert
			$svc | Should Not Be $null;
			$svc.ApplicationName | Should Be $applicationName;
		}
	}

	Context "#CLOUDTCL-1897-ActivitiWorkflowDefinition" {
	
		BeforeEach {
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			Remove-Module $moduleName -ErrorAction:SilentlyContinue;
			Import-Module $moduleName;
			$svc = Enter-Activiti -Credential $cred;
		}
		
		It "GetWorkflowDefinition-ReturnsList" -Test {
		
			# Act
			$wfds = Get-ActivitiWorkflowDefinition;
			
			# Assert
			$wfds -is [Array] | Should Be $true;
			$wfds.Count -gt 0 | Should Be $true;
		}

		
			 
		It "GetWorkflowDefinition-WithNullProcessEngineThrowsException" -Test {
		
			# Arrange
			$error.Clear();
			
			try
			{
				# Act
				$wfds = Get-ActivitiWorkflowDefinition -ProcessEngine $null;
				'Statement returned without exception' | Should Be 'An exception should have been thrown';
			}
			catch
			{				
				# Assert
				$_ | Should Not Be $null;
				# DFTODO - assert exact argument exception
			}
		}

		It "GetWorkflowDefinition-ByKeySucceeds" -Test {
			
			# Arrange
			$wfd = Get-ActivitiWorkflowDefinition | Select -First 1;
			$wfd | Should Not Be $null;
			$wfd.key | Should Not Be $null;

			$key = $wfd.key;

			# Act
			$wfd = Get-ActivitiWorkflowDefinition -Key $key;
			
			# Assert
			$wfd | Should Not Be $null;
			$wfd.key | Should Be $key;
		}

		It "GetWorkflowDefinition-ByIdSucceeds" -Test {
			# Arrange
			$wfd = Get-ActivitiWorkflowDefinition | Select -First 1;
			$wfd | Should Not Be $null;
			$wfd.id | Should Not Be $null;

			$id = $wfd.id;
			
			# Act
			$wfd = Get-ActivitiWorkflowDefinition -Id $id;
			
			# Assert
			$wfd | Should Not Be $null;
			$wfd.id | Should Be $id;
		}

		It "GetWorkflowDefinition-UrlRewritingSucceeds" -Test {

			# Arrange

			# Act
			$wfd = Get-ActivitiWorkflowDefinition | Select -First 1;
			$wfd | Should Not Be $null;
			$wfd.url | Should Not Be $null;
			
			# Assert
			$wfd.url.StartsWith($biz_dfch_PS_Activiti_Client.ServerUri.AbsoluteUri) | Should Be $true;
		}
	}
	
	
	Context "#CLOUDTCL-1898-ActivitiWorkflowstatus"{
	
		BeforeEach {
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			Remove-Module $moduleName -ErrorAction:SilentlyContinue;
			Import-Module $moduleName;
			$svc = Enter-Activiti -Credential $cred;
		}
		
		It "CreateAndGet-WorkflowInstance-Succeeds" -Test {
			# Arrange
			$defid = "UserTaskToDone:1:1510";
			$vars = @{};
			
			# Act
			$new = Start-ActivitiWorkflowInstance -id $defid -params $vars -svc $svc;
			$result = Get-ActivitiWorkflowInstance -id $new.id -svc $svc
			
			# Assert
			$result | Should Not Be $null;
			0 -lt $result.id | Should Be $true;
			$result.id | Should Be $new.id;
			$result.suspended | Should Be 'False';
			$result.ended | Should Be 'False';
			$result.completed | Should Be 'False';
		}
		
		It "Get-WorkflowInstanceOfNonExistingWorkflow-Fails" -Test {
			# Arrange
						
			# Act
			$result = Get-ActivitiWorkflowInstance -id 0 -svc $svc
			
			# Assert
			$result | Should Be $null;
			
		}
		
		It "CreateAndGetCompleted-WorkflowInstance-Succeeds" -Test {
			# Arrange
			$defid = "createTimersProcess:1:36";
			$vars = @{"duration"="short"; "throwException"="false"};
			
			
			# Act
			$new = Start-ActivitiWorkflowInstance -id $defid -params $vars -svc $svc;
			
			$result1 = Get-ActivitiWorkflowInstance -id $new.id -svc $svc
			Start-Sleep $WaitTimeoutSeconds;
			$result2 = Get-ActivitiWorkflowInstance -id $new.id -svc $svc
			
			# Assert result1
			$result1 | Should Not Be $null;
			0 -lt $result1.id | Should Be $true;
			$result1.id | Should Be $new.id;
			$result1.suspended | Should Be 'False';
			$result1.ended | Should Be 'False';
			$result1.completed | Should Be 'False';
			
			# Assert result2
			$result2 | Should Not Be $null;
			0 -lt $result2.id | Should Be $true;
			$result2.id | Should Be $new.id;
			$result2.suspended | Should Be 'False';
			$result2.ended | Should Be 'True';
			$result2.completed | Should Be 'True';
			
		}		
	}
	
	Context "#CLOUDTCL-1899-ActivitiCancelWorkflow"{
	
		BeforeEach {
			$moduleName = 'biz.dfch.PS.Activiti.Client';
			Remove-Module $moduleName -ErrorAction:SilentlyContinue;
			Import-Module $moduleName;
			$svc = Enter-Activiti -Credential $cred;
		}
		
		It "CancelInvokedWorkflowInstance-Succeeds" -Test {
			# Arrange
			$defid = "createTimersProcess:1:36";
			$vars = @{"duration"="long"; "throwException"="false"};
			
			# Act
			$new = Start-ActivitiWorkflowInstance -id $defid -params $vars -svc $svc;
			Stop-ActivitiWorkflowInstance -id $new.id -svc $svc;
			$result = Get-ActivitiWorkflowInstance -id $new.id -svc $svc;

			# Assert
			$result | Should Not Be $null;
			$result.deleteReason | Should Be 'ACTIVITI_DELETED';
			$result.id | Should Be $new.id;
			$result.suspended | Should Be 'False';
			$result.ended | Should Be 'True';
			$result.completed | Should Be 'True';
		}
		
			
		It "CancelSuspendedWorkflowInstance-Succeeds" -Test {
			# Arrange
			$defid = "createTimersProcess:1:36";
			$vars = @{"duration"="long"; "throwException"="false"};
			
			# Act
			$new = Start-ActivitiWorkflowInstance -id $defid -params $vars -svc $svc;
			
			# TODO: Suspend workflow here
			
			$ret = Stop-ActivitiWorkflowInstance -id $new.id -svc $svc;
			$result = Get-ActivitiWorkflowInstance -id $new.id -svc $svc;

			# Assert
			$result | Should Not Be $null;
			$ret | Should Be $true;
			$result.deleteReason | Should Be 'ACTIVITI_DELETED';
			$result.id | Should Be $new.id;
			$result.suspended | Should Be 'True';
			$result.ended | Should Be 'True';
			$result.completed | Should Be 'True';
		}
		
		It "CancelCompletedWorkflowInstance-Fails" -Test {
			# Arrange
			$defid = "createTimersProcess:1:36";
			$vars = @{"duration"="short"; "throwException"="false"};
			
			# Act
			$new = Start-ActivitiWorkflowInstance -id $defid -params $vars -svc $svc;
			Start-Sleep $WaitTimeoutSeconds;
			$ret = Stop-ActivitiWorkflowInstance -id $new.id -svc $svc;
			$result = Get-ActivitiWorkflowInstance -id $new.id -svc $svc;

			
			# Assert
			$result | Should Not Be $null;
			$ret | Should Be $false;
			$result.deleteReason | Should Not Be 'ACTIVITI_DELETED';
			$result.id | Should Be $new.id;
			$result.suspended | Should Be 'False';
			$result.ended | Should Be 'True';
			$result.completed | Should Be 'True';
		}
		
		It "CancelFailedWorkflowInstance-Fails" -Test {
			# Arrange
			$defid = "createTimersProcess:1:36";
			$vars = @{"duration"="short"; "throwException"="true"};
					
			# Act
			$new = Start-ActivitiWorkflowInstance -id $defid -params $vars -svc $svc;
			# workflow should end with an exception after 10 seconds.
			Start-Sleep $WaitTimeoutSeconds;
			$ret = Stop-ActivitiWorkflowInstance -id $new.id -svc $svc;
			# Failed workflow can be cancelled
			$ret | Should Be $true;
			$result = Get-ActivitiWorkflowInstance -id $new.id -svc $svc;

			# Assert
			$result | Should Not Be $null;
			$result.deleteReason | Should Be 'ACTIVITI_DELETED';
			$result.id | Should Be $new.id;
			$result.suspended | Should Be 'False';
			$result.ended | Should Be 'True';
			$result.completed | Should Be 'True';
		}
		
		It "CancelEndedWorkflowInstance-Fails" -Test {
			# Arrange
			$defid = "createTimersProcess:1:36";
			$vars = @{"duration"="short"; "throwException"="false"};
					
			# Act
			$new = Start-ActivitiWorkflowInstance -id $defid -params $vars -svc $svc;
			# workflow should end with an exception after 10 seconds.
			Start-Sleep $WaitTimeoutSeconds;
			$ret = Stop-ActivitiWorkflowInstance -id $new.id -svc $svc;
			$ret | Should Be $false;
			$result = Get-ActivitiWorkflowInstance -id $new.id -svc $svc;
			
			# Assert
			$result | Should Not Be $null;
			$result.deleteReason | Should Be $null;
			$result.id | Should Be $new.id;
			$result.suspended | Should Be 'False';
			$result.ended | Should Be 'True';
			$result.completed | Should Be 'True';
		}
		
		It "CancelNonExistingWorkflowInstance-Fails" -Test {
			# Arrange
			
			# Act			
			$result = Stop-ActivitiWorkflowInstance -id 0 -svc $svc;
			
			# Assert
			$result | Should Be $false;
		}
		
	}
}

#
# Copyright 2015 d-fens GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# SIG # Begin signature block
# MIIXDwYJKoZIhvcNAQcCoIIXADCCFvwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUN5eauk5yu4ZR/Fd8TPR1RJ1I
# gfGgghHCMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BCkwggMRoAMCAQICCwQAAAAAATGJxjfoMA0GCSqGSIb3DQEBCwUAMEwxIDAeBgNV
# BAsTF0dsb2JhbFNpZ24gUm9vdCBDQSAtIFIzMRMwEQYDVQQKEwpHbG9iYWxTaWdu
# MRMwEQYDVQQDEwpHbG9iYWxTaWduMB4XDTExMDgwMjEwMDAwMFoXDTE5MDgwMjEw
# MDAwMFowWjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# MDAuBgNVBAMTJ0dsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBTSEEyNTYgLSBH
# MjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKPv0Z8p6djTgnY8YqDS
# SdYWHvHP8NC6SEMDLacd8gE0SaQQ6WIT9BP0FoO11VdCSIYrlViH6igEdMtyEQ9h
# JuH6HGEVxyibTQuCDyYrkDqW7aTQaymc9WGI5qRXb+70cNCNF97mZnZfdB5eDFM4
# XZD03zAtGxPReZhUGks4BPQHxCMD05LL94BdqpxWBkQtQUxItC3sNZKaxpXX9c6Q
# MeJ2s2G48XVXQqw7zivIkEnotybPuwyJy9DDo2qhydXjnFMrVyb+Vpp2/WFGomDs
# KUZH8s3ggmLGBFrn7U5AXEgGfZ1f53TJnoRlDVve3NMkHLQUEeurv8QfpLqZ0BdY
# Nc0CAwEAAaOB/TCB+jAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIB
# ADAdBgNVHQ4EFgQUGUq4WuRNMaUU5V7sL6Mc+oCMMmswRwYDVR0gBEAwPjA8BgRV
# HSAAMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3Jl
# cG9zaXRvcnkvMDYGA1UdHwQvMC0wK6ApoCeGJWh0dHA6Ly9jcmwuZ2xvYmFsc2ln
# bi5uZXQvcm9vdC1yMy5jcmwwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHwYDVR0jBBgw
# FoAUj/BLf6guRSSuTVD6Y5qL3uLdG7wwDQYJKoZIhvcNAQELBQADggEBAHmwaTTi
# BYf2/tRgLC+GeTQD4LEHkwyEXPnk3GzPbrXsCly6C9BoMS4/ZL0Pgmtmd4F/ximl
# F9jwiU2DJBH2bv6d4UgKKKDieySApOzCmgDXsG1szYjVFXjPE/mIpXNNwTYr3MvO
# 23580ovvL72zT006rbtibiiTxAzL2ebK4BEClAOwvT+UKFaQHlPCJ9XJPM0aYx6C
# WRW2QMqngarDVa8z0bV16AnqRwhIIvtdG/Mseml+xddaXlYzPK1X6JMlQsPSXnE7
# ShxU7alVrCgFx8RsXdw8k/ZpPIJRzhoVPV4Bc/9Aouq0rtOO+u5dbEfHQfXUVlfy
# GDcy1tTMS/Zx4HYwggSfMIIDh6ADAgECAhIRIQaggdM/2HrlgkzBa1IJTgMwDQYJ
# KoZIhvcNAQEFBQAwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzIw
# HhcNMTUwMjAzMDAwMDAwWhcNMjYwMzAzMDAwMDAwWjBgMQswCQYDVQQGEwJTRzEf
# MB0GA1UEChMWR01PIEdsb2JhbFNpZ24gUHRlIEx0ZDEwMC4GA1UEAxMnR2xvYmFs
# U2lnbiBUU0EgZm9yIE1TIEF1dGhlbnRpY29kZSAtIEcyMIIBIjANBgkqhkiG9w0B
# AQEFAAOCAQ8AMIIBCgKCAQEAsBeuotO2BDBWHlgPse1VpNZUy9j2czrsXV6rJf02
# pfqEw2FAxUa1WVI7QqIuXxNiEKlb5nPWkiWxfSPjBrOHOg5D8NcAiVOiETFSKG5d
# QHI88gl3p0mSl9RskKB2p/243LOd8gdgLE9YmABr0xVU4Prd/4AsXximmP/Uq+yh
# RVmyLm9iXeDZGayLV5yoJivZF6UQ0kcIGnAsM4t/aIAqtaFda92NAgIpA6p8N7u7
# KU49U5OzpvqP0liTFUy5LauAo6Ml+6/3CGSwekQPXBDXX2E3qk5r09JTJZ2Cc/os
# +XKwqRk5KlD6qdA8OsroW+/1X1H0+QrZlzXeaoXmIwRCrwIDAQABo4IBXzCCAVsw
# DgYDVR0PAQH/BAQDAgeAMEwGA1UdIARFMEMwQQYJKwYBBAGgMgEeMDQwMgYIKwYB
# BQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMAkG
# A1UdEwQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwQgYDVR0fBDswOTA3oDWg
# M4YxaHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9ncy9nc3RpbWVzdGFtcGluZ2cy
# LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly9zZWN1cmUu
# Z2xvYmFsc2lnbi5jb20vY2FjZXJ0L2dzdGltZXN0YW1waW5nZzIuY3J0MB0GA1Ud
# DgQWBBTUooRKOFoYf7pPMFC9ndV6h9YJ9zAfBgNVHSMEGDAWgBRG2D7/3OO+/4Pm
# 9IWbsN1q1hSpwTANBgkqhkiG9w0BAQUFAAOCAQEAgDLcB40coJydPCroPSGLWaFN
# fsxEzgO+fqq8xOZ7c7tL8YjakE51Nyg4Y7nXKw9UqVbOdzmXMHPNm9nZBUUcjaS4
# A11P2RwumODpiObs1wV+Vip79xZbo62PlyUShBuyXGNKCtLvEFRHgoQ1aSicDOQf
# FBYk+nXcdHJuTsrjakOvz302SNG96QaRLC+myHH9z73YnSGY/K/b3iKMr6fzd++d
# 3KNwS0Qa8HiFHvKljDm13IgcN+2tFPUHCya9vm0CXrG4sFhshToN9v9aJwzF3lPn
# VDxWTMlOTDD28lz7GozCgr6tWZH2G01Ve89bAdz9etNvI1wyR5sB88FRFEaKmzCC
# BNYwggO+oAMCAQICEhEhDRayW4wRltP+V8mGEea62TANBgkqhkiG9w0BAQsFADBa
# MQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEwMC4GA1UE
# AxMnR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBDQSAtIFNIQTI1NiAtIEcyMB4XDTE1
# MDUwNDE2NDMyMVoXDTE4MDUwNDE2NDMyMVowVTELMAkGA1UEBhMCQ0gxDDAKBgNV
# BAgTA1p1ZzEMMAoGA1UEBxMDWnVnMRQwEgYDVQQKEwtkLWZlbnMgR21iSDEUMBIG
# A1UEAxMLZC1mZW5zIEdtYkgwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDNPSzSNPylU9jFM78Q/GjzB7N+VNqikf/use7p8mpnBZ4cf5b4qV3rqQd62rJH
# RlAsxgouCSNQrl8xxfg6/t/I02kPvrzsR4xnDgMiVCqVRAeQsWebafWdTvWmONBS
# lxJejPP8TSgXMKFaDa+2HleTycTBYSoErAZSWpQ0NqF9zBadjsJRVatQuPkTDrwL
# eWibiyOipK9fcNoQpl5ll5H9EG668YJR3fqX9o0TQTkOmxXIL3IJ0UxdpyDpLEkt
# tBG6Y5wAdpF2dQX2phrfFNVY54JOGtuBkNGMSiLFzTkBA1fOlA6ICMYjB8xIFxVv
# rN1tYojCrqYkKMOjwWQz5X8zAgMBAAGjggGZMIIBlTAOBgNVHQ8BAf8EBAMCB4Aw
# TAYDVR0gBEUwQzBBBgkrBgEEAaAyATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93
# d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADATBgNVHSUE
# DDAKBggrBgEFBQcDAzBCBgNVHR8EOzA5MDegNaAzhjFodHRwOi8vY3JsLmdsb2Jh
# bHNpZ24uY29tL2dzL2dzY29kZXNpZ25zaGEyZzIuY3JsMIGQBggrBgEFBQcBAQSB
# gzCBgDBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNvbS9j
# YWNlcnQvZ3Njb2Rlc2lnbnNoYTJnMi5jcnQwOAYIKwYBBQUHMAGGLGh0dHA6Ly9v
# Y3NwMi5nbG9iYWxzaWduLmNvbS9nc2NvZGVzaWduc2hhMmcyMB0GA1UdDgQWBBTN
# GDddiIYZy9p3Z84iSIMd27rtUDAfBgNVHSMEGDAWgBQZSrha5E0xpRTlXuwvoxz6
# gIwyazANBgkqhkiG9w0BAQsFAAOCAQEAAApsOzSX1alF00fTeijB/aIthO3UB0ks
# 1Gg3xoKQC1iEQmFG/qlFLiufs52kRPN7L0a7ClNH3iQpaH5IEaUENT9cNEXdKTBG
# 8OrJS8lrDJXImgNEgtSwz0B40h7bM2Z+0DvXDvpmfyM2NwHF/nNVj7NzmczrLRqN
# 9de3tV0pgRqnIYordVcmb24CZl3bzpwzbQQy14Iz+P5Z2cnw+QaYzAuweTZxEUcJ
# bFwpM49c1LMPFJTuOKkUgY90JJ3gVTpyQxfkc7DNBnx74PlRzjFmeGC/hxQt0hvo
# eaAiBdjo/1uuCTToigVnyRH+c0T2AezTeoFb7ne3I538hWeTdU5q9jGCBLcwggSz
# AgEBMHAwWjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# MDAuBgNVBAMTJ0dsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBTSEEyNTYgLSBH
# MgISESENFrJbjBGW0/5XyYYR5rrZMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTwyOXjv1bLTfyq
# 4NSeCawC6kKXEjANBgkqhkiG9w0BAQEFAASCAQBMFw+9MuCNWNVPShGPe0BmDNAu
# benfJIgwvQj3ifBKhPyF33PfS3R6ITzeIPJz/MeDwkmVreqVlDpYwuN5wwcy8vrc
# BU0KrVTYQ7TCAMiyYvGo5yjaueJe5ewa9jjK5tY6qih23blT7NUPd09yqp8P+cGL
# D63jnaBXd+smDDFSnnYEsD/01DpbezlaLvzKkPpg78nIBYnDMP6N7eGQ7OQ9oxwk
# a8YM49/GZ8q3hdKXSI4VfHa+UDsGaf4yNCgQI3nNDi+9Nue04Mi99G8g5BEWUV67
# 18Y053gvnLj9xpAEhM+uqwvfsKN+j31hf1hpBtAXKMgWf9SRrBYxisLAOAFDoYIC
# ojCCAp4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAX
# BgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGlt
# ZXN0YW1waW5nIENBIC0gRzICEhEhBqCB0z/YeuWCTMFrUglOAzAJBgUrDgMCGgUA
# oIH9MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE1
# MTIwMjA0MzM0N1owIwYJKoZIhvcNAQkEMRYEFDwiHOKdCSD1D3/sc3VfCwi0phTy
# MIGdBgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUs2MItNTN7U/PvWa5Vfrjv7Es
# KeYwbDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYt
# c2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh
# BqCB0z/YeuWCTMFrUglOAzANBgkqhkiG9w0BAQEFAASCAQA1VaqbmCld444qCfqz
# biIYWXwu9/j80vk5YZYBUp1sm63MUoJgwSg8MTqXe7nvxlb7weaS22oPC5oAD0Wy
# HL0pHKkgQ0x4uaPHyVjx4vONmqS54ORHa776QekRiQKt84s9NvSwYx9jMtS5I/F4
# KMp/6PHhs7wZEW532GcvBF/sWZbf5Y0wIqSA2QAGCxpEUz5YC4xO85ebAYbgkANv
# HWNH80D89Shr2Wa/ceXP91bKSuQ4ranhuaux5MjNjpxEmjKK4Ia7ShRI+wmVy4e4
# lSUP9idth9ydc4nXDKEtcqJP1UkP7RjRAsi6963mL+D4OSVAx4TAhOwcyu8yFRNB
# BL7b
# SIG # End signature block
