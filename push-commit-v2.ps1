function ReadInput() {
    # ==== usage example
    #$var = ReadInput -message "please enter value" -default "default value"
    # === No parameter is Mandatory
    param (
        [string]$message = "Values is",
        [string]$default = "",
        [boolean]$active = 1,
        [boolean]$view = 0

    )
    if ($active -eq $true) {  
        # if there is a default change massage style
        if (-not [string]::IsNullOrEmpty($default)) {
            [string]$message = "$message (default is [$default])"
        }
        # read host
        $result = Read-Host $message;
        # if input is empty read, reslut default value
        if ([string]::IsNullOrEmpty($result)) {
            $result = $default
        }
        # return value
        if ($view) {
            Write-Host "You Entered:$result"
        }
        return $result

    }else{
        if ($view) {
            Write-Host "You Entered:$default"
        }
        return $default
    }
}

Function Apause(){
    param (
        [string]$message="",
        [boolean]$active = $true
    )
    Write-Host $message
    if ($active) {
        Pause
    }
}

Function ConfirmDialog() {
    #=======usage Example
    #$dialog = ConfirmDialog -message "confirme operation?" -description 'confirme operation description' `
    #-default 0  -yes "yes option description" -no "no option descriptio"

    # if($dialog -eq 1){
        #yes logic
    #}else{
        #no logic
    #}
    # === -default yes is 1, -default no is 0
    # ==  no parameter is Mandatory

    param(
        [Parameter(Mandatory=$false)][string]$message,
        [Parameter(Mandatory=$false)][string]$description,
        [Parameter(Mandatory=$false)][int]$default,
        [Parameter(Mandatory=$false)][string]$yes,
        [Parameter(Mandatory=$false)][string]$no
    )

    [int]$defaultChoice1 = 0
    $message_description1 = 'Continue'
    $caption1 = 'Proceed?'
    $yesmsg = 'Confirm'
    $nomsg = 'reject'
    if ($default -eq 0 -or 1) {
        [int]$defaultChoice1 = !$default
    } 
    if ($description) {
        [string]$message_description1 = $description
    }    
    if ($message) {
        [string]$caption1 = $message
    } 

    if ($yes) {
        [string]$yesmsg = $yes
    }       
    if ($no) {
        [string]$nomsg = $no
    }       

    $yes1 = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $yesmsg
    $no1 = New-Object System.Management.Automation.Host.ChoiceDescription "&No", $nomsg
    $options1 = [System.Management.Automation.Host.ChoiceDescription[]]($yes1, $no1)
    $choiceRTN1 = $host.ui.PromptForChoice($caption1,$message_description1, $options1,$defaultChoice1)
    if ( $choiceRTN1 -ne 1 )
    {
        return 1;
    }
    else
    {
        return 0;
    }
    
}

Set-Location -LiteralPath "D:\Work\powershell\git powershell script\"

Write-Host "------------------ Current Status ------------------"
git status
Write-Host "------------------ End Current Status ------------------"

Write-Host "------------------ Branches ------------------"
git branch
Write-Host "------------------ End Branches ------------------"

$gitadd = ConfirmDialog -message "Add files?" -default 0
if($gitadd){
	Write-Host "------------------ Staging Files...------------------"
	git add *
	Write-Host "------------------ End Staging Files...------------------"

}
$gitcommit = ConfirmDialog -message "commit files?" -default 0
if($gitcommit){
	$commit = ReadInput -message 'Please enter commit message'
	Write-Host "------------------ Commiting... ------------------"
	git commit -m $commit
	Write-Host "------------------ End Commiting... ------------------"
}

Write-Host "------------------ Current Status ------------------"
git status
Write-Host "------------------ End Current Status ------------------"


# pushing files
$gitpush = ConfirmDialog -message "Push files to remote?" -default 0

if($gitpush){
	$gitpushdry = ConfirmDialog -message "Push dry run?" -default 1
	# DRY-RUN
	if($gitpushdry){
		Write-Host "------------------ pushing DRY-RUN... ------------------"
		git push --dry-run
		Write-Host "------------------ End pushing DRY-RUN... ------------------"
	}
	
	# Normal
	$gitpushnormal = ConfirmDialog -message "Push live run?" -default 0
	if($gitpushnormal){
		Write-Host "------------------ pushing... ------------------"
		git push
		Write-Host "------------------ End pushing... ------------------"
	}
}
Apause -message "-------------------------Finished"