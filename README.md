# compress_png.ps1

A PowerShell script to batch‑optimize PNG images using [oxipng](https://github.com/oxipng/oxipng). It recursively scans a folder for .png files, writes optimized copies into a `compressed` subfolder (preserving structure), and skips anything already inside that folder.

---

## ✨ Features

- **Recursive scan:** Finds all PNGs under the input folder
- **Output mirroring:** Saves results under `input\compressed` with the same relative paths
- **Skip reprocessing:** Ignores files already in `compressed`
- **Parallel work:** Uses multiple cores via PowerShell 7 parallelism
- **Modes:** Default (`--opt=2`), Max (`--opt=max`), optional Zopfli (much slower)
- **Reports:** Detailed per‑file results and a summary (sizes and % saved)
- **CSV export:** Optional results CSV with auto timestamp or custom path
- **Short flags:** Handy one‑letter aliases for common switches

---

## 🧩 Requirements

- PowerShell 7+
- [oxipng](https://github.com/oxipng/oxipng) available in PATH or placed next to the script

---

## 📦 Installation

- Place `Compress-PNGs.ps1` anywhere you like.
- Ensure `oxipng.exe` is accessible (PATH or same folder as the script).

---

## 🚀 Usage

- **Default compression (opt=2):**  
  pwsh Compress-PNGs.ps1 "C:\Textures"

- **Max compression:**  
  pwsh Compress-PNGs.ps1 "C:\Textures" -Max  
  pwsh Compress-PNGs.ps1 "C:\Textures" -m

- **Zopfli (slow, smallest size):**  
  pwsh Compress-PNGs.ps1 "C:\Textures" -Zopfli  
  pwsh Compress-PNGs.ps1 "C:\Textures" -z

- **Max + Zopfli:**  
  pwsh Compress-PNGs.ps1 "C:\Textures" -m -z

- **Skip files that already exist in compressed:**  
  pwsh Compress-PNGs.ps1 "C:\Textures" -SkipExisting  
  pwsh Compress-PNGs.ps1 "C:\Textures" -s

- **Enable CSV export (auto timestamped in input folder):**  
  pwsh Compress-PNGs.ps1 "C:\Textures" -CsvLog  
  pwsh Compress-PNGs.ps1 "C:\Textures" -c

- **CSV export to a specific path:**  
  pwsh Compress-PNGs.ps1 "C:\Textures" -c -CsvPath "C:\logs\results.csv"  
  pwsh Compress-PNGs.ps1 "C:\Textures" -c -p "C:\logs\results.csv"

---

## 🎛️ Options and aliases

- **InputFolder (string):** Root folder to scan; defaults to "."
- **MaxCores (int):** Parallel throttle; defaults to your CPU core count
- **SkipExisting (-s):** Do not recompress if output file already exists
- **Max (-m):** Use `--opt=max` (slower, better compression than default)
- **Zopfli (-z):** Add `--zopfli` (much slower; often a bit smaller)
- **CsvLog (-c):** Export results to CSV; if no path provided, auto‑name in input folder
- **CsvPath (-p):** Explicit CSV file path used when `-CsvLog` is set

---

## ⚙️ Behavior

- Input files are discovered under the specified folder.
- Anything beneath the `compressed` subfolder is excluded from processing.
- Output paths mirror the input folder structure.
- If `-s` is used, files already present in `compressed` are marked Skipped.

---

## ⚡ Performance notes

- Oxipng max is very fast and yields near‑optimal sizes for most images.
- Zopfli often reduces size a bit further but can be orders of magnitude slower.
- Recommended workflow: use oxipng for day‑to‑day; reserve Zopfli for final releases/archives.

---

## 📄 License

This project is licensed under the GNU General Public License v3.0 (GPLv3). See the LICENSE file for details.

---

## 🙏 Acknowledgements

- oxipng for PNG optimization
- PowerShell 7 for parallel processing capabilities
