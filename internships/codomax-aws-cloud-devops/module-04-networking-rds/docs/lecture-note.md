Module 04: AWS Networking & Amazon RDS
Overview
This module covers the networking foundations for deploying AWS workloads securely and introduces Amazon Relational Database Service (RDS). The central design exercise is an application running on Amazon EC2 that connects privately to an RDS database inside an Amazon Virtual Private Cloud (VPC).
1. Amazon VPC and Networking Fundamentals
An Amazon VPC is a logically isolated virtual network in an AWS Region. It lets you define an IP address range and control subnets, routing, and network access for resources deployed inside it.

Key terms:
- IP address: Identifies a resource on a network.
- CIDR block: Defines an IP range, e.g. 10.0.0.0/16.
- Subnet: A smaller IP range inside a VPC. Each subnet belongs to one Availability Zone.
- Route table: Rules that determine where network traffic is sent.
- Internet Gateway (IGW): A VPC component that provides a target for internet-bound routes.
- Availability Zone (AZ): An isolated location within an AWS Region.
- Private IP: Used for communication within private networks.
- Public IP: An internet-routable address; routing and security rules must also permit connectivity.
Example VPC address plan:
Subnet	CIDR	Purpose
Public A	10.0.1.0/24	Internet-facing entry point
Public B	10.0.2.0/24	Resilient entry point in another AZ
Private app A	10.0.11.0/24	Application servers
Private app B	10.0.12.0/24	Application servers in another AZ
Private DB A	10.0.21.0/24	Database resources
Private DB B	10.0.22.0/24	Database resources in another AZ


Plan CIDR ranges carefully; they should not overlap with each other or networks that must communicate with the VPC.
2. VPCs, Subnets, Route Tables, and Internet Gateways
VPC
A VPC is the network boundary for resources such as EC2 instances and RDS databases. A VPC is regional; each subnet is associated with one AZ.
Subnets
Subnets divide the VPC address range. A subnet is not public merely because of its name: its associated route table determines whether it has a route to an Internet Gateway.
Route tables
A route table contains destination-and-target rules. Every VPC has a main route table; a subnet uses the main table unless explicitly associated with another table.

Example public-subnet routes:
Destination	Target	Purpose
10.0.0.0/16	local	VPC-internal communication
0.0.0.0/0	Internet Gateway	IPv4 internet-bound traffic


The local route is created automatically for communication within the VPC.
Internet Gateway
An IGW is attached to a VPC and is the target for public-subnet internet routes. Attaching an IGW alone does not make every resource publicly reachable.

For an EC2 instance to communicate directly with the internet over IPv4, it generally needs:
- An attached IGW on its VPC.
- A subnet route to that IGW.
- A public IPv4 address or Elastic IP.
- Permissive security group and network ACL rules.
- A running service and suitable operating-system firewall rules.
3. Public and Private Subnets
Public subnet
A subnet is public when its associated route table has a route to an IGW, commonly 0.0.0.0/0 -> igw-... for IPv4.

Typical resources include internet-facing load balancers, controlled bastion hosts, and NAT Gateways.
Private subnet
A private subnet has no direct route to an IGW. It commonly hosts application servers, databases, and internal services. Private resources can use a NAT Gateway in a public subnet for outbound internet access when required; a NAT Gateway does not allow unsolicited inbound internet connections to those private resources.
Feature	Public subnet	Private subnet
Direct route to IGW	Usually yes	No
Typical workloads	Internet-facing entry points	Application and database tiers
Direct inbound internet access	Possible if other conditions permit	Not directly through an IGW
Outbound internet	Through IGW when configured	Often through NAT Gateway, if needed


A public route does not automatically make every resource in a public subnet accessible from the internet.
4. Security Groups and Basic Network Security
A Security Group (SG) is a stateful virtual firewall attached to supported AWS resources, such as EC2 and RDS network interfaces.
- Inbound rules: Traffic allowed into a resource.
- Outbound rules: Traffic allowed out of a resource.
- Protocol/port: For example TCP 443 for HTTPS, 3306 for MySQL, or 5432 for PostgreSQL.
- Source/destination: Can include IP ranges or another security group.
Because security groups are stateful, response traffic for an allowed connection is automatically permitted.
EC2-to-RDS example
- Application SG (app-sg): Allow application traffic from the load balancer SG. Allow outbound database traffic to db-sg on the database engine's port.
- Database SG (db-sg): Allow inbound TCP 3306 from app-sg for MySQL, or TCP 5432 for PostgreSQL.
- Do not open database ports to 0.0.0.0/0.
Security best practices
- Apply least privilege.
- Avoid unrestricted SSH (22) or RDP (3389) inbound rules.
- Permit database connections only from the application tier that needs them.
- Prefer security-group references over broad IP ranges for tier-to-tier access.
- Keep databases in private subnets.
- Review rules regularly.
- Consider AWS Systems Manager Session Manager or another controlled administration path instead of broadly exposing SSH.
5. Amazon RDS and Cloud Databases
Amazon Relational Database Service (Amazon RDS) is a managed service for relational databases. AWS handles many routine database administration tasks so teams can focus on applications and data.

