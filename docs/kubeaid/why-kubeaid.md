# Why KubeAid?

## The Problem: Kubernetes Is Not the Same Everywhere

Everyone thinks installing Kubernetes on any cloud is easy, at least the first time. But there is one important
distinction that most people miss: **it is very different everywhere**, especially when you need automation. And we all
need automation.

- **AWS** has its IAM system for identity management.
- **Azure** has Workload Identity to solve something similar, but in a completely different way.
- **Hetzner**, **bare metal**, and **on-premise** setups each have their own unique requirements.

```mermaid
---
title: The Same Task, Completely Different Everywhere
---
flowchart LR
    subgraph AWS["AWS"]
        direction TB
        A1["IAM Roles"]
        A2["EBS CSI Driver"]
        A3["VPC CNI"]
        A4["ALB Ingress"]
    end

    subgraph Azure["Azure"]
        direction TB
        B1["Workload Identity"]
        B2["Azure Disk CSI"]
        B3["Azure CNI"]
        B4["App Gateway"]
    end

    subgraph Hetzner["Hetzner"]
        direction TB
        C1["API Tokens"]
        C2["Hetzner Volumes"]
        C3["Cilium"]
        C4["Traefik"]
    end

    subgraph BM["Bare Metal"]
        direction TB
        D1["SSH Keys"]
        D2["Local Storage"]
        D3["Cilium"]
        D4["Traefik"]
    end

    You["You want: a working K8s cluster"] --> AWS
    You --> Azure
    You --> Hetzner
    You --> BM

    style You fill:#e8833a,stroke:#b35c1e,color:#fff
    style AWS fill:#ff9900,stroke:#cc7a00,color:#fff
    style Azure fill:#0078d4,stroke:#005a9e,color:#fff
    style Hetzner fill:#d50c2d,stroke:#a30a22,color:#fff
    style BM fill:#6b8e23,stroke:#4a6319,color:#fff
```

Best practices for each cloud provider differ *dramatically*. The networking, the identity model, the storage, the
scaling: none of it is portable. And this is **just installation**. Day 2 operations (upgrades, monitoring, backup,
security) are even more fragmented.

The result? Every team solves the same problems from scratch, often making the same mistakes. 95% of what one team needs
is the *exact same* as what every other team needs.

---

## One Way to Install, On Any Cloud (Even Your Own)

KubeAid was designed to solve this by giving you **one unified way to install Kubernetes**, regardless of where you
choose to run it: AWS, Azure, Hetzner, bare metal, or your own data centre. This includes the clouds' managed control
planes: KubeAid can bootstrap and delete EKS and AKS clusters, with upgrades done as a GitOps version bump.

