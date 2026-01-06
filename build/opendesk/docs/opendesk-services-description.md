# OpenDesk Pods and Services

This document provides a detailed breakdown of the Kubernetes pods running in the `opendesk` namespace. The pods are categorized by their primary function, offering insight into the microservice architecture of the platform.

---

## Service Dependencies and Relationships

### Core Infrastructure Dependencies (Foundation Layer)

These components must be deployed first as they provide foundational services required by all other applications:

```
Layer 1 (Foundation - Deploy First):
Database for UMS, OX, OpenProject, Matrix
Database for Nextcloud, XWiki
Cache and session storage
Object storage (S3-compatible)
Application-level caching
Antivirus scanning service
```

### Identity Management Dependencies (Layer 2)

UMS (Nubus) components depend on core infrastructure and must be initialized before applications:

```
Layer 2 (Identity - Deploy Second):
Depends on: postgresql-0
Message bus (independent)
Depends on: postgresql-0, ums-ldap-server-primary-0
Bootstrap Job - Depends on: ums-keycloak-0
Depends on: ums-keycloak-0
Depends on: ums-provisioning-nats-0
Depends on: ums-provisioning-nats-0
Depends on: ums-ldap-server-primary-0, ums-provisioning-nats-0
Depends on: ums-portal-server-*
Depends on: ums-keycloak-0
```

**Bootstrap Jobs:**
- `ums-keycloak-bootstrap-bootstrap-1-*`: Kubernetes Job that runs once during initial deployment to configure Keycloak with default realms, clients, and settings

### Application Layer Dependencies (Layer 3)

Applications depend on both infrastructure and identity management:

```
Layer 3 (Applications - Deploy Third):

Open-Xchange Mail Suite:
Depends on: ums-provisioning-nats-0, postgresql-0
Depends on: postgresql-0, redis-master-0, ums-keycloak-0
Depends on: dovecot-*, ums-ldap-server-primary-0
Depends on: postgresql-0, ums-ldap-server-primary-0
Independent converter service

Matrix Chat:
Depends on: postgresql-0, ums-keycloak-0
Depends on: opendesk-synapse-0, ums-keycloak-0, intercom-service-*
Depends on: opendesk-synapse-0

Jitsi Video Conferencing:
XMPP server (base dependency)
Depends on: jitsi-prosody-0
Depends on: jitsi-prosody-0
Depends on: jitsi-prosody-0, jitsi-web-*
Depends on: jitsi-prosody-0, ums-keycloak-0

Nextcloud File Storage:
Depends on: mariadb-0, redis-master-0, minio-*, ums-ldap-server-primary-0, ums-keycloak-0
Depends on: opendesk-nextcloud-aio-*

OpenProject:
Depends on: postgresql-0, ums-ldap-server-primary-0, ums-keycloak-0, opendesk-nextcloud-aio-*
Depends on: openproject-web-*, redis-master-0

Other Applications:
Depends on: opendesk-nextcloud-aio-*, ums-keycloak-0
Depends on: ums-keycloak-0, ums-portal-server-*
```

### Supporting Services (Layer 4)

These services provide auxiliary functionality and can be deployed last:

```
Layer 4 (Supporting Services - Deploy Last):
Depends on: minio-*, ums-keycloak-0
Independent (serves static assets)
Independent (serves .well-known endpoints)
```

---

## Detailed Service Descriptions

### Core Infrastructure and Shared Services

These pods are the foundational components of the platform, providing essential services that the other applications rely on.

*   **`mariadb-0`**: A persistent pod running the MariaDB database. It serves as a primary data store for applications that require a relational database.
   - **Used by**: Nextcloud, XWiki
   - **Dependencies**: None (foundation layer)

*   **`postgresql-0`**: A persistent pod running the PostgreSQL database. This is another key data store for various OpenDesk applications, particularly those within the Open-Xchange and Identity Management stacks.
   - **Used by**: UMS/Keycloak, Open-Xchange, OpenProject, Matrix Synapse, Dovecot
   - **Dependencies**: None (foundation layer)

*   **`redis-master-0`**: The pod for the Redis in-memory data store. It is used for high-speed data caching, managing job queues, and storing temporary application-level data to improve performance.
   - **Used by**: Open-Xchange, OpenProject, Nextcloud
   - **Dependencies**: None (foundation layer)

*   **`minio-9f575c949-hdd8n`**: Runs the MinIO object storage server, which provides an S3-compatible API. This pod is used for storing unstructured data like user files, backups, and attachments.
   - **Used by**: All applications requiring object storage
   - **Dependencies**: None (foundation layer)

*   **`nubus-nginx-s3-gateway-*`**: An NGINX pod that acts as a secure gateway, providing controlled access to the MinIO object storage. It handles traffic routing and authentication for S3-related requests.
   - **Dependencies**: minio-*, ums-keycloak-0

