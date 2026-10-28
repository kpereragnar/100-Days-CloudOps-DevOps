# AWS Basic Web Application Architecture

## 1. Overview

This document describes a conceptual AWS architecture for hosting a basic web application. It demonstrates how compute, networking, database, access control, and monitoring services can work together to support an application.

The architecture uses Amazon Virtual Private Cloud (VPC), Amazon EC2, Amazon RDS, AWS Identity and Access Management (IAM), and Amazon CloudWatch.

**Architecture type:** Conceptual design  
**Cloud provider:** Amazon Web Services (AWS)  
**Purpose:** Demonstrate fundamental AWS architecture and security concepts.

## 2. Architecture Diagram

The diagram below represents the proposed architecture. The PNG version will be stored in the `diagrams/` directory.

![AWS Basic Web Application Architecture](diagrams/aws-basic-architecture.png)

> **Note:** This diagram represents a conceptual design. It does not indicate that these resources have been deployed in an AWS account.

## 3. Architecture Components

| Component | AWS Service | Purpose |
|---|---|---|
| Virtual network | Amazon VPC | Provides a logically isolated network for application resources. |
| Public subnet | VPC subnet | Hosts the web server where the required public connectivity is configured. |
| Web server | Amazon EC2 | Runs the web server or application workload. |
| Private subnet | VPC subnet | Hosts the database without requiring direct public internet access. |
| Database | Amazon RDS | Provides managed relational database functionality. |
| Network access control | Security groups | Controls permitted inbound and outbound network traffic. |
| Identity and permissions | AWS IAM | Defines permissions for users, services, and AWS resources. |
| Monitoring | Amazon CloudWatch | Collects configured metrics and logs and supports alarms. |
| Internet connectivity | Internet gateway | Provides an internet connectivity path for eligible resources when routing and other network settings permit it. |

## 4. Network Design

### Amazon VPC

The VPC provides the logical network boundary for the application resources. It contains the subnets and associated networking configurations.

### Public Subnet

The public subnet is intended to host the EC2 web server. Its route table must provide a route to an internet gateway for the required internet connectivity.

For a publicly accessible web server, the instance also needs appropriate addressing and security configuration.

### Private Subnet

The private subnet is intended to host the Amazon RDS database. The database should not require direct public internet access for normal application operation.

The application must have an approved network path to the database, and the database security group should permit connections only from authorized application resources.

**Important:** A subnet's name does not determine whether it is public or private. Routing and resource configuration determine its actual connectivity.

## 5. Traffic Flow

The expected application traffic flow is:

1. A user sends an HTTP or HTTPS request to the web application.
2. The network routing configuration directs eligible traffic toward the EC2 web server.
3. Security group rules determine whether the connection is permitted.
4. The EC2 instance processes the request.
5. If the application requires persistent data, it connects to Amazon RDS over an authorized network path.
6. Amazon RDS processes the database request and returns the result to the application.
7. The application returns the response to the user.
8. Configured CloudWatch metrics and logs provide operational visibility.

The exact traffic path depends on the final network configuration and whether additional components, such as a load balancer, are introduced.

## 6. Security Considerations

### Network Security

- Allow only the inbound ports required by the application.
- Prefer HTTPS for public application traffic.
- Restrict SSH or other administrative access to authorized sources.
- Configure the database security group to accept connections only from the application tier.
- Avoid exposing the database directly to the public internet.

### Identity and Access Management

- Apply least-privilege permissions.
- Use an IAM role for the EC2 instance when it needs to access other AWS services.
- Avoid embedding long-term AWS credentials in application code.
- Protect privileged accounts and review permissions regularly.

### Data Protection

- Use encryption for data at rest and in transit where appropriate.
- Configure database backups and retention according to recovery requirements.
- Protect application secrets and database credentials.
- Restrict access to stored data through appropriate IAM and resource policies.

### Monitoring

- Configure CloudWatch metrics and logs for relevant resources.
- Establish alarms for important operational conditions.
- Review logs for errors and unexpected activity.
- Monitor resource utilization to identify potential performance problems.

## 7. Limitations and Production Considerations

This is a simplified architecture intended for learning AWS fundamentals. Before using a similar design in production, additional decisions would be necessary.

Potential enhancements include:

- Deploying the application across multiple Availability Zones.
- Using an Application Load Balancer to distribute incoming requests.
- Implementing Auto Scaling where appropriate.
- Configuring secure secrets management.
- Defining backup, restoration, and disaster recovery procedures.
- Reviewing availability, performance, and cost requirements.
- Establishing appropriate logging, alerting, and incident-response procedures.

These enhancements are recommendations, not components confirmed to exist in the conceptual design.

## 8. Conclusion

This architecture illustrates the relationship between AWS networking, compute, database, identity, and monitoring services. Separating the web and database tiers provides a foundation for applying network access controls and reducing unnecessary exposure.

The exercise reinforces the importance of designing cloud infrastructure with security, operational visibility, and future scalability in mind.

## 9. References

- [Amazon VPC](https://aws.amazon.com/vpc/)
- [Amazon EC2](https://aws.amazon.com/ec2/)
- [Amazon RDS](https://aws.amazon.com/rds/)
- [AWS IAM](https://aws.amazon.com/iam/)
- [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/)
- [AWS Shared Responsibility Model](https://aws.amazon.com/compliance/shared-responsibility-model/)

---

**Module:** 01 — AWS & Cloud Fundamentals  
**Program:** Codomax Digital Solutions — AWS Cloud & DevOps Internship

