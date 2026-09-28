# CloudFormation → Bicep Syntax Mapping

| CloudFormation | Bicep | Notes |
|---|---|---|
| `AWSTemplateFormatVersion` | Removed | Not needed in Bicep |
| `Parameters` | `param` | Parameter declarations |
| `Variables` | `var` | Variable declarations |
| `Resources` | `resource` or `module` | Resource declarations |
| `Outputs` | `output` | Output declarations |
| `!Ref` | `resourceName.id` / `resourceName.properties.xxx` | Context-dependent |
| `!Sub '${Var}text'` | `'${varName}text'` | Bicep string interpolation |
| `!GetAtt Resource.Attr` | `resourceName.properties.xxx` | Property path from resource type |
| `!Join ['', [a, b]]` | `'${a}${b}'` | Use interpolation or `join()` |
| `Fn::Select [i, list]` | `list[i]` | Array indexing |
| `Fn::If` | ternary `condition ? a : b` | Bicep conditional expressions |
