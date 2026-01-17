# Project Execution Report: Secure Database Connectivity Migration

## 1. Executive Summary

This project addresses a Critical Severity vulnerability in the current Industrial Automation / Software architecture: the reliance on unencrypted Universal Data Link (`.udl`) files and legacy `SQLOLEDB` providers. The current state exposes plain-text credentials and utilizes deprecated data access technologies.

The migration to the **Microsoft OLE DB Driver for SQL Server (MSOLEDBSQL19)** utilizing **Windows Authentication (Integrated Security)** will align the system with IEC 62443 and NIST SP 800-82 standards. This shift moves identity management from decentralized, static files to the centralized, auditable control of Active Directory.

## 2. Risk Analysis: The "Why"

### 2.1 Current State Risks (Legacy)
*   **Credential Exposure:** `.udl` files store passwords in plain text if "Allow Saving Password" is enabled. Any user with file read access can compromise the database.
*   **Compliance Violation:** Static passwords often violate rotation policies. Shared SQL accounts (e.g., `sa` or `operator`) eliminate non-repudiation (you cannot know *who* did what).
*   **Encryption Gaps:** The legacy `SQLOLEDB` provider does not support TLS 1.3, leaving data in transit vulnerable to interception on the OT network.

### 2.2 Target State Benefits (Modern)
*   **Zero Trust Identity:** Authentication is handled via Kerberos tokens (SSPI). The application never handles a password.
*   **Centralized Management:** Access is granted to AD Groups (e.g., `OT_Users`). Employee offboarding is instant and handled by IT, requiring no changes to the plant software.
*   **Future Proofing:** `MSOLEDBSQL19` supports modern SQL types, Azure connectivity, and mandatory encryption defaults.

## 3. Technical Strategy

### 3.1 The "Driver" Standard
We are standardizing on **`MSOLEDBSQL19`**.
*   *Justification:* `SQLNCLI` and `SQLOLEDB` are deprecated. `MSOLEDBSQL` is the only driver receiving security updates.
*   *Deployment:* The driver must be deployed to all client workstations. Attention to "bitness" (installing x86 runtimes for 32-bit LabVIEW/Apps) is paramount.

### 3.2 The "Auth" Standard
We are moving to **`Integrated Security=SSPI`**.
*   *Mechanism:* The application runs under the context of the logged-in Windows User or the Service Account (if a service).
*   *Network Protocol:* We prioritize **Kerberos** over NTLM for mutual authentication. This requires correct Service Principal Name (SPN) registration for the SQL Server.

### 3.3 Connection String Architecture
The file-based configuration (`File Name=...`) is deprecated. Connection strings will be constructed in-memory using the following template:

```text
Provider=MSOLEDBSQL19;
Server=<FQDN_OF_SQL_SERVER>;
Database=<DATABASE_NAME>;
Integrated Security=SSPI;
Use Encryption for Data=Mandatory;
Trust Server Certificate=<No/Yes>;
```

## 4. Implementation Roadmap

1.  **Infrastructure Prep (IT/Admin):**
    *   Audit and fix SPNs on SQL Servers.
    *   Create AD Groups for OT/App Users.
    *   Map AD Groups to SQL Logins/Users.

2.  **Client Deployment (Engineering):**
    *   Deploy `msoledbsql.msi` (x64) and VC++ Redistributable (x86) to all client nodes.
    *   Verify registry keys for 32-bit visibility.

3.  **Code Migration (Dev):**
    *   Refactor code to remove `.udl` file reads.
    *   Implement connection string builder logic.
    *   Set `prompt=adPromptNever` to support headless operation.

4.  **Validation:**
    *   Verify connection using 32-bit UDL wizard (`rundll32 ... oledb32.dll`).
    *   Validate Kerberos via `klist` or Wireshark (port 88 traffic).

## 5. Conclusion

Eliminating `.udl` files is not merely a "cleanup" task; it is a fundamental security hardening requirement. This migration bridges the gap between OT and IT security standards, ensuring that our database connectivity is as secure as the rest of our enterprise infrastructure.

---
*End of Report*
