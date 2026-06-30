# Why KubeAid: A Comparison With The Alternatives

We looked at Terraform, Pulumi, Ansible, and Puppet. We ended up building KubeAid on GitOps + Cluster API + ArgoCD.

This document explains what makes KubeAid different, why we did not go those other routes, and what we learned from years of running Terraform, Ansible, and Puppet in [LinuxAid](https://github.com/Obmondo/LinuxAid).

---

## What KubeAid Gets Right

### Git Is the Only Source of Truth

Every piece of your Kubernetes platform - every Helm chart, every configuration, every network policy, every monitoring rule - lives in Git. Not in a statefile sitting in S3 that can go stale. Not in someone's head. Not in a cloud console session someone forgot to document. **In Git.**

ArgoCD continuously watches your Git repository and compares it against what is actually running in your cluster. The moment something drifts - whether someone ran a `kubectl edit`, manually scaled a deployment, or changed a config - ArgoCD sees it and alerts you. Not tomorrow when someone runs a plan. Not next week when CI happens to trigger. **Right now.**

This is the single biggest thing that separates KubeAid from the alternatives. In every other model we evaluated, there is a gap between "what the system thinks exists" and "what actually exists" - and that gap is where production incidents hide.

### One Way to Run Kubernetes, On Any Cloud

AWS has IAM. Azure has Workload Identity. Hetzner has API tokens. Bare metal has SSH keys. The networking, the storage, the identity model - none of it is portable. Every team that goes multi-cloud ends up learning four different ways to do the same thing.

KubeAid uses **Cluster API** - the official Kubernetes SIG project for cluster lifecycle management - to abstract all of this away. Cloud vendors maintain their own Cluster API drivers. You give KubeAid CLI two YAML files (`general.yaml` for what you want, `secrets.yaml` for credentials), and you get a production-ready cluster with GitOps, monitoring, networking, and security configured out of the box.

The same workflow works on AWS, Azure, Hetzner, and bare metal. Learn it once, use it everywhere.

### 100+ Helm Charts, Curated and Tested

There are 10+ PostgreSQL operators for Kubernetes. Which one do you pick? There are dozens of ingress controllers, monitoring stacks, secret management solutions. How do you know which ones actually work well together?

KubeAid ships **100+ pre-configured Helm charts** that we have tested, tuned, and deployed across real production environments. Every chart is wrapped in our umbrella pattern so it integrates cleanly with the rest of the platform. Default values follow security and operational best practices. Charts are updated weekly with security patches.

You do not spend weeks evaluating tools. You get a stack that works on day one.

### Compliance Built In, Not Bolted On

KubeAid's defaults are mapped to **ISO 27001:2022**, covering GDPR and NIS2 goals. This is not a marketing checkbox - it means:

- **NetworkPolicies** enforce least-privilege pod communication out of the box
- **Sealed Secrets** handle encrypted-at-rest secret management
- **Audit logging** tracks who did what and when
- **Automated backups** via Velero for disaster recovery
- **Supply chain scanning** with Trivy for vulnerability detection
- **Drift detection** catches unauthorised changes immediately

Most teams bolt compliance on after the fact, usually when an auditor asks. With KubeAid, you start compliant and stay compliant.

### The Open-Source Flywheel

KubeAid is fully open source. Every fix, every improvement, every new chart we add for any customer flows to all customers and the community. The collective investment is far greater than any single team could afford.

And there is zero vendor lock-in. You own your Git repository. You own your clusters. If you stop using Obmondo's managed service tomorrow, everything keeps running.

---

## Why Not Terraform?

Terraform is everywhere - ~48k GitHub stars, ~76% market share in IaC. We use it ourselves in a limited way for cloud resource provisioning (VPCs, IAM roles, DNS zones). But we do not build our platform on top of it. Here is why.

### The Statefile Problem

Terraform keeps a statefile - a JSON blob that says "this is what I think exists in the cloud right now." The moment someone makes a manual change (and they will - during incidents, during debugging, during that 2am production fire where nobody has time to write HCL), the statefile goes stale. Terraform has **no idea** this happened. It cannot even tell you someone made that mistake.

What happens next is worse:

- Someone runs `terraform apply` for an unrelated change. Terraform sees the drift and **silently reverts the manual change** - maybe downgrading a database back to its old size during peak traffic.
- You discover the drift and try to fix it. `terraform import` adds the resource to state but does not generate HCL code - so next `apply` tries to delete it. `terraform state rm` requires the exact resource address - one typo and you orphan infrastructure. Eventually you end up **manually editing a JSON statefile** with hundreds of resources and praying nothing breaks.
- Two people run `terraform apply` at the same time without proper locking. State gets corrupted. Production resources get deleted.

There are mitigations - state locking with DynamoDB, versioned backends on S3, restricting apply to CI/CD. But these are band-aids. You are always one manual change away from a stale statefile, and Terraform will not warn you.

**KubeAid's answer:** Git is the state. ArgoCD reconciles continuously. Drift is detected immediately, not on next apply. No statefiles to corrupt, go stale, or manually edit.

---

## Why Not Pulumi?

We were genuinely excited about Pulumi. Write infrastructure in Go or TypeScript instead of HCL? Real programming languages with loops, type safety, IDE support, and proper testing? Sign us up.

Then we looked under the hood.

### Most of Pulumi Is Terraform Underneath

**~85-90% of Pulumi providers are Terraform providers wrapped in a bridge** (`pulumi-terraform-bridge`). When you write `new aws.s3.Bucket()` in TypeScript, you are calling the same Terraform AWS provider through a generated wrapper. Only a handful of high-priority providers have native Pulumi implementations.

This was the main thing that killed it for us. Even though using Go with Pulumi to do infra would be nice, most of the support in Pulumi is actually done by a Terraform module underneath. Which means the statefiles are back.

### Does Pulumi Solve the State Problem?

**No.** Pulumi has the same three-way state model as Terraform: desired state (your code), current state (Pulumi's state file), actual state (what is really in the cloud). If someone makes a manual change, the state file becomes stale. You run `pulumi refresh` to detect drift - same dance, different music. Their own docs warn: **never edit state files manually.**

Pulumi Cloud offers scheduled drift detection and better locking UX. But the fundamental failure mode is identical: someone makes a manual change, nobody knows until something breaks, and when you find it you MAY break something trying to fix it - and you will have to manually modify statefiles.

The syntax is nicer, the UX is smoother, but the failure mode is the same one we were trying to escape.

**KubeAid's answer:** No statefiles at all. Cluster API manages infrastructure as Kubernetes objects with continuous reconciliation. ArgoCD manages everything else from Git. Drift is caught the moment it happens.

---

## Why Not Ansible?

Ansible is the biggest community out there - ~69k GitHub stars, 5000+ contributors. We use it extensively in [LinuxAid](https://github.com/Obmondo/LinuxAid) for server configuration management. It is excellent at what it does.

But Ansible is **imperative and run-once**. You execute a playbook, it makes changes, it is done. If someone changes something after Ansible ran, Ansible does not know and does not care until you run it again. There is no continuous reconciliation loop.

There is also the abstraction mismatch. Ansible thinks in terms of SSH connections, hosts, and tasks. Kubernetes thinks in terms of API objects, controllers, and reconciliation loops. You can use Ansible's `k8s` module, but you are basically using it as a glorified `kubectl apply` - losing all the continuous sync, drift detection, and rollback that ArgoCD gives you for free.

Ansible is great for bootstrapping servers and OS-level config. We respect it and we still use it where it fits. But managing a Kubernetes platform with 100+ Helm charts and continuous drift detection? That is not Ansible's job.

**KubeAid's answer:** ArgoCD provides the continuous reconciliation loop that Ansible cannot. The platform is always watching, always comparing, always ready to tell you when something is out of sync.

---

## Why Not Puppet?

Puppet was revolutionary in its time. We came from the Puppet world with [LinuxAid](https://github.com/Obmondo/LinuxAid) - we know it well, we have written thousands of manifests.

But Puppet is in decline (~7.9k GitHub stars, ~600 contributors, shrinking). The community is moving elsewhere, and with it goes the ecosystem.

More importantly, Puppet's model is built around **managing individual servers** - packages, files, services on a host. Kubernetes is a fundamentally different abstraction - pods, deployments, services across a cluster. Puppet's agent-based model (agent on each server checks in with a master every 30 minutes) does not map to Kubernetes where the cluster is the unit, not the node.

**KubeAid's answer:** Kubernetes-native tooling for Kubernetes problems. ArgoCD is a Kubernetes controller that watches the Kubernetes API - the same pattern Kubernetes uses for everything.

---

## KubeAid Stands on the Shoulders of Giants

KubeAid is not competing with the Kubernetes ecosystem - it **is** the Kubernetes ecosystem, assembled and battle-tested.

Every tool in the KubeAid stack is already one of the largest, most active open-source projects in infrastructure:

| KubeAid Component                | What It Is                                           | Community Behind It         |
| -------------------------------- | ---------------------------------------------------- | --------------------------- |
| **ArgoCD**                       | GitOps continuous delivery                           | CNCF Graduated, ~18k stars  |
| **Helm**                         | Kubernetes package management                        | CNCF Graduated, ~27k stars  |
| **Cluster API**                  | Cluster lifecycle management                         | Official Kubernetes SIG     |
| **Prometheus + Grafana**         | Monitoring and observability                         | CNCF Graduated, ~57k stars  |
| **Cilium**                       | Networking (CNI)                                     | CNCF Graduated, ~21k stars  |
| **cert-manager**                 | TLS certificate management                           | CNCF Graduated, ~12k stars  |
| **CloudNative-PG**               | PostgreSQL operator                                  | CNCF Sandbox, ~5k stars     |

When you use KubeAid, you are not betting on a small project. You are getting the combined community of tens of thousands of contributors across all of these projects. When someone finds a bug in ArgoCD, the ArgoCD community fixes it. When Cilium adds a feature, you get it. When Prometheus improves, your monitoring improves.

This is the advantage. Terraform, Pulumi, Ansible, and Puppet each have their own ecosystem that you have to learn, maintain, and keep up with. KubeAid plugs you directly into the Kubernetes ecosystem - the largest, most active infrastructure community in the world.

Where most people go, everything simply works better and more reliably. You have less work with every Kubernetes upgrade because someone else already hit that problem and fixed it. The Helm chart you need already exists. The monitoring integration already works. The upgrade guide is already written. When you are doing a Kubernetes upgrade at 2am and something breaks, you search for the error message and find five people who already solved it.

KubeAid's job is to make all of these projects work together seamlessly - so you do not spend months integrating them yourself.

---

## Summary

|                        | Terraform                                   | Pulumi                                   | Ansible                                  | Puppet                       | **KubeAid**                              |
| ---------------------- | ------------------------------------------- | ---------------------------------------- | ---------------------------------------- | ---------------------------- | ---------------------------------------- |
| State management       | Statefiles (fragile)                        | Statefiles (same problem, nicer wrapper) | Stateless (no continuous reconciliation) | Agent-based (server-centric) | **Git is the state (ArgoCD reconciles)** |
| Drift detection        | Only on next plan/apply                     | Only on refresh or scheduled             | None (run-and-done)                      | Agent checks every ~30 min   | **Continuous (always watching)**         |
| Manual change handling | Silent disaster waiting to happen           | Same as Terraform                        | Does not track                           | Agent may revert on next run | **Detected and alerted immediately**     |
| Kubernetes-native      | No (cloud resource focused)                 | Partial                                  | No (server focused)                      | No (server focused)          | **Yes (built for K8s)**                  |
| Multi-cloud            | Per-provider modules                        | Per-provider code                        | Per-host playbooks                       | Per-host manifests           | **One workflow, any cloud**              |
| Compliance             | DIY                                         | DIY                                      | DIY                                      | DIY                          | **ISO 27001:2022 built in**              |
| Community ecosystem    | Massive                                     | Growing                                  | Massive                                  | Declining                    | **Leverages entire K8s ecosystem**       |
| Where we use it        | Limited cloud provisioning (VPCs, IAM, DNS) | We do not                                | LinuxAid (server config management)      | LinuxAid (legacy)            | **Platform management end-to-end**       |

We did not make this choice because the alternatives are bad tools. Terraform is genuinely useful for cloud resource provisioning - we still use it for that. Ansible is excellent for configuration management - we still use it in LinuxAid. Pulumi has real developer experience improvements over Terraform.

But for managing a Kubernetes platform end-to-end - with continuous reconciliation, immediate drift detection, compliance built in, and the same workflow on every cloud - GitOps with ArgoCD and Cluster API is the right answer.

**That is what KubeAid is built on. And that is why it works.**
