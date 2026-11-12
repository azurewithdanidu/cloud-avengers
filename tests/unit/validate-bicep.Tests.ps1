#Requires -Module Pester
<#
.SYNOPSIS
    Unit tests for validate-bicep.ps1 — static analysis only (no Azure calls).
#>
Describe "validate-bicep.ps1" {
    BeforeAll {
        $script:ScriptPath = "$PSScriptRoot/../../skills/module-organization/scripts/validate-bicep.ps1"
        $script:Content    = Get-Content $script:ScriptPath -Raw -ErrorAction SilentlyContinue
    }

    Context "File exists" {
        It "should exist at the expected path" {
            $script:ScriptPath | Should -Exist
        }
    }

    Context "Syntax check" {
        It "should parse without errors" {
            $errors = @()
            $null = [System.Management.Automation.Language.Parser]::ParseFile(
                $script:ScriptPath, [ref]$null, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }

    Context "Core behaviours" {
        It "should call az bicep build" {
            $script:Content | Should -Match "bicep build"
        }

        It "should call az bicep restore" {
            $script:Content | Should -Match "bicep restore"
        }

        It "should recurse over .bicep files" {
            $script:Content | Should -Match "\.bicep"
        }

        Context 'Fail-closed what-if validation' {
            BeforeAll {
                $script:Pwsh = (Get-Process -Id $PID).Path
                $script:Root = Join-Path $TestDrive 'bicep'
                New-Item -ItemType Directory -Path (Join-Path $script:Root 'parameters/dev') -Force | Out-Null
                "targetScope = 'subscription'" | Set-Content (Join-Path $script:Root 'main.compute.bicep')
                "using '../../main.compute.bicep'" | Set-Content (Join-Path $script:Root 'parameters/dev/compute.bicepparam')
                $script:Runner = Join-Path $TestDrive 'runner.ps1'
                @(
                    'param($Validator, $Root, $Json, [int]$ExitCode = 0)'
                    'function az {'
                    '    if ($args[0] -eq "deployment") {'
                    '        $global:LASTEXITCODE = $ExitCode'
                    '        $Json'
                    '    } else { $global:LASTEXITCODE = 0 }'
                    '}'
                    '& $Validator -BicepRoot $Root -Environment dev -Location eastus'
                    'exit $LASTEXITCODE'
                ) | Set-Content $script:Runner
            }

            It 'accepts valid results and rejects failed or malformed results in both skill copies' {
                foreach ($skill in @('module-organization', 'parameter-management')) {
                    $validator = Join-Path $PSScriptRoot "../../skills/$skill/scripts/validate-bicep.ps1"
                    foreach ($json in @('{"properties":{"changes":[]}}', 'not-json', '{}', '{"properties":{"changes":[{}]}}', '{"properties":{"changes":[{"changeType":"Delete","resourceId":"/storageAccounts/test"}]}}')) {
                        & $script:Pwsh -NoProfile -File $script:Runner -Validator $validator -Root $script:Root -Json $json
                        if ($json -eq '{"properties":{"changes":[]}}') {
                            $LASTEXITCODE | Should -Be 0
                        } else {
                            $LASTEXITCODE | Should -Not -Be 0 -Because $json
                        }
                    }
                    & $script:Pwsh -NoProfile -File $script:Runner -Validator $validator -Root $script:Root -Json '{"properties":{"changes":[]}}' -ExitCode 1
                    $LASTEXITCODE | Should -Not -Be 0
                }
            }

            It 'rejects a group without parameters in both skill copies' {
                "targetScope = 'subscription'" | Set-Content (Join-Path $script:Root 'main.data.bicep')
                foreach ($skill in @('module-organization', 'parameter-management')) {
                    $validator = Join-Path $PSScriptRoot "../../skills/$skill/scripts/validate-bicep.ps1"
                    & $script:Pwsh -NoProfile -File $script:Runner -Validator $validator -Root $script:Root -Json '{"properties":{"changes":[]}}'
                    $LASTEXITCODE | Should -Not -Be 0
                }
            }
        }
    }
}
