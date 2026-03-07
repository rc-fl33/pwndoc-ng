# PwnDoc-NG Code Map

## Repository Structure

```
pwndoc-ng/
├── docker-compose.yml              # Production compose (4 services)
├── docker-compose-dev.yml          # Development compose override
├── run_tests.sh                    # Test runner script
├── .github/
│   ├── workflows/main.yml          # CI: runs integration tests on push/PR to master
│   └── dependabot.yml              # Dependency update automation
│
├── backend/                        # Node.js Express API
│   ├── Dockerfile                  # Production: node:20-alpine, npm start
│   ├── Dockerfile.dev              # Development: nodemon for hot reload
│   ├── Dockerfile.test             # Test runner image
│   ├── docker-compose.dev.yml      # Backend-only dev compose
│   ├── docker-compose.test.yml     # Test compose (with test MongoDB)
│   ├── package.json                # Dependencies and scripts
│   ├── swagger.js                  # Swagger auto-generation script
│   ├── ssl/                        # Self-signed certificates for HTTPS
│   │   ├── server.key
│   │   └── server.cert
│   ├── report-templates/           # DOCX report templates (mounted volume)
│   ├── tests/                      # Jest integration tests
│   │   └── index.test.js
│   └── src/
│       ├── app.js                  # *** MAIN ENTRY POINT ***
│       ├── config/
│       │   ├── config.json         # DB connection, ports, JWT secrets (auto-generated)
│       │   ├── roles.json          # Custom role definitions (optional)
│       │   └── swagger-output.json # Generated API documentation
│       ├── lib/
│       │   ├── auth.js             # JWT auth, ACL role system, permission middleware
│       │   ├── report-generator.js # DOCX report generation engine (core feature)
│       │   ├── custom-generator.js # Custom report content generation
│       │   ├── chart-generator.js  # OOXML chart generation for reports
│       │   ├── html2ooxml.js       # HTML to Office Open XML converter
│       │   ├── cvsscalc31.js       # CVSS v3.1 score calculator
│       │   ├── cron.js             # Scheduled jobs (auto-delete old audits)
│       │   ├── httpResponse.js     # Standardized HTTP response helpers
│       │   ├── passwordpolicy.js   # Password strength validation
│       │   └── utils.js            # Utility functions
│       ├── models/                 # Mongoose schemas and data access
│       │   ├── audit.js            # *** CORE MODEL *** - Audits with findings, sections, scope
│       │   ├── user.js             # Users with auth, TOTP, refresh tokens
│       │   ├── vulnerability.js    # Vulnerability database entries
│       │   ├── vulnerability-update.js  # Vulnerability change tracking
│       │   ├── vulnerability-type.js    # Vulnerability type definitions
│       │   ├── vulnerability-category.js # Vulnerability categories with sort options
│       │   ├── client.js           # Client contacts for audits
│       │   ├── company.js          # Company entities
│       │   ├── template.js         # Report template metadata
│       │   ├── language.js         # Supported languages
│       │   ├── audit-type.js       # Audit type definitions (sections, templates)
│       │   ├── custom-section.js   # Custom section definitions
│       │   ├── custom-field.js     # Custom field definitions
│       │   ├── image.js            # Uploaded images (stored in MongoDB)
│       │   └── settings.js         # Application settings (colors, reviews, automation)
│       ├── routes/                 # Express route handlers
│       │   ├── audit.js            # /api/audits/* - CRUD, findings, sections, report gen
│       │   ├── user.js             # /api/users/* - Auth, TOTP, CRUD, profile
│       │   ├── vulnerability.js    # /api/vulnerabilities/* - Vuln database management
│       │   ├── client.js           # /api/clients/*
│       │   ├── company.js          # /api/companies/*
│       │   ├── template.js         # /api/templates/* - Upload/manage report templates
│       │   ├── data.js             # /api/data/* - Import/export, languages, types, categories
│       │   ├── image.js            # /api/images/* - Image upload/retrieval
│       │   └── settings.js         # /api/settings/* - App configuration
│       └── translate/
│           └── index.js            # Translation/i18n for report generation
│
└── frontend/                       # Vue 3 + Quasar SPA
    ├── Dockerfile                  # Multi-stage: build Vue -> serve with Nginx
    ├── Dockerfile.dev              # Dev mode with hot reload
    ├── docker-compose.dev.yml      # Frontend-only dev compose
    ├── package.json                # Dependencies and scripts
    ├── quasar.config.js            # Quasar framework configuration
    ├── ssl/                        # SSL certs for Nginx HTTPS
    ├── .docker/
    │   └── nginx.conf              # Nginx config: SSL, reverse proxy to backend
    └── src/
        ├── App.vue                 # Root Vue component
        ├── boot/                   # Quasar boot files (plugins)
        │   ├── auth.js             # Auth guard, token refresh interceptor
        │   ├── axios.js            # Axios HTTP client configuration
        │   ├── socketio.js         # Socket.IO client setup
        │   ├── i18n.js             # Internationalization setup
        │   ├── settings.js         # Global settings loader
        │   ├── darkmode.js         # Dark mode toggle
        │   ├── lodash.js           # Lodash global registration
        │   └── sticky.js           # Sticky directive
        ├── router/
        │   ├── index.js            # Vue Router setup with auth guard
        │   └── routes.js           # Route definitions (all app routes)
        ├── services/               # API service layer (Axios wrappers)
        │   ├── audit.js            # Audit API calls
        │   ├── vulnerability.js    # Vulnerability API calls
        │   ├── user.js             # User/auth API calls
        │   ├── client.js           # Client API calls
        │   ├── company.js          # Company API calls
        │   ├── collaborator.js     # Collaborator API calls
        │   ├── reviewer.js         # Reviewer API calls
        │   ├── template.js         # Template API calls
        │   ├── image.js            # Image upload API calls
        │   ├── data.js             # Data import/export API calls
        │   ├── settings.js         # Settings API calls
        │   ├── autoCorrection.js   # LanguageTool integration
        │   └── utils.js            # Shared utilities
        ├── components/             # Reusable Vue components
        │   ├── editor.vue          # TipTap rich text editor (core)
        │   ├── cvsscalculator.vue  # CVSS v3.1 calculator widget
        │   ├── custom-fields.vue   # Dynamic custom field renderer
        │   ├── uploadImage.vue     # Image upload component
        │   ├── breadcrumb.vue      # Navigation breadcrumbs
        │   ├── audit-state-icon.vue # Audit state indicator
        │   ├── language-selector.vue # Language picker
        │   ├── textarea-array.vue  # Dynamic array input
        │   ├── editor-image.js     # TipTap image extension
        │   ├── editor-caption.js   # TipTap caption extension
        │   ├── figure.js           # TipTap figure extension
        │   ├── internal-link.js    # TipTap internal link extension
        │   ├── languagetool.js     # TipTap LanguageTool extension
        │   └── CodeBlockComponent.vue # Code block with syntax highlighting
        ├── pages/                  # Page-level Vue components
        │   ├── login.vue           # Login page
        │   ├── 403.vue             # Forbidden page
        │   ├── 404.vue             # Not found page
        │   ├── audits/             # Audit pages
        │   │   ├── list/           # Audit listing
        │   │   └── edit/           # Audit editor
        │   │       ├── general/    # General info tab
        │   │       ├── network/    # Network/scope tab
        │   │       ├── findings/   # Findings management
        │   │       │   ├── add/    # Add finding
        │   │       │   └── edit/   # Edit finding
        │   │       └── sections/   # Custom sections editor
        │   ├── data/               # Data management pages
        │   │   ├── collaborators/  # User management
        │   │   ├── companies/      # Company management
        │   │   ├── clients/        # Client management
        │   │   ├── templates/      # Template management
        │   │   ├── dump/           # Import/export
        │   │   └── custom/         # Custom fields/sections/types
        │   ├── vulnerabilities/    # Vulnerability database
        │   ├── profile/            # User profile
        │   └── settings/           # Application settings
        ├── i18n/                   # Translation files
        │   ├── en-US/
        │   ├── fr-FR/
        │   ├── de-DE/
        │   └── zh-CN/
        └── layouts/
            └── home.vue            # Main application layout with sidebar
```

