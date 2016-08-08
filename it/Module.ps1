# This method returns the definitionid of a given definitionkey.
# If definitionkey is createTimersProcessPesterTests or exceptionAfterDurationProcessPesterTests and definition does not exist, the definition is deployed
	function GetDefinitionId ($definitionkey)
	{
		$currentPath = ((Get-Item -Path ".\" -Verbose).FullName);
		$result = Get-ActivitiWorkflowDefinition -key $definitionKey;
		if ((($result -eq $null) -or ($result.Count -eq 0)) -and ($definitionKey -eq 'createTimersProcessPesterTests'))
		{
			#Create the workflow definition
			$filename = Join-Path -path $currentPath -childpath "\createTimersProcessPesterTests.bpmn20.xml";	 
			$bytes = [System.IO.File]::ReadAllBytes($filename)
			$response = $biz_dfch_PS_Activiti_Client.ProcessEngine.CreateDeployment($filename, $bytes);
			if($response -ne $null -and $response.id -gt 0)
			{
				$result = Get-ActivitiWorkflowDefinition -key $definitionKey;
			}
		}
		
		if ((($result -eq $null) -or ($result.Count -eq 0)) -and ($definitionKey -eq 'exceptionAfterDurationProcessPesterTests'))
		{
			#Create the workflow definition
			$filename = Join-Path -path $currentPath -childpath "\exceptionAfterDurationProcessPesterTests.bpmn20.xml";	 
			$bytes = [System.IO.File]::ReadAllBytes($filename)
			$response = $biz_dfch_PS_Activiti_Client.ProcessEngine.CreateDeployment($filename, $bytes);
			if($response -ne $null -and $response.id -gt 0)
			{
				$result = Get-ActivitiWorkflowDefinition -key $definitionKey;
			}
		}
		if($result -ne $null -and $result.id -gt 0) 
		{
			return $result.id;
		}
		return 0;		
	}
		
		