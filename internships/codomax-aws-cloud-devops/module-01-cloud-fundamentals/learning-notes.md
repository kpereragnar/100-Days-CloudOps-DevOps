# AWS & Cloud Fundamentals — Learning Notes

## 1. Introduction to Cloud Computing

Cloud computing is the delivery of computing resources—including servers, storage, databases, networking, and software—over the internet on demand.

Instead of purchasing and maintaining all physical infrastructure, organizations can access computing resources from cloud providers and pay according to their usage or chosen pricing model.

### Key Benefits

- **Scalability:** Resources can be increased or decreased as requirements change.
- **Elasticity:** Computing capacity can adjust to changing workloads.
- **Cost Efficiency:** Reduces the need for upfront investment in physical infrastructure.
- **Availability:** Cloud services can support resilient architectures when configured appropriately.
- **Global Reach:** Applications can be deployed closer to users in different geographical locations.
- **Managed Services:** Cloud providers manage some or all of the underlying infrastructure, depending on the service.

### Traditional IT vs. Cloud Computing

| Traditional IT | Cloud Computing |
|---|---|
| Organizations purchase physical servers. | Resources can be provisioned on demand. |
| Capacity planning often requires significant upfront investment. | Capacity can be adjusted as requirements change. |
| Hardware maintenance is handled by the organization. | Infrastructure responsibilities vary by service model. |
| Expanding capacity may require purchasing and installing hardware. | Additional resources can often be provisioned quickly. |

Cloud computing does not eliminate infrastructure management or security responsibilities. Organizations must still configure their environments appropriately.

## 2. Cloud Service Models

Cloud service models describe the level of infrastructure management provided by the cloud provider and the responsibilities retained by the customer.

### Infrastructure as a Service (IaaS)

IaaS provides fundamental computing infrastructure, including virtual machines, storage, and networking.

The customer generally manages the operating system, installed applications, and much of the system configuration, while the provider manages the underlying physical infrastructure.

**Example:** Amazon EC2, which provides virtual servers.

**Common use cases:**
- Hosting applications on virtual machines.
- Running custom operating systems and software.
- Building flexible computing environments.

### Platform as a Service (PaaS)

PaaS provides a managed platform for developing, deploying, and running applications without requiring customers to manage every layer of the underlying infrastructure.

The provider manages more of the infrastructure and platform components than in a typical IaaS arrangement.

**Example:** AWS Elastic Beanstalk, which helps deploy and manage applications on AWS.

**Common use cases:**
- Application development and deployment.
- Reducing infrastructure administration.
- Supporting development teams that want to focus on application code.

### Software as a Service (SaaS)

SaaS provides ready-to-use software over the internet. The provider manages the application and its underlying infrastructure.

**Examples:** Salesforce and Microsoft 365.

**Common use cases:**
- Email and collaboration.
- Customer relationship management.
- Online productivity applications.

### Comparison

| Characteristic | IaaS | PaaS | SaaS |
|---|---|---|---|
| Main offering | Computing infrastructure | Application platform | Ready-to-use software |
| Infrastructure management | Primarily provider-managed physical infrastructure | Provider manages infrastructure and platform layers | Provider manages the application and underlying service |
| Customer focus | OS, configuration, and applications | Application development and data | Using the software |
| Example | Amazon EC2 | AWS Elastic Beanstalk | Salesforce |

## 3. Cloud Deployment Models

Deployment models describe how cloud infrastructure is owned, organized, and made available.

### Public Cloud

Cloud resources are provided by a third-party cloud provider and accessed over a network.

**Example:** Hosting an application using AWS services.

**Advantages:**
- Rapid provisioning.
- Access to a wide range of managed services.
- Flexible capacity and pricing options.

### Private Cloud

Cloud infrastructure is dedicated to a single organization. It may be hosted within the organization's facilities or by a third party.

**Advantages:**
- Greater control over the environment.
- Ability to tailor configurations to organizational requirements.
- Potential suitability for specific regulatory or operational constraints.

A private cloud still requires effective security, maintenance, and governance.

### Hybrid Cloud

A hybrid cloud combines private infrastructure with public cloud resources, with some level of integration or coordination between them.

**Example:** An organization retains selected systems in its own data centre while running other workloads in AWS.

**Advantages:**
- Flexibility in workload placement.
- Support for gradual cloud migration.
- Ability to combine existing infrastructure with public cloud services.

## 4. AWS Global Infrastructure

