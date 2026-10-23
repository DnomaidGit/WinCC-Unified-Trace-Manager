# WinCC Unified Trace Manager

Web-based tool for managing Siemens WinCC Unified TraceReceiver connections to Unified Comfort Panels.

The application provides a simple graphical interface to connect to a Siemens Unified panel and launch the official Siemens TraceViewer without manually entering commands in Windows CMD.

## Features

- Web-based graphical interface using HTML, CSS and JavaScript.
- Connect to Siemens WinCC Unified panels using their IP address.
- Start `RTILtraceTool.exe` automatically.
- Display TraceReceiver diagnostic messages in real time.
- Launch Siemens `RTILtraceViewer.exe`.
- Save connection settings.
- Clear the diagnostic console.
- Export diagnostic messages to a TXT file.
- No Python or Node.js installation required.

## Requirements

- Windows 10, Windows 11 or a compatible Windows environment.
- Windows PowerShell 5.1.
- Siemens WinCC Unified engineering/runtime tools installed.
- Network connectivity to the target Unified panel.
- **Enable Trace forwarder activated on the HMI panel.**

## HMI Configuration – Enable Trace Forwarder

**Important:** Before connecting to an HMI panel, the **Enable Trace forwarder** option must be activated on the Siemens Unified Comfort Panel.

To enable it:

1. Open the **Control Panel** on the HMI.
2. Navigate to **Service and Commissioning**.
3. Open **Trace options**.
4. Activate **Enable Trace forwarder**.
5. Ensure that the HMI and the Windows computer can communicate over the network.

**Note:** The menu names may vary depending on the panel firmware version.

If **Enable Trace forwarder** is disabled, WinCC Unified Trace Manager will not be able to receive the panel's forwarded traces.

## Installation

1. Download or clone this repository.
2. Extract the files into a local folder.
3. Run `Iniciar.bat`.
4. Open `http://localhost:8080` in your browser if it does not open automatically.

## Configuration

The application uses the following default Siemens installation directory:

`C:\Program Files\Siemens\Automation\WinCCUnified\bin`

Required Siemens executables:

- `RTILtraceTool.exe`
- `RTILtraceViewer.exe`

The directory can be modified directly from the web interface.

## Usage

1. Enable **Trace forwarder** on the HMI panel.
2. Enter the IP address of the Siemens Unified panel.
3. Click **Conectar** to start TraceReceiver.
4. Monitor the connection status and diagnostic messages in the web console.
5. Click **Abrir TraceViewer** to launch the Siemens trace viewer.
6. Use **Exportar TXT** to save the displayed diagnostic output.

The TraceReceiver connection uses the Siemens trace tool. The actual trace records are displayed through Siemens TraceViewer.

## Technologies

- HTML5
- CSS3
- JavaScript
- Windows PowerShell
- Windows Batch

## Project structure

```text
WinCC-Unified-Trace-Manager/
├── index.html
├── server.ps1
├── Iniciar.bat
└── README.md
```

## Important notes

This project is an independent utility and is not affiliated with, endorsed by, or officially supported by Siemens.

Siemens, SIMATIC and WinCC are trademarks of Siemens AG.

Siemens executables are not included in this repository. Users must have the required Siemens software installed.

The HTTP server is intended for local use on a trusted Windows computer and should not be exposed directly to untrusted networks.

## License

MIT License, if included in the repository.

## Project status

Initial functional version. Further testing and improvements may be required across different WinCC Unified versions and Windows environments.