We tried hard not to reinvent the wheel. For unifying installation automation across every possible target, there is
only one solution: **[Cluster API](https://cluster-api.sigs.k8s.io/)**.

Cluster API is complex by design. It hides each cloud provider's complexity behind drivers, which are often maintained
by the cloud vendors themselves. But it removes the vendor lock-in those vendors have worked so hard to build. And it
unifies the managed paths too: an EKS or AKS cluster is driven through the same Cluster API workflow as a self-managed
one.

On top of Cluster API, there is a *lot* to set up correctly: GitOps management, identity implementation (which differs
by provider), networking, monitoring, and more. This is what **KubeAid CLI** handles for you.

You give it **2 YAML files**:

1. **`general.yaml`**: a spec of *what you want*, written in a generalised way. You can take the same file and roll
   your cluster up in any other location.
2. **`secrets.yaml`**: the credentials needed to actually do it. Store this in your password manager.

That's it. One command, and your production-ready cluster is provisioned with GitOps, monitoring, networking, and
security configured out of the box.

```mermaid
---
title: How KubeAid CLI Works
---
flowchart LR
    G["general.yaml\n(what you want)"] --> CLI["KubeAid CLI"]
    S["secrets.yaml\n(credentials)"] --> CLI

    CLI --> CAPI["Cluster API"]

    CAPI --> AWS["AWS"]
    CAPI --> Azure["Azure"]
    CAPI --> Hetzner["Hetzner"]
    CAPI --> BM["Bare Metal"]

    CLI --> GitOps["GitOps Setup\n(ArgoCD)"]
    CLI --> Mon["Monitoring\n(Prometheus)"]
    CLI --> Sec["Security\n(NetworkPolicies)"]

    style CLI fill:#e8833a,stroke:#b35c1e,color:#fff
    style CAPI fill:#326ce5,stroke:#1a4dab,color:#fff
    style G fill:#6b8e23,stroke:#4a6319,color:#fff
    style S fill:#b8860b,stroke:#8b6508,color:#fff
    style GitOps fill:#7b68ee,stroke:#5a4bb8,color:#fff
    style Mon fill:#7b68ee,stroke:#5a4bb8,color:#fff
    style Sec fill:#7b68ee,stroke:#5a4bb8,color:#fff
```

---

## Curated Best Practices, Not Decision Fatigue

On top of installation, there is a *lot* of work in picking "the right" solution for everything you need in a
Kubernetes cluster. There are **10+ PostgreSQL operators** (seriously). Which one fits your needs, if you even knew you
needed an operator?

In KubeAid, we constantly evaluate and ship the best-practice solution for every common need:

- **100+ pre-configured Helm charts**, tested and updated weekly
- Default values that follow security and operational best practices
- Solutions selected based on real-world production experience across many customers

Because KubeAid is open source, everyone benefits from this collective curation. You get the best start possible, and
the community continuously improves the selection.

```mermaid
---
title: What KubeAid Gives You Out of the Box
---
flowchart TB
    subgraph KubeAid["KubeAid Platform"]
        direction TB

        subgraph Infra["Infrastructure"]
            ClusterAPI["Cluster API\n(provisioning)"]
            Cilium["Cilium CNI\n(networking)"]
            CSI["Storage Drivers\n(per provider)"]
        end

        subgraph Ops["Operations"]
            ArgoCD["ArgoCD\n(GitOps)"]
            Prometheus["Prometheus + Grafana\n(monitoring)"]
            Alertmanager["Alertmanager\n(alerting)"]
        end

        subgraph Security["Security"]
            SealedSecrets["Sealed Secrets\n(encryption)"]
            NetworkPolicies["NetworkPolicies\n(firewalling)"]
            CertManager["cert-manager\n(TLS)"]
        end

        subgraph Data["Data"]
            PostgreSQL["PostgreSQL Operator"]
            Velero["Velero\n(backup)"]
            Redis["Redis / KeyDB"]
        end
    end

    style KubeAid fill:#1a1a2e,stroke:#4a90a4,color:#fff
    style Infra fill:#4a90a4,stroke:#2d5a6b,color:#fff
    style Ops fill:#e8833a,stroke:#b35c1e,color:#fff
    style Security fill:#6b8e23,stroke:#4a6319,color:#fff
    style Data fill:#7b68ee,stroke:#5a4bb8,color:#fff
```

---

## Compliance Built In, Not Bolted On

The best practices in KubeAid are designed around the compliance requirements that have emerged because everyone
actually wants a stable environment with the best possible security and reliability, to avoid being compromised by
ransomware attacks and other threats.

We map all these requirements into the **ISO 27001:2022** specification and constantly work to ensure KubeAid guides
you to solutions that adhere to those goals. This includes legislations like **GDPR** and **NIS2**, which all have goals
that are already part of ISO 27001:2022.

```mermaid
---
title: How KubeAid Maps to Compliance
---
flowchart TB
    subgraph Reqs["Compliance Requirements"]
        ISO["ISO 27001:2022"]
        GDPR["GDPR"]
        NIS2["NIS2"]
    end

    GDPR -->|"goals already covered by"| ISO
    NIS2 -->|"goals already covered by"| ISO

    ISO -->|"mapped into"| KA["KubeAid Defaults"]

    KA --> NP["NetworkPolicies\n(least privilege)"]
    KA --> SS["Sealed Secrets\n(encrypted at rest)"]
    KA --> AU["Audit Logging\n(who did what)"]
    KA --> BA["Automated Backups\n(disaster recovery)"]
    KA --> SC["Supply Chain Scans\n(vulnerability detection)"]
    KA --> DD["Drift Detection\n(unauthorised changes)"]

    style Reqs fill:#b8860b,stroke:#8b6508,color:#fff
    style KA fill:#e8833a,stroke:#b35c1e,color:#fff
    style ISO fill:#d4a017,stroke:#a37c10,color:#fff
```

We have open-sourced this compliance work and continue to improve it:
**[obmondo.com/en/compliance](https://obmondo.com/en/compliance)**

Complying with these requirements makes perfect sense. They were written by experienced people based on decades of
industry knowledge. But it takes time to learn and implement, time and skill that many smaller companies simply don't
have.

---

## The Open-Source Flywheel

This is where [Obmondo](https://obmondo.com), the makers of KubeAid, bridges the gap.

As we solve problems for our customers, we solve them so they work for *all* of our customers, no matter where they have
chosen to run their servers. Every one of our customers understands that allowing us to open-source the work we do for
them is what allows us to share the workload across all of them.

**Whenever we raise the bar, everyone benefits.**

This model means:

- Fixes and improvements for one customer flow to all customers, and to the community
- The collective investment in KubeAid is far greater than any single team could afford
- You get a platform that is battle-tested across diverse production environments

[Obmondo](https://obmondo.com) offers subscriptions where we monitor your clusters and handle your alerts 24/7,
enabling your team to focus on your business, not on who is absent, on holiday, or ill. There is **zero vendor
lock-in**: any subscription can be cancelled at any time.