Amazon Web Services operates infrastructure across geographical locations to support the deployment, availability, and performance of cloud applications.

### AWS Regions

An AWS Region is a separate geographical area containing AWS infrastructure.

Organizations select Regions based on considerations such as:
- Proximity to users.
- Service availability.
- Data residency and regulatory requirements.
- Cost and operational requirements.
- Disaster recovery design.

Not every AWS service is available in every Region.

### Availability Zones

An Availability Zone (AZ) is an isolated location within an AWS Region, consisting of one or more data centres with independent infrastructure.

Deploying workloads across multiple Availability Zones can improve resilience against certain types of infrastructure failure.

For example, a web application could run across two Availability Zones behind a load balancer. If one zone becomes unavailable, the architecture may continue serving traffic through the other, provided the application and its dependencies are designed for this scenario.

### Regions and Availability Zones

| Feature | AWS Region | Availability Zone |
|---|---|---|
| Meaning | Geographical area | Isolated location within a Region |
| Main purpose | Geographical deployment and service selection | Isolation and resilience within a Region |
| Relationship | Contains multiple Availability Zones | Belongs to a Region |

### AWS Global Infrastructure and Architecture

A resilient architecture may use multiple Availability Zones within one Region. For broader disaster recovery requirements, an organization may also consider using multiple Regions.

The appropriate design depends on the application's availability, recovery, latency, and cost requirements.

## 5. Introduction to Core AWS Services

### Amazon EC2 — Compute

Amazon Elastic Compute Cloud (EC2) provides virtual servers called instances.

**Common uses:**
- Hosting web applications.
- Running backend services.
- Performing computing tasks.
- Hosting tools and applications that require operating-system-level control.

Important concepts include instance types, Amazon Machine Images (AMIs), key pairs, security groups, and storage volumes.

### Amazon S3 — Object Storage

Amazon Simple Storage Service (S3) is an object storage service used to store and retrieve data.

**Common uses:**
- Storing documents, images, and other files.
- Hosting static website assets.
- Backups and archival storage.
- Storing logs and data used by other services.

Security considerations include bucket policies, IAM permissions, encryption, and blocking unintended public access.

### Amazon VPC — Networking

Amazon Virtual Private Cloud (VPC) enables customers to provision a logically isolated network for AWS resources.

Important networking concepts include:
- **Subnets:** Network segments within a VPC associated with an Availability Zone.
- **Route tables:** Rules determining where network traffic is directed.
- **Internet gateways:** Components that enable internet connectivity for eligible resources when routes and other requirements are configured.
- **Security groups:** Stateful virtual firewalls controlling inbound and outbound traffic for supported resources.
- **Network ACLs:** Stateless rules that control traffic at the subnet level.

A subnet is not automatically public merely because it is named `public`. Its routing and the resource's network configuration determine its connectivity.

### AWS IAM — Identity and Access Management

AWS Identity and Access Management (IAM) controls authentication and authorization for AWS resources.

IAM concepts include:
- **Users:** Identities for people or applications that need credentials.
- **Groups:** Collections of IAM users to simplify permission management.
- **Roles:** Identities that provide temporary credentials when assumed by an authorized principal.
- **Policies:** Documents defining allowed or denied actions on resources.

Security best practices include least-privilege permissions, avoiding unnecessary long-term credentials, and protecting root-user access.

### Amazon RDS — Managed Relational Databases

Amazon Relational Database Service (RDS) simplifies the setup, operation, and maintenance of supported relational databases.

**Common uses:**
- Application databases.
- Transactional workloads.
- Structured data storage.

A database can be placed in private subnets and protected through appropriately configured security groups. Private placement alone does not guarantee security; permissions, network paths, encryption, and other controls also matter.

### Amazon CloudWatch — Monitoring

Amazon CloudWatch provides monitoring and observability capabilities for AWS resources and applications.

It supports:
- Metrics.
- Logs.
- Alarms.
- Dashboards.

CloudWatch can help teams identify operational problems, monitor resource performance, and respond to configured alarm conditions.

## 6. Understanding a Basic AWS Web Architecture

A basic web application architecture can use several AWS services together.

### Conceptual Design

```text
                    Users
                      |
                   Internet
                      |
              Internet Gateway
                      |
          +-------------------------+
          |           VPC           |
          |                         |
          |    Public Subnet        |
          |    +-------------+      |
          |    | EC2 Web     |      |
          |    | Server      |      |
          |    +-------------+      |
          |           |             |
          |    Private Subnet       |
          |    +-------------+      |
          |    | Amazon RDS  |      |
          |    | Database   |      |
          |    +-------------+      |
          |                         |
          +-------------------------+

        IAM: Permissions and access control
        CloudWatch: Monitoring and logs
```

