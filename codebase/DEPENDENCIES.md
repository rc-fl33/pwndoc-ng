# PwnDoc-NG Dependency Inventory

## Backend Dependencies

### Runtime Dependencies (package.json)

| Package | Version | Purpose | Notes |
|---|---|---|---|
| `express` | ^4.18.2 | HTTP server framework | Core framework |
| `mongoose` | ^8.10.2 | MongoDB ODM | Database interaction layer |
| `jsonwebtoken` | ^9.0.0 | JWT token generation/verification | Authentication |
| `bcrypt` | ^5.1.0 | Password hashing | Native addon (needs build tools) |
| `body-parser` | ^1.20.2 | Request body parsing | JSON and URL-encoded |
| `cookie-parser` | ^1.4.6 | Cookie parsing middleware | For JWT cookie auth |
| `socket.io` | ^4.8.1 | WebSocket server | Real-time collaboration presence |
| `@hocuspocus/server` | ^2.15.2 | Y.js WebSocket server | Collaborative editing backend |
| `docxtemplater` | ^3.60.0 | DOCX template engine | Report generation core |
| `docxtemplater-image-module-pwndoc` | github fork | Image support for docxtemplater | Custom fork for PwnDoc |
| `pizzip` | ^3.1.4 | ZIP file handling | DOCX file manipulation |
| `angular-expressions` | ^1.4.3 | Expression parser | Template expressions in reports |
| `docx` | ^7.0.0 | DOCX generation | Additional DOCX utilities |
| `docx-templates` | ^4.11.1 | DOCX template processing | Alternative template engine |
| `htmlparser2` | ^8.0.2 | HTML parser | HTML to OOXML conversion |
| `image-size` | ^1.0.2 | Image dimension detection | Report image sizing |
| `node-cron` | ^3.0.2 | Cron job scheduler | Auto-deletion of old audits |
| `otpauth` | ^7.0.6 | TOTP/HOTP implementation | Two-factor authentication |
| `qrcode` | ^1.5.1 | QR code generation | TOTP enrollment QR codes |
| `winston` | ^2.3.1 | Logging | **Outdated - v2, current is v3** |
| `js-yaml` | ^3.13.1 | YAML parser | Data import/export |
| `lodash` | ^4.17.21 | Utility library | Object/array manipulation |
| `swagger-ui-express` | ^4.6.0 | API documentation UI | Swagger/OpenAPI docs |
| `xml` | ^1.0.1 | XML builder | Chart XML generation |
| `full-icu` | ^1.5.0 | ICU data for i18n | Locale-aware string operations |
| `http` | 0.0.0 | Node built-in | Redundant - can be removed |

### Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| `jest` | ^29.5.0 | Testing framework |
| `supertest` | ^6.3.3 | HTTP testing |
| `nodemon` | ^2.0.22 | Dev server auto-reload |
| `swagger-autogen` | ^2.23.1 | Auto-generate Swagger docs |
| `@babel/core` | ^7.21.4 | JavaScript transpilation |
| `@babel/preset-env` | ^7.10.2 | Babel environment preset |

## Frontend Dependencies

### Runtime Dependencies

