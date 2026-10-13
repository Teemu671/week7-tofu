# Cloud Week 7 Documentation

# Infrastructure as Code — Core Concepts & Analysis

## Why was OpenTofu created? Compare Terraform and OpenTofu — would the choice between them matter to you as a developer, or to a company?


### Why OpenTofu Was Created
HashiCorp shifted the license of Terraform from the open-source **Mozilla Public License (MPL v2)** to the restrictive **Business Source License (BSL v1.1)**. Companies could no longer use Terraform to build competing commercial products. In response, a group of developers, startups, and enterprises formed a fork called **OpenTofu** under the **Linux Foundation** to ensure a open-source, community-driven tool alternative.

### Terraform vs. OpenTofu Matrix

| Dimension | Terraform (HashiCorp) | OpenTofu (Linux Foundation) |
| :--- | :--- | :--- |
| **Licensing** | Business Source License (BSL 1.1) — Restrictive commercial use | Mozilla Public License (MPL 2.0) — Truly open source |
| **Registry** | Controlled by HashiCorp (Subject to strict terms of service) | Decentralized, community-managed registry |
| **Ecosystem** | Integrated with HashiCorp Cloud Platform (HCP) | Native state encryption, community RFC-driven features |

### Does the Choice Matter?
* **To a Developer:** **Rarely.** Both engines interpret the exact same HCL syntax, share provider libraries, and utilize identical CLI workflows (`init`, `plan`, `apply`, `destroy`). Your local workflow will remain identical using both.
* **To a Company:** **Yes, significantly.** Companies building managed DevOps platforms or SaaS tooling risk legal non-compliance under HashiCorp’s BSL terms. Large firms often transition to OpenTofu to mitigate long-term vendor lock-in, legal exposure, or unexpected licensing fee hikes.

---

## Some changes in a tofu plan are made in place, while others require the resource to be destroyed and re-created. Why does this matter, and what kinds of changes would you be especially careful with?

### Why the Difference Matters
* **In-Place Updates (`~`):** Modifies specific parameters on an existing resource dynamically (e.g., adding an optional tag or appending a new rule to an OpenStack security group) without impacting runtime stability.
* **Destructive Replacements (`-/+`):** Forces the platform to delete the old resource completely before generating a fresh resource. 

### High-Risk Changes to Watch Out For
* **Database Updates:** Altering standard storage engine schemas, compute flavors, or database names will trigger a destruction cycle that results in total data loss if a remote backup isn’t configured.
* **Network & Compute Resizing:** Changing core components like static Private IP blocks, specific OS Images, Virtual Machine flavors, or Root Disk Volume sizes can trigger a forced instance deletion.
* **How to Mitigate Danger:** AI said: Use `lifecycle { prevent_destroy = true }` block on mission-critical state files.

---

## What is configuration drift, how does it happen, and how does an IaC tool detect it?

### What is Configuration Drift & How It Happens
Configuration Drift occurs when the actual state of your live cloud environment deviates from the configurations defined in your local `.tf` files. 

It happens primarily through:
* **Manual Emergencies:** A sysadmin logs into the web console to expand an active security firewall rule during a live outage and forgets to document it.
* **External Overwrites:** Automated patches, cloud providers updating resource baselines, or API scripts running independently of the IaC workflow.

### How OpenTofu/Terraform Detects It
When you run `tofu plan` or `tofu apply`, the engine triggers a three-step reconciliation process:
1. **Refresh Cycle:** The CLI queries the real-world cloud provider APIs to fetch current operational metrics for managed items.
2. **State Alignment Analysis:** The real-time results are compared directly against your local `.tfstate` cache tracking ledger.
3. **Delta Proposal:** If variances exist, the tool compiles a corrective execution plan. It will propose to either roll back the manual console changes or align state definitions to match the running deployment.

---

## Explain the difference between declarative and imperative infrastructure automation. What does idempotency mean, and why is it important?

### Infrastructure Automation Philosophies
* **Declarative Approach (e.g., OpenTofu, Terraform):** You specify the final desired state of your target architecture (e.g., *"I need 1 VM instance with Port 80 open"*). The tool evaluates the active environment and handles all calculations, dependencies, and api calls automatically.
* **Imperative Approach (e.g., Bash scripts, AWS CLI, Ansible commands):** You provide step-by-step sequential directions to the system (e.g., *"Run curl, install nginx, wait 5 seconds, spin up security-group-1, bind the elastic IP"*). If a single intermediate command encounters an unexpected fault, the entire execution workflow breaks.

