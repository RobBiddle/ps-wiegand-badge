<#
    ps-wiegand-badge - PowerShell Module to perform Wiegand Badge Conversions.
    Copyright (C) 2026 Robert D. Biddle

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

BeforeAll {
    # Import the module
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\ps-wiegand-badge\ps-wiegand-badge.psd1'
    Import-Module $ModulePath -Force
}

Describe 'Convert-BadgeValue' {

    Context 'Module and Function Availability' {

        It 'Should have the Convert-BadgeValue function available' {
            Get-Command -Name Convert-BadgeValue -Module ps-wiegand-badge | Should -Not -BeNullOrEmpty
        }

        It 'Should have the cvbv alias available' {
            Get-Alias -Name cvbv -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'FromFacilityCard Parameter Set' {

        It 'Should convert facility 160 and badge 20340 correctly' {
            $result = Convert-BadgeValue -Facility 160 -BadgeNumber 20340
            $result.Facility | Should -Be 160
            $result.BadgeNumber | Should -Be 20340
            $result.ParityOk | Should -BeTrue
        }

        It 'Should accept FC prefix for facility code' {
            $result = Convert-BadgeValue -Facility 'FC160' -BadgeNumber 20340
            $result.Facility | Should -Be 160
        }

        It 'Should handle facility 0 correctly' {
            $result = Convert-BadgeValue -Facility 0 -BadgeNumber 1
            $result.Facility | Should -Be 0
            $result.BadgeNumber | Should -Be 1
            $result.ParityOk | Should -BeTrue
        }

        It 'Should handle facility 255 correctly' {
            $result = Convert-BadgeValue -Facility 255 -BadgeNumber 65535
            $result.Facility | Should -Be 255
            $result.BadgeNumber | Should -Be 65535
            $result.ParityOk | Should -BeTrue
        }

        It 'Should generate correct parity bits' {
            $result = Convert-BadgeValue -Facility 160 -BadgeNumber 20340
            $result.ParityOk | Should -BeTrue
        }
    }

    Context 'FromHex Parameter Set' {

        It 'Should convert hex value to facility and badge number' {
            $result = Convert-BadgeValue -HexId '03409E1C'
            $result.Facility | Should -Be 160
            $result.BadgeNumber | Should -Be 20238
            $result.HexId | Should -Be '03409e1c'
        }

        It 'Should accept lowercase hex' {
            $result = Convert-BadgeValue -HexId '03409e1c'
            $result.Facility | Should -Be 160
        }

        It 'Should accept short hex values' {
            $result = Convert-BadgeValue -HexId 'FF'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Should reject invalid hex characters' {
            { Convert-BadgeValue -HexId 'GHIJKLMN' } | Should -Throw
        }

        It 'Should accept max valid 26-bit value' {
            { Convert-BadgeValue -HexId '3FFFFFF' } | Should -Not -Throw
        }

        It 'Should reject hex values exceeding 26-bit capacity' {
            { Convert-BadgeValue -HexId '4000000' } | Should -Throw
        }

        It 'Should support pipeline input' {
            $results = '03409E1C', '03409DFD' | Convert-BadgeValue
            $results.Count | Should -Be 2
            $results[0].Facility | Should -Be 160
            $results[1].Facility | Should -Be 160
        }
    }

    Context 'FromDecimal Parameter Set' {

        It 'Should convert decimal value to facility and badge number' {
            $result = Convert-BadgeValue -DecimalWiegand 54566428
            $result.Facility | Should -Be 160
            $result.BadgeNumber | Should -Be 20238
        }

        It 'Should handle zero value' {
            $result = Convert-BadgeValue -DecimalWiegand 0
            $result.DecimalWiegand | Should -Be 0
        }

        It 'Should handle maximum 26-bit value' {
            $result = Convert-BadgeValue -DecimalWiegand 67108863
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Round-Trip Conversions' {

        It 'Should round-trip from facility/card to hex and back' {
            $original = Convert-BadgeValue -Facility 160 -BadgeNumber 20340
            $roundTrip = Convert-BadgeValue -HexId $original.HexId
            $roundTrip.Facility | Should -Be 160
            $roundTrip.BadgeNumber | Should -Be 20340
        }

        It 'Should round-trip from facility/card to decimal and back' {
            $original = Convert-BadgeValue -Facility 100 -BadgeNumber 12345
            $roundTrip = Convert-BadgeValue -DecimalWiegand $original.DecimalWiegand
            $roundTrip.Facility | Should -Be 100
            $roundTrip.BadgeNumber | Should -Be 12345
        }
    }

    Context 'Output Options' {

        It 'Should output uppercase hex when -UpperHex is specified' {
            $result = Convert-BadgeValue -Facility 160 -BadgeNumber 20340 -UpperHex
            $result.HexId | Should -BeExactly $result.HexId.ToUpperInvariant()
        }

        It 'Should return only hex string when -RawHex is specified' {
            $result = Convert-BadgeValue -Facility 160 -BadgeNumber 20340 -RawHex
            $result | Should -BeOfType [string]
            $result | Should -Match '^[0-9a-f]{8}$'
        }

        It 'Should include binary when -IncludeBinary is specified' {
            $result = Convert-BadgeValue -Facility 160 -BadgeNumber 20340 -IncludeBinary
            $result.Word26Binary | Should -Not -BeNullOrEmpty
            $result.Word26Binary.Length | Should -Be 26
        }
    }

    Context 'Parity Validation' {

        It 'Should report ParityOk as True for valid parity' {
            $result = Convert-BadgeValue -Facility 160 -BadgeNumber 20340
            $result.ParityOk | Should -BeTrue
        }

        It 'Should throw with -StrictParity when parity is invalid' {
            # Manually construct a value with bad parity (flip a parity bit)
            # 0x03409EE9 is valid for FC160/20340, flip last bit to make parity bad
            { Convert-BadgeValue -DecimalWiegand 54566632 -StrictParity } | Should -Throw
        }
    }

    Context 'Error Handling' {

        It 'Should throw for empty facility' {
            { Convert-BadgeValue -Facility '' -BadgeNumber 123 } | Should -Throw
        }

        It 'Should throw for facility out of range' {
            { Convert-BadgeValue -Facility 256 -BadgeNumber 123 } | Should -Throw
        }

        It 'Should throw for negative facility value' {
            { Convert-BadgeValue -Facility -1 -BadgeNumber 123 } | Should -Throw
        }

        It 'Should throw for negative badge number' {
            { Convert-BadgeValue -Facility 160 -BadgeNumber -1 } | Should -Throw
        }

        It 'Should throw for badge number exceeding 65535' {
            { Convert-BadgeValue -Facility 160 -BadgeNumber 65536 } | Should -Throw
        }
    }

    Context 'Output Type' {

        It 'Should return WiegandBadge type' {
            $result = Convert-BadgeValue -Facility 160 -BadgeNumber 20340
            $result.PSTypeNames | Should -Contain 'WiegandBadge'
        }

        It 'Should have expected properties' {
            $result = Convert-BadgeValue -Facility 160 -BadgeNumber 20340
            $result.PSObject.Properties.Name | Should -Contain 'HexId'
            $result.PSObject.Properties.Name | Should -Contain 'DecimalWiegand'
            $result.PSObject.Properties.Name | Should -Contain 'Facility'
            $result.PSObject.Properties.Name | Should -Contain 'BadgeNumber'
            $result.PSObject.Properties.Name | Should -Contain 'ParityOk'
            $result.PSObject.Properties.Name | Should -Contain 'SourceParameter'
        }
    }
}

Describe 'Module Manifest' {

    BeforeAll {
        $script:ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\ps-wiegand-badge\ps-wiegand-badge.psd1'
        $script:Manifest = Test-ModuleManifest -Path $script:ManifestPath
    }

    It 'Should have a valid module manifest' {
        $script:Manifest | Should -Not -BeNullOrEmpty
    }

    It 'Should export Convert-BadgeValue function' {
        $script:Manifest.ExportedFunctions.Keys | Should -Contain 'Convert-BadgeValue'
    }

    It 'Should export cvbv alias' {
        $script:Manifest.ExportedAliases.Keys | Should -Contain 'cvbv'
    }

    It 'Should not export any variables' {
        $script:Manifest.ExportedVariables.Count | Should -Be 0
    }

    It 'Should support Desktop and Core editions' {
        $script:Manifest.CompatiblePSEditions | Should -Contain 'Desktop'
        $script:Manifest.CompatiblePSEditions | Should -Contain 'Core'
    }

    It 'Should require PowerShell 5.1 or higher' {
        $script:Manifest.PowerShellVersion | Should -BeGreaterOrEqual ([version]'5.1')
    }
}
