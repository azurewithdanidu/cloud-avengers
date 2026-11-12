#Requires -Module Pester

Describe 'OIDC mutation safeguards' {
    BeforeAll {
        $script:ScriptPath = Join-Path $PSScriptRoot '../../skills/github-actions-oidc/scripts/setup-oidc.ps1'
        $script:Inputs = @{
            GitHubOrg = 'org'
            GitHubRepo = 'repo'
            Environment = 'dev'
            Subscription = 'subscription'
            ResourceGroup = 'resource-group'
        }
        function az { throw 'Unexpected Azure call' }
    }

    BeforeEach {
        Mock az { throw 'Unexpected Azure call' }
        Mock Read-Host { 'DECLINE' }
    }

    It 'makes no Azure calls, confirmation reads, or summary writes for WhatIf' {
        Mock Out-File { throw 'Unexpected summary write' }
        & $script:ScriptPath @script:Inputs -WhatIf
        Should -Invoke az -Times 0
        Should -Invoke Read-Host -Times 0
        Should -Invoke Out-File -Times 0
    }

    It 'denies mutation without explicit human confirmation' {
        { & $script:ScriptPath @script:Inputs } | Should -Throw '*confirmation*'
        Should -Invoke az -Times 0
    }

    It 'stops on failed app creation without creating a service principal' {
        Mock Read-Host { 'APPROVE' }
        Mock az { $global:LASTEXITCODE = 1 }
        { & $script:ScriptPath @script:Inputs } | Should -Throw '*App registration creation failed*'
        Should -Invoke az -Times 1 -Exactly
    }
}