*   **`memcached-664d78586f-pxfnw`**: A caching service that stores small pieces of data in memory to reduce database load and accelerate data retrieval for applications.
   - **Used by**: Multiple applications for performance optimization
   - **Dependencies**: None (foundation layer)

*   **`clamav-simple-0`**: This pod runs the ClamAV antivirus daemon. It is integrated into mail and file storage services to scan for and detect malicious software in user content.
   - **Used by**: Postfix (mail), file storage services
   - **Dependencies**: None (foundation layer)

*   **`intercom-service-*`**: A central service for inter-application communication, enabling the various microservices within OpenDesk to send messages and trigger events for each other. Provides silent login, token exchange, and central navigation.
   - **Used by**: OX AppSuite Frontend, Element, Portal
   - **Dependencies**: ums-keycloak-0, ums-portal-server-*

*   **`opendesk-static-files-*`**: A web server pod dedicated to serving static assets such as CSS stylesheets, JavaScript files, images, and fonts for all the web-based applications, improving page load times.
   - **Dependencies**: None (independent)

*   **`opendesk-well-known-*`**: Handles standard `.well-known` endpoints as specified by various RFCs. This is crucial for services like email auto-discovery and other web service configurations.
   - **Dependencies**: None (independent)

### Identity and Access Management (Ums/Nubus)

This group of pods forms the core of OpenDesk's identity management system, providing authentication, authorization, and user provisioning. **This is the second layer that must be fully operational before applications can start.**

*   **`ums-ldap-server-primary-0`**: The OpenLDAP server, which is the authoritative source for all user and group data within the platform.
   - **Dependencies**: postgresql-0
   - **Used by**: All applications requiring user/group information

*   **`ums-provisioning-nats-0`**: The NATS message bus, a high-performance messaging system that serves as the communication backbone for all provisioning services.
   - **Dependencies**: None
   - **Used by**: All provisioning services, ox-connector

*   **`ums-keycloak-0`**: The main Keycloak server, which acts as the central identity provider. It manages user sessions, single sign-on (SSO), and authentication for all integrated applications using OpenID Connect (OIDC).
   - **Dependencies**: postgresql-0, ums-ldap-server-primary-0
   - **Used by**: All applications for authentication (OIDC)

*   **`ums-keycloak-bootstrap-bootstrap-1-*`**: A Kubernetes `Job` that runs once during the initial deployment to perform the one-time configuration and setup of Keycloak.
   - **Job Type**: Bootstrap/Initialization
   - **Dependencies**: ums-keycloak-0
   - **Runs**: Once during initial deployment
   - **Purpose**: Configure default realms, clients, identity federation

*   **`ums-keycloak-extensions-handler-*`**: A handler that processes custom extensions and functionality for Keycloak, such as custom login flows or user synchronization logic.
   - **Dependencies**: ums-keycloak-0

*   **`ums-provisioning-api-*`**, **`ums-provisioning-dispatcher-*`**, **`ums-provisioning-udm-listener-*`**: This is a set of services that manage the provisioning lifecycle. They listen for changes in the identity system and dispatch tasks to create, update, or delete users and groups across different applications.
   - **Dependencies**: ums-provisioning-nats-0, ums-ldap-server-primary-0 (listener)
   - **Purpose**: Synchronize user/group changes to all integrated applications

*   **`ums-portal-frontend-*`** and **`ums-portal-server-*`**: The user portal where users log in and get redirected to the appropriate application. The `frontend` is the UI, and the `server` is the backend API that serves it.
   - **Dependencies**: ums-keycloak-0 (server), ums-portal-server-* (frontend)
   - **Purpose**: Main entry point for users

### Open-Xchange (OX) Mail and Groupware

These pods collectively run the Open-Xchange suite, providing mail, calendar, and contact management services.

*   **`ox-connector-0`**: A critical provisioning component that listens to the message bus and synchronizes user data from the identity management system to the Open-Xchange application. The pod processes tasks like creating mailboxes when new users are added.
   - **Dependencies**: ums-provisioning-nats-0, postgresql-0
   - **Purpose**: User provisioning bridge between UMS and OX

*   **`open-xchange-core-*`**: This is a collection of pods that handle various functions of the Open-Xchange application. This includes the main user interface (`ui`), the backend middleware (`mw-default`), and auxiliary services for document and image conversion.
   - **Dependencies**: postgresql-0, redis-master-0, ums-keycloak-0
   - **Integrations**: Nextcloud (filepicker), Element (videoconferences), IntercomService

*   **`postfix-*-prbmc`** and **`postfix-ox-*`**: The Postfix mail transfer agents (MTAs) that are responsible for sending and receiving emails.
   - **Dependencies**: dovecot-*, ums-ldap-server-primary-0, clamav-simple-0

