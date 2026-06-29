# KubeAid vs The Alternatives: Why We Chose This Path

## The Short Version

We looked at Terraform, Pulumi, Ansible, and Puppet. We ended up with GitOps + Cluster API + ArgoCD. Here is why.

---

## Terraform: The Statefile Nightmare

Terraform is everywhere. ~48k GitHub stars, ~76% market share in IaC. So why not just use it for everything?

**Statefiles.**

Terraform keeps a statefile - a JSON blob that says "this is what I think exists in the cloud right now." Sounds reasonable until someone goes into the AWS console and manually changes something. Now your statefile is wrong, and Terraform has **no idea**. It cannot even tell you someone made that mistake.

Here is what actually happens in the real world:

- A support engineer manually upgrades a database during an incident (because production is on fire and you do not have time to write HCL). Three weeks later someone runs `terraform apply` for an unrelated change - Terraform sees the drift and **silently downgrades the production database back to the old size during peak traffic**.
- Two people run `terraform apply` at the same time without proper locking. State gets corrupted. Production resources get deleted. The whole team is locked out of deployments.
- A network drops mid-apply. The statefile is now half-written. Terraform may try to recreate resources that already exist, or refuse to run at all.

And the "fix"? You end up **manually editing JSON statefiles**. In production. For infrastructure. Let that sink in.

Yes, there are mitigations - state locking with DynamoDB, versioned backends on S3, never running apply outside CI/CD. But these are band-aids on a fundamentally broken model. You are always one manual change away from disaster, and Terraform will not warn you.

KubeAid uses Terraform in a limited, contained way for cloud resource provisioning where it makes sense. But we do not build our entire platform management on top of it. The cluster lifecycle, the applications, the monitoring, the security - all of that is GitOps through ArgoCD, where the desired state is **always** in Git, and drift detection is built in. ArgoCD will actually **tell you** when something is out of sync.

---

## Pulumi: The Promise vs The Reality

Pulumi sounds great on paper. Write your infrastructure in Go, Python, TypeScript - real programming languages instead of HCL. We were genuinely excited about using Go with Pulumi for infra. Then we looked under the hood.

**~85-90% of Pulumi providers are Terraform providers wrapped in a bridge.**

Pulumi has this thing called `pulumi-terraform-bridge` - it takes a Terraform provider, inspects its schema, and code-generates a Pulumi SDK around it. So when you write `new aws.s3.Bucket()` in TypeScript, underneath it is calling the same Terraform AWS provider. Only a handful of high-priority providers (AWS, Azure, GCP, Kubernetes) have native Pulumi implementations.