| Package | Version | Purpose | Notes |
|---|---|---|---|
| `vue` | ^3.5.13 | UI framework | Vue 3 with Composition API |
| `quasar` | ^2.17.7 | UI component library | Material Design components |
| `@quasar/extras` | ^1.3.3 | Quasar icon/font packs | Material icons, etc. |
| `axios` | ^1.7.9 | HTTP client | API communication |
| `socket.io-client` | ^4.8.1 | WebSocket client | Real-time presence updates |
| `vue-i18n` | ^9.14.2 | Internationalization | Multi-language UI (en, fr, de, zh) |
| `vue-router` | (via Quasar) | Client-side routing | SPA navigation |
| **Rich Text Editor (TipTap)** | | | |
| `@tiptap/core` | ^2.11.5 | Editor core | Replaces ProseMirror directly |
| `@tiptap/starter-kit` | ^2.11.5 | Basic editor features | Bold, italic, lists, etc. |
| `@tiptap/vue-3` | ^2.11.5 | Vue 3 integration | |
| `@tiptap/extension-*` | ^2.11.5 | Editor extensions | Tables, images, links, code blocks, collaboration |
| `yjs` | ^13.6.23 | CRDT for collaboration | Conflict-free collaborative editing |
| `@hocuspocus/provider` | ^2.15.2 | Hocuspocus client | WebSocket Y.js sync |
| **Utilities** | | | |
| `lodash` | ^4.17.15 | Utility library | Duplicated from backend |
| `js-yaml` | ^3.13.1 | YAML parser | Import/export |
| `jwt-decode` | ^2.2.0 | JWT decoding (client-side) | Token inspection only |
| `diff` | ^4.0.2 | Text diffing | Vulnerability change tracking |
| `dexie` | ^4.0.11 | IndexedDB wrapper | Client-side caching |
| `highlight.js` | ^11.11.1 | Syntax highlighting | Code blocks in editor |
| `lowlight` | ^3.3.0 | highlight.js for TipTap | Code block integration |
| `vuedraggable` | ^4.1.0 | Drag-and-drop | Finding reordering |
| `vue-sticky-directive` | ^0.0.10 | Sticky positioning | UI sticky elements |
| `vue3-sticky-directive` | ^0.0.2 | Vue 3 sticky | Updated for Vue 3 |
| `vue-lodash` | ^2.1.2 | Lodash Vue plugin | Global lodash access |
| `core-js` | ^3.9.0 | Polyfills | Browser compatibility |
| `autoprefixer` | ^10.4.20 | CSS autoprefixing | Build-time CSS processing |

### Dev Dependencies

| Package | Version | Purpose | Notes |
|---|---|---|---|
| `@quasar/app-webpack` | ^3.15.1 | Quasar build tool | Webpack-based builds |
| `@quasar/cli` | ^2.4.1 | Quasar CLI | Dev server and build commands |
| `stylus` | ^0.64.0 | CSS preprocessor | Quasar styling |
| `stylus-loader` | ^8.1.1 | Webpack stylus loader | Build integration |
| `electron` | ^34.2.0 | Desktop app framework | **Unused - remove** |
| `electron-debug` | ^1.5.0 | Electron debugging | **Unused - remove** |
| `electron-devtools-installer` | ^2.2.4 | Electron devtools | **Unused - remove** |
| `devtron` | ^1.4.0 | Electron devtools | **Unused - remove** |
| `buffer` | ^6.0.3 | Buffer polyfill | Webpack 5 compatibility |
| `strip-ansi` | ^3.0.1 | ANSI strip utility | Build tooling |
| `uuid` | ^11.0.5 | UUID generation | |

## Infrastructure Dependencies

| Component | Version/Image | Purpose |
|---|---|---|
| Node.js | 20.0.0-alpine3.16 | Backend runtime |
| Node.js | 19.8.1-alpine3.16 | Frontend build stage |
| Nginx | stable-alpine | Frontend serving + reverse proxy |
| MongoDB | 4 | Primary database |
| LanguageTool | erikvl87/languagetool (latest) | Grammar checking (Java-based) |

## Dependency Risks

1. **`docxtemplater-image-module-pwndoc`** - GitHub fork dependency. If the fork is removed or becomes incompatible, report generation breaks. Consider vendoring.
2. **`winston` v2** - End of life. Upgrade to v3 for structured logging and modern transport support.
3. **`js-yaml` v3** - Known prototype pollution vulnerability in older versions. Upgrade to v4.
4. **MongoDB 4** - End of life since April 2024. Upgrade to MongoDB 6 or 7.
5. **Electron dependencies** - Installed but unused. Remove to reduce `npm install` time and attack surface.
6. **Node.js 20.0.0** - Pinned to specific patch. Should use `node:20-alpine` for security patches.
7. **`http` 0.0.0** - Built-in Node module listed as dependency. Remove from package.json.
