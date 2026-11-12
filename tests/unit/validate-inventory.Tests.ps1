#Requires -Module Pester

Describe 'Inventory validation contract' {
    BeforeAll {
        $script:Validator = Join-Path $PSScriptRoot '../../skills/aws-inventory-scan/scripts/validate-inventory.ps1'
        $script:Pwsh = (Get-Process -Id $PID).Path
        $script:ValidJson = '{"discovery_timestamp":"2026-11-13T00:00:00Z","aws_account_id":"123456789012","aws_region":"us-east-1","services":{"lambda":{"service_type":"AWS::Lambda::Function","count":1,"resources":[{"name":"handler","arn":"arn:aws:lambda:us-east-1:123456789012:function:handler","region":"us-east-1"}]}}}'
    }

    It 'accepts a complete typed inventory' {
        $path = Join-Path $TestDrive 'valid.json'
        $script:ValidJson | Set-Content $path
        & $script:Pwsh -NoProfile -File $script:Validator -InventoryPath $path
        $LASTEXITCODE | Should -Be 0
    }

    It 'rejects count drift, invalid types, and malformed resources' {
        foreach ($case in @('count-drift', 'fraction', 'string-count', 'scalar-resource', 'boolean-name', 'blank-region', 'numeric-account', 'array-services')) {
            $inventory = $script:ValidJson | ConvertFrom-Json
            switch ($case) {
                'count-drift' { $inventory.services.lambda.count = 2 }
                'fraction' { $inventory.services.lambda.count = 1.5 }
                'string-count' { $inventory.services.lambda.count = '1' }
                'scalar-resource' { $inventory.services.lambda.resources = @(42) }
                'boolean-name' { $inventory.services.lambda.resources[0].name = $false }
                'blank-region' { $inventory.services.lambda.resources[0].region = ' ' }
                'numeric-account' { $inventory.aws_account_id = 123456789012 }
                'array-services' { $inventory.services = @() }
            }
            $path = Join-Path $TestDrive "$case.json"
            $inventory | ConvertTo-Json -Depth 10 | Set-Content $path
            & $script:Pwsh -NoProfile -File $script:Validator -InventoryPath $path
            $LASTEXITCODE | Should -Not -Be 0 -Because $case
        }
    }

    It 'accepts the documented inventory example' {
        $content = Get-Content (Join-Path $PSScriptRoot '../../skills/aws-inventory-scan/references/output-schemas.md') -Raw
        $example = [regex]::Match($content, '(?s)```json\r?\n(.*?)\r?\n```').Groups[1].Value
        $path = Join-Path $TestDrive 'example.json'
        $example | Set-Content $path
        & $script:Pwsh -NoProfile -File $script:Validator -InventoryPath $path
        $LASTEXITCODE | Should -Be 0
    }
}