Which means: **the statefiles are back.** Pulumi has its own state model - desired state (your code), current state (Pulumi's state file), actual state (what is really in the cloud). It is fundamentally the same three-way problem as Terraform. If someone makes a manual change, the state file becomes stale. You run `pulumi refresh` to detect drift - same dance, different music.

Pulumi Cloud offers scheduled drift detection as a feature, and the state locking UX is better. But the underlying model is identical. You still cannot safely have someone make a manual change and expect the system to handle it gracefully. You still end up with `pulumi state` CLI commands for "surgical state modifications." Their own docs warn: **never edit state files manually.** Sound familiar?

So what did we gain? Nicer syntax. What did we lose? Nothing - because we had the same problems. The Go/TypeScript authoring experience is genuinely better than HCL, but that is not enough to justify building a platform on top of a system that has the same fundamental weakness.

---

## Ansible: Good at Config Management, Not at Platform Lifecycle

Ansible is the biggest community out there - ~69k GitHub stars, 5000+ contributors. We use it in LinuxAid. It is excellent at what it does: configuration management, running tasks on servers, ensuring a desired state for OS-level configuration.

But Ansible is **imperative at heart**. You write playbooks that say "do this, then do that." It does not maintain a continuous reconciliation loop. You run it, it makes changes, it is done. If someone changes something after Ansible ran, Ansible does not know and does not care until you run it again.

For Kubernetes platform management, you need continuous reconciliation. You need something that is always watching, always comparing desired state to actual state, always ready to tell you "hey, someone changed this outside of Git." That is what ArgoCD does. Ansible cannot do that - it is not designed to.

Ansible is great for bootstrapping servers, installing base packages, configuring OS-level things. We respect it. But managing a Kubernetes platform with 100+ Helm charts, continuous drift detection, and GitOps workflows? That is not Ansible's job.

---

## Puppet: Legacy, Declining, Wrong Abstraction

Puppet was revolutionary in its time. It introduced declarative configuration management before most people understood why that mattered. But it is in decline - ~7.9k GitHub stars, ~600 contributors, and shrinking.

The bigger issue is that Puppet's model is built around **managing individual servers**. It thinks in terms of packages, files, services on a host. Kubernetes thinks in terms of pods, deployments, services across a cluster. These are fundamentally different abstractions, and trying to bridge them creates more problems than it solves.

We came from the Puppet world with LinuxAid. We know it well. But Kubernetes needs Kubernetes-native tooling, and that is what KubeAid provides.

---

## Why Community Size Wins

This is the part people underestimate. When you pick a tool, you are not just picking the tool - you are picking its ecosystem. The number of blog posts, Stack Overflow answers, GitHub issues with solutions, third-party integrations, maintained providers.

| Tool | GitHub Stars | Contributors | Trend |
|------|-------------|-------------|-------|
| Ansible | ~69k | 5,000+ | Stable, strong in config management |
| Terraform | ~48.5k | 1,800+ | Dominant in IaC, but OpenTofu fork growing |
| Pulumi | ~22k | 4,400+ | Growing fast (~45% YoY) |
| Puppet | ~7.9k | ~600 | Declining |

Where most people go, everything simply works better and more reliably. You have less work with every Kubernetes upgrade because someone else already hit that problem and fixed it. The Helm chart you need already exists. The monitoring integration already works. The upgrade guide is already written.

KubeAid leans into this. We use ArgoCD (one of the most popular GitOps tools), Helm charts (the standard for Kubernetes packaging), Cluster API (the official Kubernetes SIG project for cluster lifecycle), and Prometheus (the de facto monitoring standard). We are not trying to be clever with niche tools. We pick what the community has already validated and make it work together seamlessly.

---

## The KubeAid Approach: What We Actually Do Instead

Instead of fighting statefiles and hoping nobody touches the cloud console, KubeAid does this:

1. **Cluster API for provisioning** - the official Kubernetes way to create clusters, with drivers maintained by the cloud vendors themselves. No statefiles. No drift that goes undetected.

2. **ArgoCD for everything else** - every Helm chart, every configuration, every policy lives in Git. ArgoCD continuously watches for drift and alerts you immediately when something is out of sync. Not "next time someone runs apply" - immediately.

3. **100+ curated Helm charts** - we do the evaluation work so you do not have to pick between 10+ PostgreSQL operators. We test them, configure them with sane defaults, and update them weekly.

4. **Compliance built in** - ISO 27001:2022 mapped into defaults. Not a checkbox exercise bolted on later.

The fundamental difference: in the Terraform/Pulumi model, the system's understanding of reality can silently diverge from actual reality. In the GitOps model, Git is the source of truth, and the system is always reconciling. When reality drifts, you know about it.

---

## Summary

| | Terraform | Pulumi | Ansible | Puppet | KubeAid |
|---|---|---|---|---|---|
| State management | Statefiles (fragile) | Statefiles (same problem, nicer wrapper) | Stateless (no continuous reconciliation) | Agent-based (server-centric) | Git is the state (ArgoCD reconciles) |
| Drift detection | Only on next plan/apply | Only on refresh or scheduled | None (run-and-done) | Agent checks periodically | Continuous (ArgoCD watches always) |
| Manual change handling | Silent disaster waiting to happen | Same as Terraform | Does not track | Agent may revert on next run | Detected and alerted immediately |
| Kubernetes-native | No (cloud resource focused) | Partial | No (server focused) | No (server focused) | Yes (built for K8s) |
| Community ecosystem | Massive | Growing | Massive | Declining | Leverages K8s ecosystem directly |

We did not make this choice because the alternatives are bad tools. Terraform is genuinely useful for cloud resource provisioning. Ansible is excellent for configuration management. Pulumi has real developer experience improvements. But for managing a Kubernetes platform end-to-end, with continuous reconciliation, drift detection, and compliance built in? GitOps with ArgoCD and Cluster API is the right answer. That is what KubeAid is built on.
