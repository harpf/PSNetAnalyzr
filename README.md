# PSNetAnalyzr 📡 – PowerShell Module for Network Analysis

A modular PowerShell toolkit for comprehensive network diagnostics based on the OSI model. This module provides dedicated functions for each network layer, ideal for system administrators, network engineers, and PowerShell enthusiasts.

---

## 🔧 Installation

```powershell
# Import the module
Import-Module ./NetzwerkToolkit.psd1
```

> Alternatively, you can copy the module folder to a path included in `$env:PSModulePath` or clone the project from a Git repository.

---

## 📚 Function Overview

### Layer 1 – Physical  
Focuses on hardware aspects such as cables, NICs, and link status.

- **`Get-NANetworkInterfaceStats`**  
  Displays all network interfaces with status, speed (Mbps), MAC address, and link status. Ideal for verifying physical connectivity.

- **`Test-NACableConnection`**  
  Checks if a physical connection (link) exists on an interface. Issues warnings for disconnected cables or disabled interfaces.

- **`Get-NANICDetails`**  
  Provides NIC details such as manufacturer, driver version, PCI info, and current duplex settings.

---

### Layer 2 – Data Link  
Deals with MAC addresses, switch access, and frame processing.

- **`Get-NAMacTable`**  
  Displays locally discovered MAC addresses or queries a switch MAC table via SNMP. Useful for locating devices in a LAN.

- **`Test-NAVLANConfiguration`**  
  Analyzes VLAN membership of an interface. Issues warnings for misconfigurations or untagged traffic.

- **`Get-NANetworkAdapterErrors`**  
  Displays error counters such as CRC errors, packet loss, and collisions. Supports hardware fault analysis.

---

### Layer 3 – Network  
Handles addressing, routing, and logical reachability.

- **`Test-NAPing`**  
  Executes ICMP ping with response times, loss rate, and TTL. Optionally shows detailed stats.

- **`Test-NATraceroute`**  
  Displays all hops to a destination with latency. Helps identify bottlenecks in routing paths.

- **`Get-NARouteTable`**  
  Shows the local routing table with gateway, metrics, and subnet mask details.

- **`Test-NANetworkReachability`**  
  Performs a combined analysis (Ping, DNS resolution, Traceroute) and evaluates overall connectivity.

---

### Layer 4 – Transport  
Covers ports, connections, and packet transmission.

- **`Test-NATCPPort`**  
  Tests if a specific TCP port is open at a target. Useful for services like HTTP, RDP, etc.

- **`Test-NAUDPPort`**  
  Performs a UDP port test (best effort – UDP is connectionless). Useful for DNS or VoIP.

- **`Measure-NALatency`**  
  Measures RTT (Round-Trip Time) for TCP connections or UDP messages.

- **`Test-NATLSHandshake`**  
  Connects to a TLS endpoint and displays cipher suite, certificates, and expiry dates.

---

### Layer 5 – Session  
Covers session setup, management, and termination.

- **`Test-NASMBSession`**  
  Connects to an SMB share and tests session availability, authentication, and drive status.

- **`Test-NALDAPSConnection`**  
  Verifies LDAPS server availability and binding (e.g., Active Directory).

- **`Test-NARDPHandshake`**  
  Simulates an RDP handshake on port 3389. Detects TLS issues and blocked ports.

---

### Layer 6 – Presentation  
Handles formatting, encryption, and encodings.

- **`Test-NACertificateChain`**  
  Displays the complete TLS certificate chain of a target, checks chain trust and expiry dates.

- **`Test-NAEncodingSupport`**  
  Checks character encodings on web or FTP servers (UTF-8, ISO-8859, etc.).

- **`Get-NAContentMimeType`**  
  Detects the `Content-Type` of a web resource. Shows whether JSON, HTML, or binary data is returned.

---

### Layer 7 – Application  
Covers services like HTTP, DNS, email, and APIs.

- **`Test-NAHttpGet`**  
  Sends HTTP GET requests, measures response time, status code, and headers. Optional content validation.

- **`Test-NADNSResolution`**  
  Performs DNS lookups for A, AAAA, MX, CNAME, etc. Supports comparison between internal and external resolvers.

- **`Test-NASMBShareAccess`**  
  Connects to a Windows share, tests read access and availability.

- **`Test-NAApiEndpoint`**  
  Tests REST endpoints (GET/POST), authentication, response time, and status codes.

- **`Test-NAMailFlow`**  
  Tests SMTP access, optional authentication, and sending of test messages.

---

### Meta Functions

- **`Export-NANetworkReport`**  
  Exports test results to Markdown, HTML, JSON, or CSV. Ideal for documentation or reporting.

- **`Invoke-NAFullScan`**  
  Performs a full network check – analyzes all relevant layers.

- **`Start-NAInteractiveWizard`**  
  Interactive CLI tool for guided network diagnostics – ideal for initial assessments.

- **`Get-NACommonIssues`**  
  Detects common issues like DNS failures, gateway misconfigurations, MTU mismatches.

- **`Invoke-NAPacketCapture`**  
  Optionally starts a packet capture using `tshark` (if available). Useful for live traffic analysis.

---

## 📂 Example

```powershell
Test-NAPing -Target "8.8.8.8" -Count 10
Test-NAHttpGet -Url "https://www.example.com"
Export-NANetworkReport -Output "Network-Report.html"
```

---

## 🧩 Requirements

- PowerShell 5.1 or 7.x  
- Administrator rights for some features  
- Optional: `tshark`, `nmap`, SNMP-capable devices

---

## 📃 License

MIT – free to use and modify

---

## 🛠️ Author

Jonas Zauner – Network & Infrastructure Development, Switzerland