*This is a simplified conceptual diagram, not a complete production deployment.*

### Component Responsibilities

| Component | Responsibility |
|---|---|
| VPC | Provides a logically isolated network. |
| Public subnet | Hosts resources intended to have the required public connectivity. |
| EC2 | Runs the web application or web server. |
| Private subnet | Hosts resources that should not be directly reachable from the public internet. |
| Amazon RDS | Stores application data in a managed relational database. |
| Security groups | Restrict network traffic to approved connections. |
| IAM role | Grants an AWS resource the permissions it needs to access other AWS services. |
| CloudWatch | Collects monitoring data and supports alarms and operational visibility. |

### Example Traffic Flow

1. A user sends an HTTP or HTTPS request to the web application.
2. Network routing and security controls determine whether the request can reach the web server.
3. The EC2 instance processes the request.
4. When necessary, the application connects to the database using the required network access and database credentials.
5. CloudWatch collects configured metrics and logs for monitoring.

### Security Considerations

- Prefer HTTPS for public web traffic.
- Restrict administrative access instead of exposing management ports to the entire internet.
- Allow database connections only from authorized application resources.
- Keep the database off direct public access paths where possible.
- Grant IAM roles only the permissions required for their tasks.
- Enable appropriate encryption, logging, backups, and monitoring.
- Review security group rules and other network controls regularly.

A production-ready architecture may also require a load balancer, multiple Availability Zones, secure secret management, patching, automated backups, and disaster recovery measures.

## 7. AWS Shared Responsibility Model

AWS security follows a shared responsibility model.

AWS is responsible for security **of** the cloud, while customers are responsible for security **in** the cloud. The precise division depends on the service being used.

### AWS Responsibilities

These generally include:
- Physical security of AWS facilities.
- Hardware and underlying infrastructure.
- The foundational infrastructure supporting AWS services.

### Customer Responsibilities

Depending on the service, these may include:
- IAM permissions and account security.
- Data classification and protection.
- Network and security configuration.
- Operating-system patching on self-managed EC2 instances.
- Application security.
- Managing credentials and access to data.

For example, AWS manages the underlying physical infrastructure for EC2, but the customer is responsible for configuring the instance's operating system, installed software, and access permissions.

Managed services can reduce the customer's operational responsibilities, but they do not remove the need to configure access and protect data.

## 8. Key Takeaways

- Cloud computing provides on-demand access to computing resources.
- IaaS, PaaS, and SaaS differ in the services provided and the responsibilities retained by customers.
- Public, private, and hybrid clouds represent different deployment approaches.
- AWS Regions and Availability Zones are important for geographical placement and resilience.
- EC2, S3, VPC, IAM, RDS, and CloudWatch serve different infrastructure and operational purposes.
- A basic web architecture separates application compute from database resources and applies appropriate network controls.
- Security and operational responsibility is shared between AWS and the customer.

## 9. Further Hands-on Learning

The next step is to reinforce these concepts through practical exercises:

1. Explore the AWS Management Console and identify the core services discussed in these notes.
2. Review the architecture diagram and document the purpose of each component.
3. Investigate how VPCs, subnets, route tables, and security groups work together.
4. Examine IAM roles and policies, focusing on least privilege.
5. Explore EC2, S3, RDS, and CloudWatch through documentation or authorized lab environments.
6. If deploying resources, document the configuration, security controls, costs, and cleanup steps.

## References

- [AWS Cloud Computing](https://aws.amazon.com/what-is-cloud-computing/)
- [AWS Global Infrastructure](https://aws.amazon.com/about-aws/global-infrastructure/)
- [Amazon EC2](https://aws.amazon.com/ec2/)
- [Amazon S3](https://aws.amazon.com/s3/)
- [Amazon VPC](https://aws.amazon.com/vpc/)
- [AWS Identity and Access Management](https://aws.amazon.com/iam/)
- [Amazon RDS](https://aws.amazon.com/rds/)
- [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/)
- [AWS Shared Responsibility Model](https://aws.amazon.com/compliance/shared-responsibility-model/)

---

**Module:** 01 — AWS & Cloud Fundamentals  
**Program:** Codomax Digital Solutions — AWS Cloud & DevOps Internship
