# LabVIEW Migration Report: Database Connectivity Refactoring

**Target Component:** Database Connection Module (`DB Tools Open Connection.vi`)
**Context:** Migration from File-Based UDL to Dynamic In-Memory Connection

---

## 1. Overview
This report details the specific code-level changes required within the LabVIEW application to support the new secure database connectivity model. It contrasts the legacy implementation (reading from a static `.udl` file) with the modern implementation (generating the connection string programmatically).

## 2. Legacy Implementation (Deprecated)

### 2.1 The "UDL" Approach
In the legacy system, the LabVIEW application relied on the Microsoft Data Link (`.udl`) file format.

*   **Mechanism:** The `DB Tools Open Connection.vi` was wired to a file path (e.g., `C:\Config\Database.udl`).
*   **Internal Behavior:** LabVIEW (via ADO) would open this file, read the stored OLE DB provider string, and attempt to connect.
*   **Security Flaw:** To support automated login, the `.udl` file often contained `Persist Security Info=True`, storing the SQL username and password in plain text on the hard drive.

### 2.2 Visual Representation (Legacy Code)

```text
[ File Path Constant: "C:\Config\DB.udl" ] 
         |
         v
[ DB Tools Open Connection.vi ]
         |
    (Connection Reference)
```

---

## 3. Modern Implementation (Secure)

### 3.1 The "In-Memory" Approach
The new system removes the file dependency entirely. We use the **Format Into String** function to build the connection string dynamically at runtime.

### 3.2 Construction Logic
The connection string is composed of fixed security parameters and variable configuration (Server/Database name).

**Template String:**
```text
Provider=MSOLEDBSQL19;Server=%s;Database=%s;Integrated Security=SSPI;Use Encryption for Data=Mandatory;
```

**LabVIEW Block Diagram Logic:**
1.  **Inputs:**
    *   `Server FQDN` (String Control/Global) -> e.g., `db-prod.factory.local`
    *   `Database Name` (String Control/Global) -> e.g., `ProductionDB`
2.  **Function:** `Format Into String`
3.  **Output:** The resulting string is wired directly to the `connection information` terminal of `DB Tools Open Connection.vi`.

### 3.3 Visual Representation (New Code)

```text
[ String Const: "Provider=MSOLEDBSQL19..." ] --+
                                               |
[ String Control: "Server FQDN" ] ------------>| [ Format Into String ] 
                                               |          |
[ String Control: "Database Name" ] ---------->|          |
                                                          |
                                                          v
                                            [ DB Tools Open Connection.vi ]
                                                          ^
                                                          |
                                          [ Enum: adPromptNever (4) ]
```

### 3.4 Critical Configuration Parameters

| Parameter | Value | LabVIEW Implementation Note |
| :--- | :--- | :--- |
| **Provider** | `MSOLEDBSQL19` | **Hardcoded.** Do not use a variable. This ensures we always use the TLS 1.2+ capable driver. |
| **Integrated Security** | `SSPI` | **Hardcoded.** Triggers Windows Auth. No User/Pass inputs are required on the VI. |
| **Prompt** | `adPromptNever` | **Enum Constant.** Wired to the `prompt` input of the Open Connection VI. Prevents the app from freezing if auth fails. |

---

## 4. Migration Steps for LabVIEW Developers

1.  **Open** the main database initialization VI.
2.  **Locate** the `DB Tools Open Connection.vi`.
3.  **Delete** the existing file path constant wired to the `connection information` input.
4.  **Place** a `Format Into String` function.
5.  **Create** the format string: `Provider=MSOLEDBSQL19;Server=%s;Database=%s;Integrated Security=SSPI;Use Encryption for Data=Mandatory;`
6.  **Wire** your Server Name and Database Name variables into the input terminals.
7.  **Wire** the resulting string to the `connection information` input.
8.  **Create** an Enum constant for the `prompt` input and select `adPromptNever` (Value: 4).
9.  **Save** and Compile.

---

## 5. Verification
To verify the LabVIEW change without running the full application:
1.  Create a small test VI.
2.  Implement the logic above.
3.  Run the VI.
4.  If successful, the error cluster will remain empty, and the connection reference will be valid.
5.  If it fails (e.g., Error -2147xxxx), check the error description against the troubleshooting guide (usually "Provider not found" or "SSPI context").