Supported engines include:
- Amazon Aurora
- PostgreSQL
- MySQL
- MariaDB
- Oracle Database
- Microsoft SQL Server
Availability, versions, features, and pricing vary by engine and Region.
What AWS manages
Depending on the engine and configuration, RDS can manage database provisioning, automated backups and point-in-time recovery, maintenance and patching, monitoring metrics, and Multi-AZ availability options.
What the customer manages
Customers remain responsible for schema design, queries, database users and permissions, capacity choices, data classification, application security, and testing backup restoration.
Important RDS concepts
- DB instance: The managed database environment.
- DB subnet group: A collection of subnets in which RDS can place database network interfaces. For Multi-AZ designs, include subnets in at least two AZs.
- Publicly accessible: Determines whether the DB instance can have a public address. Application databases should generally not be publicly accessible.
- Multi-AZ deployment: Provides a standby in another AZ for high availability and failover; it is not the same as read scaling.
- Read replica: Can scale read workloads in supported configurations; it is not a replacement for backups.
- Automated backups: Support point-in-time recovery within the configured retention period.
- Encryption: Use encryption at rest and TLS for connections as appropriate to the engine and application.
6. Application Architecture Using EC2 and RDS
A common secure design separates the internet-facing entry point, application tier, and database tier.
                         Internet
                            |
                     Internet Gateway
                            |
                Public Subnets (AZ-a / AZ-b)
                            |
                 Application Load Balancer
                            |
                Private Application Subnets
                    EC2 Application Servers
                            |
                 Private Database Subnets
                            |
                     Amazon RDS
                  (Not publicly accessible)
Request and data flow
1. A user sends an HTTPS request to an application entry point, commonly an Application Load Balancer in public subnets.
2. The load balancer forwards permitted application traffic to EC2 instances in private application subnets.
3. The application connects to RDS through its private endpoint.
4. The database security group allows the database port only from the application security group.
5. Responses return over the established connections.
Architecture components
Component	Placement	Responsibility
VPC	AWS Region	Isolated network boundary
Internet Gateway	Attached to VPC	Internet connectivity for public routes
Public subnets	Across AZs	Host internet-facing load balancer
Private app subnets	Across AZs	Host EC2 application servers
Private DB subnets	Across AZs	Network placement for RDS
Application Load Balancer	Public subnets	Distributes incoming application traffic
EC2	Private app subnets	Runs application code
Amazon RDS	Private DB subnets	Stores relational application data
Security Groups	Resource network interfaces	Restricts traffic between tiers


Design and security considerations
- Do not expose RDS directly to the public internet.
- Keep application and database resources in private subnets.
- Allow only the required application-to-database port.
- Use HTTPS for client-to-application traffic.
- Store database credentials securely, for example with AWS Secrets Manager.
- Enable backups and choose an appropriate retention period.
- Consider Multi-AZ for production availability.
- Use NAT Gateways only when private resources need outbound internet access; include their cost in the design.
- Monitor application and database health with CloudWatch metrics and logs.
Key Takeaways
1. A VPC provides an isolated network for AWS resources.
2. Subnets divide a VPC's IP range, and each subnet belongs to one AZ.
3. Route tables determine where subnet traffic is sent.
4. A public subnet has a route to an IGW; a private subnet does not.
5. Security Groups are stateful firewalls and should follow least-privilege rules.
6. Amazon RDS is a managed relational database service.
7. A secure EC2–RDS architecture keeps the database private and allows database access only from the application tier.
Suggested Hands-on Follow-up
To reinforce the theory:
- Create a custom VPC with public and private subnets across two AZs.
- Create and associate route tables.
- Attach an IGW and configure public-subnet routing.
- Create separate application and database security groups.
- Review an RDS DB subnet group and, if lab budget and permissions allow, deploy a non-production RDS instance.
- Document the traffic flow and test only the intended connectivity.
Cost and security note: NAT Gateways, EC2 instances, load balancers, and RDS instances can incur charges. Check current AWS pricing, use the smallest suitable lab configuration, and delete billable resources after the exercise. Never expose a database publicly just to simplify a connectivity test.
