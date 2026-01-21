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
function ConvertTo-FacilityNumber {
    <#
    .SYNOPSIS
    Converts a facility string to a numeric value.

    .DESCRIPTION
    Parses facility code strings like "160" or "FC160" and returns the numeric value.
    Validates that the value is between 0 and 255.

    .PARAMETER Text
    The facility code text to parse.

    .OUTPUTS
    [uint16] The facility code as a number.
    #>
    [CmdletBinding()]
    [OutputType([uint16])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    if ($null -eq $Text -or $Text.Trim() -eq '') {
        throw "Facility cannot be empty."
    }

    $clean = $Text.Trim()
    $match = [regex]::Match($clean, '^(?i)(?:FC)?(?<num>\d+)$')
    if (-not $match.Success) {
        throw "Facility '$Text' is not a valid number. Use digits 0-255, optionally prefixed with FC (e.g., FC160)."
    }

    [int]$value = 0
    if (-not [int]::TryParse($match.Groups['num'].Value, [ref]$value)) {
        throw "Facility '$Text' is not a valid number. Use digits 0-255, optionally prefixed with FC (e.g., FC160)."
    }

    if ($value -lt 0 -or $value -gt 255) {
        throw "Facility '$Text' must be between 0 and 255."
    }

    return [uint16]$value
}
