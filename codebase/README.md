# PwnDoc-NG Codebase Documentation

Comprehensive documentation for understanding, deploying, and customizing PwnDoc-NG.

## Documents

| Document | Description |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | High-level system architecture, service breakdown, data flows, and design decisions |
| [CODE-MAP.md](CODE-MAP.md) | Complete directory structure, file purposes, data models, API endpoints, and authentication flow |
| [SECURITY.md](SECURITY.md) | Security analysis with 25 identified concerns (rated by severity), and prioritized AWS security requirements |
| [CONCERNS.md](CONCERNS.md) | Operational risks, scalability limitations, reliability issues, data integrity concerns, and monitoring requirements |
| [AWS-DEPLOYMENT.md](AWS-DEPLOYMENT.md) | Three AWS deployment options ($17-250/month), cost breakdowns, architecture diagrams, and deployment checklist |
| [DEPENDENCIES.md](DEPENDENCIES.md) | Complete dependency inventory for backend and frontend with version, purpose, and risk notes |
| [CUSTOMIZATION-GUIDE.md](CUSTOMIZATION-GUIDE.md) | How to customize roles, report templates, custom fields, languages, audit types, and settings |

## Quick Reference

- **Stack**: Vue 3 + Quasar (frontend) / Node.js + Express (backend) / MongoDB (database)
- **Key Feature**: Collaborative pentest report generation using DOCX templates
- **Services**: 4 containers (Frontend/Nginx, Backend/Express, MongoDB, LanguageTool)
- **Auth**: JWT cookies + optional TOTP 2FA
- **Cheapest AWS**: Single EC2 t3.small ~$17/month
- **Critical Security Items**: MongoDB auth, SSL certificates, JWT secret management (see SECURITY.md)