### Idempotency: Definition & Critical Importance
* **Definition:** **Idempotency** describes an automation process that yields the exact same environment outcome regardless of how many times it is run. Running an idempotent block once, 10 times, or 100 times results in the identical final state.
* **Why It Is Crucial:** It completely eliminates infrastructure duplication, resource bloat, and deployment anxiety. If an automated script fails halfway through execution, an idempotent engine can safely re-run without trying to clone existing virtual machines or create overlapping subnets, gracefully correcting only what is missing or broken.


## Working Infrastructure from Code

### Initial Deployment & Verification
The OpenTofu code successfully provisions the core components: the Virtual Machine, security groups, key pair, and floating IP. Configuration is handled automatically via cloud-init.

* **First Successful Run (`tofu apply` baseline):**
  ![Successful Execution Baseline](https://a3s.fi/swift/v1/week7-cloud-tofu/FirstRun.png)
* **Web Server Operational Verification:**
  The web server serves traffic correctly after deployment updates.
  ![Website Verification](https://a3s.fi/swift/v1/week7-cloud-tofu/WebsiteWithChangedWebpage.png)

***

## Experiment 1: Change

### Change A: Modifying Security Group Security Rules
* **Prediction:** Probably gonna change make create the deleted security group rule back without affecting the other stuff from the VM or project.
* **Execution Result:** 
  ![Tofu Plan After New 8080 Rule](https://a3s.fi/swift/v1/week7-cloud-tofu/TofuPlanAfterNew8080Rule.png)
  ![After Deleting HTTP Rule](https://a3s.fi/swift/v1/week7-cloud-tofu/AfterDeletingHttpRule.png)
* **Explanation:** It did create a new rule when deleting the HTTP (80) rule but when adding the 8080 rule it doesn't do anything and doesn't complain.

### Change B: Changing the VM Hostname / Core Resource Attributes
* **Prediction:** The variables are carried over from the terraform.tfvars to variables.tf to main.tf so I would expect the whole thing to be made again to apply changes aka (`-/+` destroy and then create).
* **Execution Result:**
  ![Plan Destroy for Changed Name](https://a3s.fi/swift/v1/week7-cloud-tofu/planDestroyForChangedName.png)
* **Explanation:** Yes. It destroys the old and creates a new one in place to update the variables.

***

## Experiment 2: Drift

**Objective:** Alter infrastructure manually via the web console. Observe what `tofu plan` flags, what it fails to notice, and why.

* **Prediction:** It notices the new https rule and adds it to the security group in cPouta.
* **Execution Result:**
  ![Tofu Plan HTTPS Detection](https://a3s.fi/swift/v1/week7-cloud-tofu/tofuPlanHttps.png)
  ![VS Code Context Tracking](https://a3s.fi/swift/v1/week7-cloud-tofu/httpsInVSCODE.png)
* **Explanation:** I did work but the website doesn't work with the https still does to the apache configurations not being updated. I think.

***

## Experiment 3: Destroy & Rebuild

**Objective:** Execute `tofu destroy` followed by `tofu apply`. Analyze resource teardown order and recovery behavior.

* **Prediction:** Resources will be deleted in the reserver order of creation due to depencency concerns.
* **Execution Result:**
  * *Teardown Metrics:* ![How Many To Destroy](https://a3s.fi/swift/v1/week7-cloud-tofu/HowManyToDestroy.png)
  * *Teardown Log Context:* ![Detailed List of Destroyed Resources](https://a3s.fi/swift/v1/week7-cloud-tofu/DestoryListOfDestroyed.png)
  * *Destruction Execution:* ![Destroyed Files](https://a3s.fi/swift/v1/week7-cloud-tofu/DestoryedFiles.png)
* **Explanation:** Destruction successfully deletes the architecture in a non-blocking sequence.

***

## Problems Encountered & Solutions

### 1. Cloud Provider API Quota Exhaustion
* **Problem:** While I was trying to tofu apply again after destorying the previous version. The quota is 2 max and it wasn't displaying the old IP but it still registered as me having 2/2 public IPs.
  ![Problem Quota Encountered](https://a3s.fi/swift/v1/week7-cloud-tofu/ProblemQuota.png)
* **Solution:** Required waiting to allow cPouta update the count and release the floating IP.
  ![Fixing Quota After Waiting](https://a3s.fi/swift/v1/week7-cloud-tofu/FixingQuotaAfterWaiting.png)