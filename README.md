# Secure Database Connectivity Migration

![Status](https://img.shields.io/badge/Status-Complete-green)
![Driver](https://img.shields.io/badge/Driver-MSOLEDBSQL19-blue)
![Security](https://img.shields.io/badge/Auth-Kerberos%2FSSPI-secure)

**Welcome to the Database Connectivity Migration repository.**

This repository contains the complete technical deliverables for migrating an Industrial Automation system from insecure legacy providers (`SQLOLEDB` / `.udl`) to the secure **Microsoft OLE DB Driver 19** using **Windows Authentication**.

## 📂 Repository Structure

| Directory | Content |
| :--- | :--- |
| `docs/` | **Start Here.** Contains the [Client Migration Guide](docs/Client_Migration_Guide.md) and technical reports. |
| `src/scripts/` | Validation scripts (PowerShell) to verify driver installation on client machines. |
| `src/sql/` | SQL scripts to provision Active Directory users and permissions on the server. |
| `labview/` | Placeholder for LabVIEW source code and `.vi` modules. |

## 🚀 Quick Start (Deploying to a Client)

### 1. Prerequisites
*   **OS:** Windows 10/11 or Server 2019+ (64-bit)
*   **Network:** DNS Resolution to SQL Server FQDN must work.

### 2. Installation Steps
1.  **Install Driver:** Download and install [Microsoft OLE DB Driver 19 for SQL Server (x64)](https://learn.microsoft.com/en-us/sql/connect/oledb/download-oledb-driver-for-sql-server).
    *   *Note:* The x64 installer automatically installs the 32-bit components required for LabVIEW.
2.  **Verify Installation:**
    Run the included PowerShell script to confirm the driver is visible to LabVIEW:
    ```powershell
    ./src/scripts/Verify_Driver_Installation.ps1
    ```
3.  **Database Access (Admin Only):**
    Customize and execute `src/sql/01_Setup_Logins.sql` on the SQL Server to grant access to the appropriate AD group.

## 🔗 Key Documentation
*   [**Client Migration Guide:**](docs/Client_Migration_Guide.md) The official manual for this change.
*   [**Engineering Walkthrough:**](docs/reports/Migration_Walkthrough.md) Deep technical details on the "Why" and "How".

---
*Maintained by Engineering Team*