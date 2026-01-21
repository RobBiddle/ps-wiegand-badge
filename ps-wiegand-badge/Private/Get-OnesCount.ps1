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
function Get-OnesCount {
    <#
    .SYNOPSIS
    Counts the number of set bits (1s) in a 32-bit unsigned integer.

    .DESCRIPTION
    PopCount helper uses BitOperations when available (PowerShell 7+),
    falls back to manual counting for Windows PowerShell.

    .PARAMETER Value
    The 32-bit unsigned integer to count bits in.

    .OUTPUTS
    [int] The number of set bits.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [uint32]$Value
    )

    # Use cached check from module load for better performance
    if ($script:UseBitOperations) {
        return [System.Numerics.BitOperations]::PopCount($Value)
    }

    $count = 0
    $work = $Value
    while ($work -ne 0) {
        $count += ($work -band 1)
        $work = $work -shr 1
    }
    return $count
}
