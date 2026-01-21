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
function Convert-BadgeValue {
    <#
    .SYNOPSIS
    Convert ValuProx 26-bit Wiegand badge data between hex, decimal Wiegand, and facility/card.

    .DESCRIPTION
    Single cmdlet with parameter sets for each conversion direction:
    - From facility code + card number to hex/decimal Wiegand
    - From hex to facility code + card number + decimal Wiegand
    - From decimal Wiegand to facility code + card number + hex

    Implements ValuProx 26-bit layout: P1 (even parity over bits 2-13), payload24 (facility 8 bits + card 16 bits), P2 (odd parity over bits 14-25).

    .PARAMETER HexId
    The hex string representation of the 26-bit Wiegand value (max 8 hex chars).

    .PARAMETER DecimalWiegand
    The decimal representation of the 26-bit Wiegand value (0 to 67108863).

    .PARAMETER Facility
    The facility code (0-255). Can be prefixed with "FC" (e.g., "FC160").

    .PARAMETER BadgeNumber
    The badge/card number (0-65535).

    .PARAMETER UpperHex
    Output uppercase hex instead of lowercase.

    .PARAMETER RawHex
    Emit only the hex string (scripting-friendly), skipping the object wrapper.

    .PARAMETER IncludeBinary
    Add a 26-bit binary string to the output for debugging.

    .PARAMETER StrictParity
    Validate incoming parity bits and throw if they are incorrect (for FromHex/FromDecimal).

    .EXAMPLE
    Convert-BadgeValue -Facility 160 -BadgeNumber 20340

    Converts facility code 160 and badge number 20340 to hex and decimal Wiegand values.

    .EXAMPLE
    Convert-BadgeValue -HexId "03409E1C"

    Converts a hex Wiegand value to facility code, badge number, and decimal.

    .EXAMPLE
    Convert-BadgeValue -DecimalWiegand 5456140

    Converts a decimal Wiegand value to facility code, badge number, and hex.

    .EXAMPLE
    "03409E1C","03409DFD" | Convert-BadgeValue

    Converts multiple hex values via pipeline.

    .EXAMPLE
    Convert-BadgeValue -HexId "03409E1C" -StrictParity

    Converts and validates parity bits, throwing an error if they are incorrect.

    .OUTPUTS
    PSCustomObject with properties: HexId, DecimalWiegand, Facility, BadgeNumber, ParityOk, SourceParameter
    If -IncludeBinary is specified, also includes Word26Binary.
    If -RawHex is specified, returns only the hex string.

    .NOTES
    Author: Robert D. Biddle
    Module: ps-wiegand-badge
    Version: 1.0.0

    The 26-bit Wiegand format is commonly used in HID proximity cards and access control systems.
    Bit layout: [P1][8-bit Facility][16-bit Card Number][P2]
    - P1: Even parity over bits 2-13
    - P2: Odd parity over bits 14-25

    .LINK
    https://github.com/RobBiddle/ps-wiegand-badge

    .LINK
    https://en.wikipedia.org/wiki/Wiegand_interface
    #>
    [CmdletBinding(DefaultParameterSetName = 'FromHex')]
    [Alias('cvbv')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'FromHex', Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Hex')]
        [ValidatePattern('^[0-9A-Fa-f]{1,8}$')]
        [ValidateLength(1, 8)]
        [string]$HexId,

        [Parameter(ParameterSetName = 'FromDecimal', Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Decimal')]
        [ValidateRange(0, 0x3FFFFFF)]
        [uint32]$DecimalWiegand,

        [Parameter(ParameterSetName = 'FromFacilityCard', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Facility,

        [Parameter(ParameterSetName = 'FromFacilityCard', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(0, 0xFFFF)]
        [uint32]$BadgeNumber,

        # Output options
        [Parameter()]
        [switch]$UpperHex,

        [Parameter()]
        [switch]$RawHex,

        [Parameter()]
        [switch]$IncludeBinary,

        # Validation options
        [Parameter()]
        [switch]$StrictParity
    )

    begin {
        # Helper function to create terminating errors with proper ErrorRecord
        function New-TerminatingError {
            param(
                [string]$Message,
                [string]$ErrorId,
                [System.Management.Automation.ErrorCategory]$Category = [System.Management.Automation.ErrorCategory]::InvalidArgument,
                [object]$TargetObject = $null
            )
            $exception = [System.ArgumentException]::new($Message)
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                $exception,
                $ErrorId,
                $Category,
                $TargetObject
            )
            return $errorRecord
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'FromHex' {
                [uint32]$value26 = 0
                if (-not [uint32]::TryParse($HexId, [System.Globalization.NumberStyles]::HexNumber, $null, [ref]$value26)) {
                    $PSCmdlet.ThrowTerminatingError(
                        (New-TerminatingError -Message "HexId '$HexId' is not valid hex." -ErrorId 'InvalidHexFormat' -TargetObject $HexId)
                    )
                }
                if ($value26 -gt 0x3FFFFFF) {
                    $PSCmdlet.ThrowTerminatingError(
                        (New-TerminatingError -Message "HexId '$HexId' exceeds 26-bit capacity (max 0x3FFFFFF / 67108863)." -ErrorId 'HexValueTooLarge' -TargetObject $HexId)
                    )
                }
            }

            'FromDecimal' {
                $value26 = $DecimalWiegand
                if ($value26 -gt 0x3FFFFFF) {
                    $PSCmdlet.ThrowTerminatingError(
                        (New-TerminatingError -Message "DecimalWiegand '$DecimalWiegand' exceeds 26-bit capacity (max 67108863)." -ErrorId 'DecimalValueTooLarge' -TargetObject $DecimalWiegand)
                    )
                }
            }

            'FromFacilityCard' {
                $facilityValue = ConvertTo-FacilityNumber -Text $Facility
                $payload24 = ([uint32]$facilityValue -shl 16) -bor ([uint32]$BadgeNumber -band 0xFFFF)

                $bits_2_13 = ($payload24 -shr 12) -band 0xFFF
                if ((Get-OnesCount -Value $bits_2_13) % 2 -eq 0) {
                    $p1 = 0  # even parity
                } else {
                    $p1 = 1
                }

                $bits_14_25 = $payload24 -band 0xFFF
                if ((Get-OnesCount -Value $bits_14_25) % 2 -eq 0) {
                    $p2 = 1  # odd parity
                } else {
                    $p2 = 0
                }

                $value26 = ($p1 -shl 25) -bor ($payload24 -shl 1) -bor $p2
            }
        }

        $payload24 = ($value26 -shr 1) -band 0xFFFFFF
        $facilityDecoded = ($payload24 -shr 16) -band 0xFF
        $badgeNumberDecoded = $payload24 -band 0xFFFF

        # Parity verification for decoded word
        $actualP1 = ($value26 -shr 25) -band 0x1
        $actualP2 = $value26 -band 0x1
        $bits_2_13_check = ($payload24 -shr 12) -band 0xFFF
        $parityCount1 = (Get-OnesCount -Value $bits_2_13_check) % 2
        if ($parityCount1 -eq 0) { $expectedP1 = 0 } else { $expectedP1 = 1 }
        $bits_14_25_check = $payload24 -band 0xFFF
        $parityCount2 = (Get-OnesCount -Value $bits_14_25_check) % 2
        if ($parityCount2 -eq 0) { $expectedP2 = 1 } else { $expectedP2 = 0 }
        $ParityOk = ($actualP1 -eq $expectedP1) -and ($actualP2 -eq $expectedP2)
        if ($StrictParity -and -not $ParityOk) {
            $parityLabel = if ($PSCmdlet.ParameterSetName -eq 'FromHex') { $HexId } elseif ($PSCmdlet.ParameterSetName -eq 'FromDecimal') { $DecimalWiegand } else { 'payload' }
            $PSCmdlet.ThrowTerminatingError(
                (New-TerminatingError -Message "Parity check failed for value '$parityLabel'." -ErrorId 'ParityCheckFailed' -Category ([System.Management.Automation.ErrorCategory]::InvalidData) -TargetObject $parityLabel)
            )
        }

        $hexOut = ('{0:x8}' -f $value26)
        if ($UpperHex) { $hexOut = $hexOut.ToUpperInvariant() }
        if ($RawHex) {
            return $hexOut
        }

        $result = [ordered]@{
            PSTypeName      = 'WiegandBadge'
            HexId           = $hexOut
            DecimalWiegand  = $value26
            Facility        = $facilityDecoded
            BadgeNumber     = $badgeNumberDecoded
            ParityOk        = $ParityOk
            SourceParameter = $PSCmdlet.ParameterSetName
        }
        if ($IncludeBinary) {
            $result.Word26Binary = [Convert]::ToString($value26, 2).PadLeft(26, '0')
        }

        [PSCustomObject]$result
    }
}
