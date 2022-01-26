param($Action, $Object);

function selectCommand {
    param($commandName);
    if ($null -eq $commandName) {
        Write-Output "`nPlease specify either the name or ID of an odd command.`n`nRun ``oc ls`` to list all odd commands.`n";
        Exit;
    }
    try {
        $commandIndex = [int] $commandName;
        if ($commandIndex -gt 0 -and $config.commands.Length -ge $commandIndex) {
            return $config.commands[$commandIndex - 1];
        }
    }
    catch {
        foreach ($command in $config.commands) {
            if ($command.name -eq $commandName) {
                return $command;
            }
        }
    }
    Write-Output "`nCould not find '$commandName'.`n";
    Exit;
}

function list {
    if ($null -eq $config.commands -or $config.commands.Length -eq 0) {
        Write-Output "`nNo odd commands yet.`n";
    }
    else {
        $config.commands | Format-Table `
            @{Label="Index"; Expression={$config.commands.IndexOf($_) + 1;}; Align="center"}, `
            @{Label="Name"; Expression={$_.name}}, `
            @{Label="Description"; Expression={$_.description}} `
        ;
    }
}

function peek {
    param($command);
    Write-Output ("`n" + $command.name + ' - ' + $command.description + "`n`n");
    Write-Output ($command.commands.length -eq 1 ? "Command:`n" : "Commands:`n");
    foreach ($subcommand in $command.commands) {
        Write-Output $subcommand;
    }
    Write-Output '';
}

function run {
    param($command);
    Write-Output ("`n" + $command.name + ' - ' + $command.description + "`n");
    Start-Sleep -Seconds 2;
    foreach ($subcommand in $command.commands) {
        Invoke-Expression $subcommand;
    }
}

function add {
    do {
        $name = (Read-Host "Name").Trim();
        if ($name.length -eq 0) {
            Write-Host "Name may not be empty." -ForegroundColor 'Red';
        }
        elseif ($name.indexof(' ') -ne -1) {
            Write-Host "Name may not contain spaces." -ForegroundColor 'Red';
        }
        elseif (-not (isNameUnique $name)) {
            Write-Host "Name must be unique." -ForegroundColor 'Red';
        }
    }
    while ($name.length -eq 0 -or $name.indexof(' ') -ne -1 -or -not (isNameUnique $name));

    do {
        $description = (Read-Host "Description").Trim();
        if ($description.length -eq 0) {
            Write-Host "Description may not be empty." -ForegroundColor 'Red';
        }
    }
    while ($description.length -eq 0);

    Write-Output "`nYou may enter multiple sub-commands that will be part of this odd command.`nTo finish, enter a blank line.`n";
    $commands = New-Object -TypeName "System.Collections.ArrayList";
    do {
        $newCommand = (Read-Host "Command").Trim();
        if ($newCommand.length -gt 0) {
            $null = $commands.Add($newCommand);
        }
    }
    while ($newCommand.length -gt 0);

    $config.commands += @{name = $name; description = $description; commands = $commands};
    ConvertTo-Json $config -Depth 10 | Set-Content $configFilePath;
}

function isNameUnique {
    param($name);
    foreach ($command in $config.commands) {
        if ($command.name -eq $name) {
            return $false;
        }
    }
    return $true;
}

function remove {
    param($command);
    $config.commands = $config.commands.where({ $_.name -ne $command.name });
    ConvertTo-Json $config -Depth 10 | Set-Content $configFilePath;
}

function help {
    Write-Output (Get-Content "$PSScriptRoot\help.txt").Replace('{{ script root }}', $PSScriptRoot);
}

$configFilePath = "$PSScriptRoot\odd-commands.json";
if (-not (Test-Path -Path $configFilePath -PathType Leaf)) {
    $null = New-Item -ItemType File -Path $configFilePath -Value '{"commands":[]}' -Force;
}
$config = Get-Content $configFilePath | ConvertFrom-Json;

switch ($Action) {
    "ls" {
        list;
        Break;
    }
    "peek" {
        peek (selectCommand $Object);
        Break;
    }
    "run" {
        run (selectCommand $Object);
        Break;
    }
    "add" {
        add;
        Break;
    }
    "rm" {
        remove (selectCommand $Object);
        Break;
    }
    default {
        help;
        Break;
    }
}