*   **`dovecot-*`**: The Dovecot IMAP/POP3 server that allows email clients to retrieve messages from user mailboxes.
   - **Dependencies**: postgresql-0, ums-ldap-server-primary-0, ums-keycloak-0

*   **`open-xchange-gotenberg-*`**: A pod running Gotenberg, a service used to convert documents into other formats, such as PDFs.
   - **Dependencies**: None (independent converter)

### Jitsi (Video Conferencing)

This group of pods provides the self-hosted video conferencing solution for the platform.

*   **`jitsi-prosody-0`**: The Prosody XMPP server, used for signaling between Jitsi components. **This is the base dependency for all other Jitsi services.**
   - **Dependencies**: None (Jitsi base)
   - **Used by**: All Jitsi components

*   **`jitsi-jicofo-*`**: Jitsi Conference Focus, which manages the conference logic.
   - **Dependencies**: jitsi-prosody-0

*   **`jitsi-jvb-*`**: Jitsi Videobridge, the pod that handles the core media routing.
   - **Dependencies**: jitsi-prosody-0

*   **`jitsi-jibri-*`**: Jibri (Jitsi Browser Recorder), a service that records or live-streams Jitsi conferences.
   - **Dependencies**: jitsi-prosody-0, jitsi-web-*

*   **`jitsi-web-*`**: The web server that hosts the user-facing web interface for Jitsi Meet.
   - **Dependencies**: jitsi-prosody-0, ums-keycloak-0

### Matrix (Chat and Collaboration)

These pods are responsible for the federated chat and team collaboration features.

*   **`opendesk-synapse-0`**: This pod runs the Matrix Synapse homeserver, which is the core server for the Matrix chat protocol.
   - **Dependencies**: postgresql-0, ums-keycloak-0
   - **Purpose**: Matrix homeserver for chat federation

*   **`opendesk-element-*`**: Serves the Element web client, a popular and feature-rich user interface for accessing the Matrix chat rooms.
   - **Dependencies**: opendesk-synapse-0, ums-keycloak-0, intercom-service-*
   - **Integrations**: IntercomService for silent login and navigation

*   **`matrix-*`**: A set of pods for various Matrix widgets and bots that extend the platform's functionality. This includes widgets for whiteboards (`neoboard`), polls (`neochoice`), and date scheduling (`neodatefix`).
   - **Dependencies**: opendesk-synapse-0

### Other Applications

These pods provide additional collaboration and productivity tools within the OpenDesk ecosystem.

*   **`opendesk-nextcloud-aio-*`**: Runs the Nextcloud All-in-One (AIO) instance for file hosting and sharing.
   - **Dependencies**: mariadb-0, redis-master-0, minio-*, ums-ldap-server-primary-0, ums-keycloak-0
   - **Used by**: OpenProject (file store), Collabora, CryptPad, OX AppSuite (filepicker)

*   **`collabora-*`**: Runs Collabora Online, a web-based office suite that allows users to collaboratively edit documents.
   - **Dependencies**: opendesk-nextcloud-aio-*
   - **Integration**: Nextcloud for document editing

*   **`openproject-web-*`** and **`openproject-worker-default-*`**: The `web` pod serves the OpenProject application for project management, while the `worker` pod handles asynchronous tasks, such as sending email notifications.
   - **Dependencies**: postgresql-0, ums-ldap-server-primary-0, ums-keycloak-0, opendesk-nextcloud-aio-* (file storage)
   - **Bootstrap**: Uses `opendesk-openproject-bootstrap` job to configure Nextcloud integration

*   **`cryptpad-*`**: A pod running CryptPad, a privacy-focused collaboration suite for secure document editing.
   - **Dependencies**: opendesk-nextcloud-aio-*, ums-keycloak-0

---

## Deployment Order Summary

To successfully deploy OpenDesk, follow this order:

1. **Foundation Layer**: Databases, caching, object storage
2. **Identity Layer**: LDAP, Keycloak, provisioning services + bootstrap jobs
3. **Application Layer**: Mail, chat, video conferencing, file storage
4. **Supporting Services**: Gateways, static files, auxiliary services

**Key Bootstrap Jobs:**
- `ums-keycloak-bootstrap`: Must complete before applications can authenticate
- `opendesk-openproject-bootstrap`: Configures OpenProject-Nextcloud integration

**Critical Dependencies:**
- All applications require `ums-keycloak-0` for authentication (OIDC)
- All applications require `ums-ldap-server-primary-0` for user/group data
- Provisioning system (`ums-provisioning-*`, `ox-connector-0`) requires `ums-provisioning-nats-0`
- File-based applications depend on `opendesk-nextcloud-aio-*`

This modular architecture allows for flexible deployment while maintaining clear dependency chains for reliable startup and operation.