# PwnDoc-NG Customization Guide

## Overview

This guide covers key areas for customizing PwnDoc-NG to fit your team's workflow.

---

## 1. Custom Roles and Permissions

### Built-in Roles
- **`user`**: Can create/read/update/delete audits, clients, companies. Can read vulnerabilities, templates, users.
- **`admin`**: Full access (wildcard `*` permission).

### Adding Custom Roles

Create/edit `backend/src/config/roles.json`:

```json
{
    "reviewer": {
        "allows": [
            "audits:read",
            "audits:review",
            "vulnerabilities:read",
            "templates:read",
            "users:read",
            "roles:read",
            "languages:read",
            "audit-types:read",
            "vulnerability-types:read",
            "vulnerability-categories:read",
            "sections:read",
            "custom-fields:read",
            "settings:read-public"
        ]
    },
    "lead": {
        "allows": [
            "vulnerabilities:create",
            "vulnerabilities:update",
            "vulnerabilities:delete"
        ],
        "inherits": ["user"]
    }
}
```

### Available Permissions
```
audits:create, audits:read, audits:update, audits:delete
clients:create, clients:read, clients:update, clients:delete
companies:create, companies:read, companies:update, companies:delete
vulnerabilities:read, vulnerabilities:create, vulnerabilities:update, vulnerabilities:delete
vulnerability-updates:create
templates:read, templates:create, templates:update, templates:delete
users:read, users:create, users:update, users:read-all
images:create, images:read
languages:read, languages:create, languages:update, languages:delete
audit-types:read, audit-types:create, audit-types:update, audit-types:delete
vulnerability-types:read, vulnerability-types:create, vulnerability-types:update, vulnerability-types:delete
vulnerability-categories:read, vulnerability-categories:create, vulnerability-categories:update, vulnerability-categories:delete
sections:read, sections:create, sections:update, sections:delete
custom-fields:read, custom-fields:create, custom-fields:update, custom-fields:delete
roles:read
settings:read, settings:read-public, settings:update
```

---

## 2. Report Templates

### Template Location
Templates are DOCX files stored in `backend/report-templates/` (mounted as a Docker volume).

### Template Syntax
PwnDoc-NG uses [docxtemplater](https://docxtemplater.com/) with [angular-expressions](https://docxtemplater.com/docs/angular-parse/). Available variables in templates:

#### Audit Data
```
{name}                    - Audit name
{auditType}               - Audit type
{date}                    - Audit date
{date_start}              - Start date
{date_end}                - End date
{language}                - Audit language
{state}                   - Audit state (EDIT/REVIEW/APPROVED)
```

#### Company/Client
```
{company.name}            - Company name
{company.logo}            - Company logo (image)
{client.email}            - Client email
{client.firstname}        - Client first name
{client.lastname}         - Client last name
```

#### People
```
{creator.username}        - Audit creator
{creator.firstname}
{creator.lastname}
{#collaborators}{username}{/collaborators}
{#reviewers}{username}{/reviewers}
```

#### Findings
```
{#findings}
  {title}                 - Finding title
  {vulnType}              - Vulnerability type
  {description}           - Description (HTML -> OOXML)
  {observation}           - Observation
  {remediation}           - Remediation
  {cvssv3}                - CVSS vector string
  {cvssScore}             - Calculated CVSS score
  {cvssSeverity}          - Severity label
  {priority}              - Priority (1-4)
  {remediationComplexity} - Complexity (1-3)
  {references}            - References list
  {scope}                 - Finding scope
  {category}              - Category
  {identifier}            - Auto-incremented ID
  {#customFields}{label}: {text}{/customFields}
{/findings}
```

#### Conditional Logic
```
{#findings | cvssSeverity == "Critical"}
  ... critical findings only ...
{/}

{findings.length}         - Total finding count
{#findings | sortBy:'cvssScore':'desc'}
  ... sorted findings ...
{/}
```

### Adding a New Template
1. Create your DOCX file with the variables above
2. Place it in `backend/report-templates/`
3. Go to Data > Templates in the UI and upload/register it
4. Associate it with an audit type for automatic selection

---

## 3. Custom Fields

Custom fields can be added to audits, findings, and sections via the UI under **Data > Custom Data**.

### Field Types
- **Text** - Single line text
- **Multi-line text** - Rich text (HTML)
- **Checkbox** - Boolean
- **Select** - Dropdown
- **Radio** - Radio buttons
- **Date** - Date picker
- **Space** - UI spacer

### Display Locations
- **General** - Appears on audit general information tab
- **Section** - Appears within a specific section
- **Finding** - Appears on finding edit form

Custom fields are available in report templates via `{#customFields}` blocks.

---

## 4. Languages and Localization

### Adding a UI Language
1. Create a new translation file in `frontend/src/i18n/<locale>/index.js`
2. Copy structure from `en-US/index.js`
3. Register in `frontend/src/i18n/index.js`
4. Add to Quasar config

### Adding a Report Language
Use the UI under **Data > Custom Data > Languages** to add supported report languages. This affects:
- Which languages are available when creating audits
- Which template to use per language/audit type
- Default text for custom fields per language

---

## 5. Audit Types and Sections

### Audit Types
Define what sections are available in an audit. Configure via **Data > Custom Data > Audit Types**.

Each audit type maps:
- A set of sections (from Custom Sections)
- A default template per language

### Custom Sections
Define reusable section types (e.g., "Executive Summary", "Methodology", "Scope"). Each section can have custom fields attached.

---

## 6. Vulnerability Database

The vulnerability database serves as a reusable knowledge base. When adding findings to an audit, users can search and import from this database.

### Import/Export
- Export: **Data > Dump > Export** (YAML format)
- Import: **Data > Dump > Import** (YAML format)

### Categories
Vulnerability categories control:
- Grouping in the UI
- Sort order in reports (configurable per category)
- Default sort field and direction

---

## 7. Application Settings

Accessible via **Settings** page (admin only):

### Report Settings
- CVSS severity colors (None/Low/Medium/High/Critical)
- Remediation complexity colors
- Priority colors
- Figure captions list
- Image border settings
- CVSS temporal/environmental score extension

### Review Settings
- Enable/disable mandatory review workflow
- Minimum number of reviewers for approval
- Auto-remove approvals on audit update

### Danger Zone
- Enable auto-deletion of audits older than N days

---

## 8. Password Policy

Edit `backend/src/lib/passwordpolicy.js` to modify password requirements:

```javascript
// Current: 8+ chars, uppercase, lowercase, digit
var regExp = /(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}/;

// Stricter example: 12+ chars, uppercase, lowercase, digit, special char
var regExp = /(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*]).{12,}/;
```

---

## 9. Docker Configuration

### Environment Variables
| Variable | Default | Description |
|---|---|---|
| `NODE_ENV` | `prod` | Environment (dev/prod/test) |
| `COLLAB_WEBSOCKET_PORT` | `8440` | Hocuspocus WebSocket port |
| `Java_Xms` | `512m` | LanguageTool min heap |
| `Java_Xmx` | `2g` | LanguageTool max heap |

### Volumes
| Volume | Path | Purpose |
|---|---|---|
| `mongo-data` | `/data/db` | MongoDB persistent data |
| `report-templates` | `/app/report-templates` | DOCX report templates |
| `config` | `/app/src/config` | Backend configuration |

### Ports
| Port | Service | Protocol |
|---|---|---|
| 8443 | Frontend (Nginx) | HTTPS |
| 4242 | Backend API | HTTPS |
| 8440 | Hocuspocus (Collab) | WebSocket |
| 27017 | MongoDB | TCP (localhost only) |
