# ps-wiegand-badge

A PowerShell module for converting ValuProx 26-bit Wiegand badge data between hex, decimal, and
facility/card number formats.

## Description

This module provides the `Convert-BadgeValue` cmdlet to convert Wiegand badge data between different
representations:

- **Hex ID** (e.g., `03409E1C`)
- **Decimal Wiegand** (e.g., `54566428`)
- **Facility Code + Badge Number** (e.g., FC 160, Badge 20238)

The module implements the standard 26-bit Wiegand format:

- 1 bit: Even parity (bits 2-13)
- 8 bits: Facility code (0-255)
- 16 bits: Card/badge number (0-65535)
- 1 bit: Odd parity (bits 14-25)

## Installation

### From PowerShell Gallery

```powershell
Install-Module ps-wiegand-badge -Scope CurrentUser

# Optional: update later
Update-Module ps-wiegand-badge
```

If your execution policy restricts installation, run from an elevated session or use
`-Scope CurrentUser`. When prompted to trust the repository, choose `Y`.

### From Source

```powershell
# Clone the repository
git clone https://github.com/RobBiddle/ps-wiegand-badge.git

# Import the module
Import-Module .\ps-wiegand-badge\ps-wiegand-badge
```

### Manual Installation

Copy the `ps-wiegand-badge` folder to one of your PowerShell module paths:

```powershell
# User modules
$env:USERPROFILE\Documents\PowerShell\Modules\

# System modules (requires admin)
$env:ProgramFiles\PowerShell\Modules\
```

## Usage

### Convert from Facility Code and Badge Number

```powershell
Convert-BadgeValue -Facility 160 -BadgeNumber 20340
```

Output:

```
HexId      DecimalWiegand  Facility   BadgeNumber  ParityOk
-----      --------------  --------   -----------  --------
03409ee9   54566633        160        20340        True
```

### Convert from Hex ID

```powershell
Convert-BadgeValue -HexId "03409E1C"
```

### Convert from Decimal Wiegand

```powershell
Convert-BadgeValue -DecimalWiegand 54566428
```

### Pipeline Support

```powershell
# Multiple hex values
"03409E1C", "03409DFD" | Convert-BadgeValue

# From CSV or other sources
Import-Csv badges.csv | Convert-BadgeValue
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-HexId` | String | Hex string representation (max 8 chars) |
| `-DecimalWiegand` | UInt32 | Decimal Wiegand value (0-67108863) |
| `-Facility` | String | Facility code (0-255), optionally prefixed with "FC" |
| `-BadgeNumber` | UInt32 | Badge/card number (0-65535) |
| `-UpperHex` | Switch | Output uppercase hex (lowercase is default) |
| `-RawHex` | Switch | Return only the hex string |
| `-IncludeBinary` | Switch | Include 26-bit binary representation |
| `-StrictParity` | Switch | Throw error if parity check fails |

## Examples

### Get Raw Hex Output

```powershell
Convert-BadgeValue -Facility 160 -BadgeNumber 20340 -RawHex
# Returns: 03409ee9
```

### Include Binary Representation

```powershell
Convert-BadgeValue -HexId "03409E1C" -IncludeBinary
```

### Validate Parity

```powershell
Convert-BadgeValue -HexId "03409E1C" -StrictParity
```

### Uppercase Hex Output

```powershell
Convert-BadgeValue -Facility 160 -BadgeNumber 20340 -UpperHex
```

## Output Object

The cmdlet returns a `WiegandBadge` object with the following properties:

| Property | Type | Description |
|----------|------|-------------|
| `HexId` | String | 8-character hex representation |
| `DecimalWiegand` | UInt32 | Decimal value of the 26-bit word |
| `Facility` | Int | Decoded facility code (0-255) |
| `BadgeNumber` | Int | Decoded badge number (0-65535) |
| `ParityOk` | Boolean | Whether parity bits are valid |
| `SourceParameter` | String | Which parameter set was used |
| `Word26Binary` | String | 26-bit binary (only with `-IncludeBinary`) |

## Requirements

- PowerShell 3.0 or later
- Windows PowerShell 5.1 or PowerShell 7+

## License

Copyright (c) Robert D. Biddle. All rights reserved.

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file
for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
