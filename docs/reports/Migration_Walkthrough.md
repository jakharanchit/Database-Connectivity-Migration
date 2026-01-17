# Walkthrough: Migrating to MSOLEDBSQL and Windows Authentication

---

## 1. Executive Summary
This guide provides the step-by-step technical procedure to retire insecure `.udl` files and legacy `SQLOLEDB` providers. It details the installation of `MSOLEDBSQL19`, the configuration of Kerberos/SPNs, and the precise construction of secure connection strings for 32-bit and 64-bit client applications.

---

## 2. Prerequisites & Environment Setup

### 2.1 Driver Installation
**Critical Rule:** You must install the **Microsoft OLE DB Driver 19 for SQL Server (`msoledbsql.msi`)**.
*   **Download:** [Official Microsoft Download](https://learn.microsoft.com/en-us/sql/connect/oledb/download-oledb-driver-for-sql-server)
*   **Architecture:** Run the **x64** installer on 64-bit Windows. This installs **BOTH** the 64-bit and 32-bit drivers, which is required for 32-bit applications (like standard LabVIEW).
*   **Dependency:** Ensure the **Visual C++ Redistributable (x86)** is installed if running 32-bit clients, even on a 64-bit OS.

### 2.2 Verification (PowerShell)
Before writing code, verify the driver is registered correctly. Run this PowerShell script to check for the 32-bit driver on a 64-bit OS:

```powershell
# Verify MSOLEDBSQL registration in the 32-bit Hive (Wow6432Node)
Get-ChildItem -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft" | 
Where-Object { $_.Name -like "*MSOLEDBSQL*" } | 
ForEach-Object { Get-ItemProperty $_.PSPath }
```
*If this returns nothing, your LabVIEW/32-bit app will fail with "Provider cannot be found".*

---

## 3. Server-Side Configuration (The "Identity" Layer)

Windows Authentication relies on Active Directory. You are no longer managing users in SQL Server; you are managing them in AD.

### 3.1 Service Principal Names (SPN)
For Kerberos (required for high performance and security) to function, the SQL Server service account must have an SPN.

1.  **Download:** Microsoft Kerberos Configuration Manager for SQL Server.
2.  **Run:** Execute on the SQL Server.
3.  **Action:** Look for "Missing" SPNs and use the generated "Fix" script (or `setspn -S`).
    *   *Symptom of failure:* "Cannot generate SSPI context" errors.

### 3.2 Access Control
1.  **Create AD Group:** e.g., `CONTOSO\OT_Operators`.
2.  **SQL Login:**
    ```sql
    USE [master];
    CREATE LOGIN [CONTOSO\OT_Operators] FROM WINDOWS;
    ```
3.  **Database User:**
    ```sql
    USE [ProductionDB];
    CREATE USER [CONTOSO\OT_Operators] FOR LOGIN [CONTOSO\OT_Operators];
    ALTER ROLE [db_datareader] ADD MEMBER [CONTOSO\OT_Operators];
    ALTER ROLE [db_datawriter] ADD MEMBER [CONTOSO\OT_Operators];
    ```

---

## 4. Connection String Implementation

Refactor your application to build the connection string in memory. Do not read from a file.

### 4.1 The Blueprint
**Old (Insecure UDL):**
`Provider=SQLOLEDB;Data Source=ServerIP;User ID=sa;Password=pass;`

**New (Secure MSOLEDBSQL):**
`Provider=MSOLEDBSQL19;Server=MyServer.domain.com;Database=MyDB;Integrated Security=SSPI;Use Encryption for Data=Optional;`

### 4.2 Parameter Breakdown
| Keyword | Value | Description |
| :--- | :--- | :--- |
| **Provider** | `MSOLEDBSQL19` | Forces the specific Version 19 driver. Safer than generic `MSOLEDBSQL`. |
| **Server** | `FQDN` (e.g., `db.contoso.com`) | **CRITICAL:** Do not use IP Address. Kerberos requires FQDN to map the SPN. |
| **Integrated Security** | `SSPI` | Triggers Windows Authentication (negotiates Kerberos). |
| **Use Encryption for Data** | `Mandatory` or `Optional` | v19 defaults to Mandatory. If you lack trusted certs, use `Optional` or add `TrustServerCertificate=yes`. |

### 4.3 LabVIEW Specifics
When using `DB Tools Open Connection.vi`:
1.  **Prompt:** Set to `4` (`adPromptNever`). This prevents the UI thread from hanging on a login dialog if authentication fails.
2.  **Bitness:** Ensure you are testing with the 32-bit UDL wizard if verifying manually:
    `C:\Windows\SysWOW64\rundll32.exe "C:\Program Files (x86)\Common Files\System\Ole DB\oledb32.dll",OpenDSLFile test.udl`

---

## 5. Troubleshooting Common Errors

| Error Message | Root Cause | Fix |
| :--- | :--- | :--- |
| **"Provider cannot be found. It may not be properly installed."** | Bitness Mismatch. | You are running a 32-bit app (LabVIEW) but only installed the x64 driver, or missing the x86 VC++ runtime. Reinstall `msoledbsql.msi` and check `Wow6432Node`. |
| **"Login failed for user 'NT AUTHORITY\ANONYMOUS LOGON'"** | Double Hop Issue. | Your app is passing through a middle tier (IIS/Web Service) that isn't trusted for delegation in AD. |
| **"Cannot generate SSPI context"** | Kerberos Failure. | Missing or Duplicate SPN. Use Kerberos Config Manager to fix. Ensure you are using FQDN, not IP. |
| **"SSL Provider: The certificate chain was issued by an authority that is not trusted."** | Encryption Default. | MSOLEDBSQL19 enforces encryption. Add `TrustServerCertificate=yes` or install a valid CA cert on SQL Server. |

---
*End of Report*
