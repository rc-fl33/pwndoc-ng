# PwnDoc-NG Architecture Overview

## What is PwnDoc-NG?

PwnDoc-NG is a **penetration testing report generation tool** built as a full-stack web application. It allows security professionals to collaboratively create, manage, and export penetration testing audit reports as DOCX documents using customizable templates.

## High-Level Architecture

```
                         ┌─────────────────────────┐
                         │     Internet / User      │
                         └───────────┬─────────────┘
                                     │ HTTPS :8443
                         ┌───────────▼─────────────┐
                         │   Nginx (Frontend)       │
                         │   - Serves Vue SPA       │
                         │   - Reverse proxy to API │
                         │   - SSL termination      │
                         └───┬─────┬─────┬─────┬───┘
                             │     │     │     │
              /api/*         │     │     │     │  /collab/*
              ───────────────┘     │     │     └──────────────
                                   │     │
                          /v2/*    │     │  /socket.io/*
                          ─────────┘     └────────────
                             │     │     │     │
                ┌────────────▼─┐ ┌─▼─────▼─┐ ┌▼─────────────────┐
                │ LanguageTool │ │ Backend  │ │ Hocuspocus Collab │
                │   :8010      │ │  :4242   │ │      :8440        │
                │ (Grammar)    │ │ Express  │ │  (WebSocket)      │
                └──────────────┘ │ + HTTPS  │ └───────────────────┘
                                 │+Socket.IO│          │
                                 └────┬─────┘          │
                                      │                │
                                 ┌────▼────────────────▼───┐
                                 │     MongoDB :27017       │
                                 │     Database: pwndoc     │
                                 │     (Persistent Volume)  │
                                 └──────────────────────────┘
```

## Service Breakdown

### 1. Frontend (Nginx + Vue 3 SPA)
- **Container**: `pwndoc-ng-frontend`
- **Port**: 8443 (HTTPS with self-signed SSL)
- **Technology**: Vue 3, Quasar Framework v2, Webpack
- **Role**: Serves the single-page application and acts as reverse proxy
- **Proxy routes**:
  - `/api/*` -> backend:4242 (REST API)
  - `/socket.io/*` -> backend:4242 (WebSocket for real-time presence)
  - `/collab/*` -> backend:8440 (Hocuspocus collaborative editing)
  - `/v2/*` -> languagetool:8010 (Grammar checking)

### 2. Backend (Node.js Express API)
- **Container**: `pwndoc-ng-backend`
- **Port**: 4242 (HTTPS)
- **Technology**: Node.js 20, Express 4, Mongoose 8
- **Role**: RESTful API server, report generation, authentication
- **Sub-services**:
  - Express HTTPS server (port 4242) - REST API + Socket.IO
  - Hocuspocus Server (port 8440) - Y.js collaborative editing WebSocket

### 3. MongoDB
- **Container**: `mongo-pwndoc-ng`
- **Port**: 27017 (bound to 127.0.0.1 only)
- **Image**: mongo:4
- **Role**: Primary data store for all application data
- **Volume**: `mongo-data` (Docker named volume)

### 4. LanguageTool
- **Container**: `pwndoc-ng-languagetool`
- **Image**: erikvl87/languagetool
- **Role**: Optional grammar/spell checking service (Java-based)
- **Resource note**: Java app configured with 512MB-2GB heap (`Java_Xms=512m`, `Java_Xmx=2g`)

## Networking

All services communicate over a single Docker bridge network named `backend`. Only the frontend (8443) and backend (4242) ports are exposed to the host. MongoDB is bound to 127.0.0.1 only.

## Data Flow

1. **User Authentication**: Browser -> Nginx -> Backend `/api/users/token` -> JWT issued as httpOnly cookie
2. **CRUD Operations**: Browser -> Nginx -> Backend `/api/*` -> MongoDB
3. **Real-time Presence**: Browser -> Nginx -> Backend Socket.IO (who's editing what)
4. **Collaborative Editing**: Browser -> Nginx -> Hocuspocus WebSocket (Y.js CRDT sync)
5. **Report Generation**: Backend reads audit from MongoDB -> Processes DOCX template with docxtemplater -> Returns generated document
6. **Grammar Check**: Frontend editor -> Nginx -> LanguageTool API -> Suggestions returned

## Key Design Decisions

- **Self-signed SSL everywhere**: Both backend Express server and Nginx use self-signed certificates in `ssl/` directories
- **Cookie-based JWT auth**: Tokens stored in httpOnly, secure, sameSite=strict cookies (not localStorage)
- **Monolithic backend**: Single Express app handles API, Socket.IO, and spawns Hocuspocus as a sub-service
- **Template-driven reports**: DOCX templates with angular-expressions and docxtemplater for report generation
- **No external auth**: Built-in user management with bcrypt passwords and optional TOTP 2FA
- **Collaborative editing**: Y.js/Hocuspocus for real-time collaborative document editing across audit sections