## Key Data Models and Relationships

```
User ─────────┬── creates ──── Audit
              ├── collaborates ─┘  │
              └── reviews ─────────┘
                                   │
Audit ────────┬── has many ──── Finding
              ├── has many ──── Section
              ├── belongs to ── Company
              ├── belongs to ── Client
              ├── uses ──────── Template
              ├── has ───────── Scope (with Hosts/Services)
              └── has ───────── CustomField values

Vulnerability ── referenced by ── Finding (manual copy, not linked)
VulnerabilityCategory ── groups ── Vulnerability
VulnerabilityType ── classifies ── Vulnerability

AuditType ── defines ── which Sections an audit has
           └── maps ── Language -> Template

CustomField ── defines ── extra fields for audits/findings/sections
CustomSection ── defines ── available section types
```

## API Endpoints Summary

| Route Group | Base Path | Auth Required | Key Operations |
|---|---|---|---|
| Users | `/api/users` | Varies | Login, register, TOTP, profile, CRUD |
| Audits | `/api/audits` | Yes | CRUD, findings, sections, report generation, cloning |
| Vulnerabilities | `/api/vulnerabilities` | Yes | CRUD, merge, import/export |
| Clients | `/api/clients` | Yes | CRUD |
| Companies | `/api/companies` | Yes | CRUD |
| Templates | `/api/templates` | Yes | Upload, download, delete DOCX templates |
| Data | `/api/data` | Yes (admin) | Languages, audit types, vuln types/categories, custom fields/sections, import/export |
| Images | `/api/images` | Yes | Upload, retrieve |
| Settings | `/api/settings` | Yes (admin) | Report colors, review config, automation |

## Authentication Flow

1. User POSTs credentials to `/api/users/token`
2. Backend validates against bcrypt hash, optionally checks TOTP
3. Issues JWT access token (15 min) + refresh token (7 days) as httpOnly cookies
4. Frontend axios interceptor auto-refreshes via `/api/users/refreshtoken`
5. ACL middleware checks role permissions on every API request
6. Roles: `user` (limited permissions) and `admin` (wildcard `*`)
7. Custom roles can be defined in `config/roles.json` with inheritance

## Report Generation Pipeline

1. User clicks "Generate Report" in frontend
2. Backend loads audit data from MongoDB with all populated references
3. Reads DOCX template from `report-templates/` directory
4. Processes template using docxtemplater with angular-expressions
5. Injects: audit data, findings (sorted by CVSS/custom), CVSS calculations, charts, images
6. Converts HTML content (from rich text editor) to OOXML
7. Generates pie/bar charts as embedded OOXML
8. Returns completed DOCX file for download
