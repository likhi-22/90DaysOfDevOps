# Week 1: Networking Challenge

> **Topics covered:** OSI & TCP/IP Models · Protocols & Ports · AWS Security Groups · CLI Cheat Sheet

---

## Table of Contents

1. [Task 1 – OSI & TCP/IP Models](#task-1--osi--tcpip-models)
2. [Task 2 – Protocols and Ports for DevOps](#task-2--protocols-and-ports-for-devops)
3. [Task 3 – AWS EC2 and Security Groups](#task-3--aws-ec2-and-security-groups)
4. [Task 4 – Networking Commands Cheat Sheet](#task-4--networking-commands-cheat-sheet)

---

## Task 1 – OSI & TCP/IP Models

### 1.1 The OSI Model

The OSI (Open Systems Interconnection) model is a conceptual framework that standardises how different network systems communicate. It divides networking into seven distinct layers, each with a specific responsibility.

| Layer | Purpose | Key Protocols | Real-World Example |
|---|---|---|---|
| **7 – Application** | End-user interface for network services | HTTP/S, FTP, DNS, SMTP | User opens browser → HTTP request sent |
| **6 – Presentation** | Data formatting, encryption, compression | SSL/TLS, JPEG, JSON | TLS handshake encrypts HTTPS traffic |
| **5 – Session** | Manage sessions between applications | NetBIOS, RPC | SSH maintains a persistent terminal session |
| **4 – Transport** | Reliable delivery, flow control, ports | TCP, UDP | TCP ensures packets arrive in order |
| **3 – Network** | Logical addressing and routing | IP, ICMP, OSPF | Router forwards packet based on IP address |
| **2 – Data Link** | Node-to-node delivery, MAC addressing | Ethernet, ARP, Wi-Fi | Switch delivers frame to correct MAC address |
| **1 – Physical** | Bit transmission over physical medium | Cables, Fiber, Radio waves | Electric signal travels through network cable |

---

### 1.2 The TCP/IP Model

The TCP/IP model is the practical, four-layer framework that underpins the modern internet and cloud networking. Unlike OSI, it maps directly to real protocol implementations.

| Layer | Responsibility | Key Protocols | DevOps Example |
|---|---|---|---|
| **Application** | User-facing data + application protocols | HTTP, HTTPS, DNS, FTP, SMTP, SSH | Nginx serves a web page over HTTP |
| **Transport** | End-to-end communication, port management | TCP (reliable), UDP (fast) | TCP delivers file upload completely |
| **Internet** | Packet routing across networks | IP, ICMP, ARP | `ping` uses ICMP to test reachability |
| **Network Access** | Physical transmission of frames | Ethernet, Wi-Fi, Fiber | NIC sends bits to network switch |

---

### 1.3 OSI vs TCP/IP – Key Differences

- OSI has 7 layers; TCP/IP consolidates these into 4 layers.
- OSI is a conceptual reference model; TCP/IP is the standard actually implemented in systems.
- OSI separates Presentation and Session concerns; TCP/IP folds them into the Application layer.
- Both models share the Transport and Network (Internet) layer concepts.
- As a DevOps engineer, you will debug at the **Application** and **Transport** layers most frequently.

---

## Task 2 – Protocols and Ports for DevOps

The table below lists the protocols most relevant to DevOps workflows, their standard ports, and where they appear in day-to-day infrastructure work.

| Protocol | Port | Transport | OSI Layer | Purpose | DevOps Relevance |
|---|---|---|---|---|---|
| **HTTP** | 80 | TCP | Application | Transfers web content (HTML, JSON, APIs). | REST API calls, health checks, web app serving |
| **HTTPS** | 443 | TCP | Application | Encrypted HTTP using TLS. Standard for all production traffic. | All web traffic, CI/CD webhooks, cloud APIs |
| **FTP** | 20/21 | TCP | Application | File transfer. Use SFTP in production (FTP is unencrypted). | Legacy file deployments (prefer SFTP/S3) |
| **SSH** | 22 | TCP | Application | Secure remote shell and encrypted file transfer. | Server access, git push, Ansible, SCP/SFTP |
| **DNS** | 53 | UDP/TCP | Application | Resolves human-readable hostnames to IP addresses. | Service discovery, load balancer routing, CDN |
| **SMTP** | 25/587 | TCP | Application | Sends email. Port 587 used for authenticated submission. | Alert notifications, CI/CD failure emails |
| **DHCP** | 67/68 | UDP | Application | Dynamically assigns IP addresses to hosts. | EC2 instances get private IPs on launch |
| **NTP** | 123 | UDP | Application | Synchronizes clocks across systems. | Log timestamps, SSL cert validation, Kubernetes |
| **ICMP** | — | ICMP | Network | Carries diagnostic messages (ping, traceroute). | Health probes, network troubleshooting |
| **TCP** | — | TCP | Transport | Reliable, ordered delivery with error checking. | HTTP/S, SSH, any data integrity use case |
| **UDP** | — | UDP | Transport | Low-latency, connectionless, no delivery guarantee. | DNS, monitoring metrics, video streaming |

---

### 2.1 DevOps Workflow Mapping

**CI/CD Pipeline**
- HTTPS (443) – GitHub webhooks, artifact registries
- SSH (22) – Ansible playbooks, remote runners
- FTP/SFTP – Legacy artifact uploads

**Cloud Infrastructure**
- DNS (53) – Service discovery, load balancers
- HTTPS (443) – AWS/GCP/Azure API calls
- DHCP (67/68) – Dynamic IP on EC2 boot

**Observability**
- UDP (custom) – Prometheus metrics scrape
- HTTPS (443) – Grafana, Datadog, CloudWatch
- SMTP (587) – Alert email notifications

---

## Task 3 – AWS EC2 and Security Groups

### What Is a Security Group?

A **Security Group (SG)** is a virtual stateful firewall attached to AWS resources (EC2, RDS, Lambda, etc.). It controls inbound and outbound traffic at the instance level using **allow rules only** — there are no explicit deny rules. Because SGs are stateful, return traffic for allowed inbound connections is automatically permitted.

---

### Step-by-Step: Launch an EC2 Instance and Configure a Security Group

#### Step 1 – Sign in and navigate to EC2

- Open the AWS Management Console and sign in.
- In the search bar, type **EC2** and open the EC2 Dashboard.
- Confirm you are in your intended region (top-right dropdown).

#### Step 2 – Launch a new EC2 instance

- Click **Launch Instance**.
- Set Name: e.g., `devops-week1-server`.
- Choose **Amazon Linux 2023 AMI** (Free Tier eligible).
- Select instance type **t2.micro** (Free Tier eligible).
- Under **Key pair**, create a new key pair (RSA, `.pem` format) and download it. Store it securely.

#### Step 3 – Create a new Security Group

- In the **Network settings** panel, click **Edit**.
- Click **Create security group** and give it a meaningful name: e.g., `devops-week1-sg`.
- Add a description: `Allow SSH and HTTP for Week 1 DevOps challenge`.

#### Step 4 – Add inbound rules

| Rule Type | Protocol | Port | Source/Dest | Purpose |
|---|---|---|---|---|
| Inbound | TCP | 22 | Your IP/32 | SSH access restricted to your IP only. Never use `0.0.0.0/0`. |
| Inbound | TCP | 80 | 0.0.0.0/0 | Allow HTTP traffic from anywhere (redirect to HTTPS). |
| Inbound | TCP | 443 | 0.0.0.0/0 | Allow HTTPS traffic from anywhere. |
| Inbound | TCP | 8080 | App SG ID | Allow traffic only from your application security group. |
| Outbound | All | All | 0.0.0.0/0 | Default: allow all outbound. Restrict in high-security environments. |

> **Security Best Practices**
> - Never open port 22 (SSH) to `0.0.0.0/0` in production. Always restrict to your office or VPN IP range.
> - Use separate Security Groups per tier (web, app, database). Reference SG IDs, not CIDR blocks, for internal rules.
> - Audit Security Groups regularly. Remove unused rules. Apply the least-privilege principle.
> - Enable **VPC Flow Logs** to capture allowed and rejected traffic for auditing.
> - Consider **AWS Network ACLs** (stateless) as an additional layer at the subnet level.

#### Step 5 – Review and launch

- Review all settings. Click **Launch Instance**.
- Navigate to **Instances** and wait for the Status Check to show `2/2 checks passed`.
- Note the **Public IPv4 address**.

#### Step 6 – Connect via SSH

```bash
# Set correct permissions on your key file (Linux/macOS)
chmod 400 ~/Downloads/your-key.pem

# Connect to the instance
ssh -i ~/Downloads/your-key.pem ec2-user@<Public-IPv4>
```

---

## Task 4 – Networking Commands Cheat Sheet

Essential CLI tools for network diagnostics. Examples are tested on Linux (Amazon Linux / Ubuntu). macOS equivalents are noted where different.

| Command | Syntax Example | What It Does | DevOps Use Case |
|---|---|---|---|
| `ping` | `ping google.com` | Sends ICMP echo requests to test host reachability and measure round-trip time. | Verify server is reachable; baseline latency before/after deployments |
| `traceroute` | `traceroute 8.8.8.8` | Shows each network hop between source and destination with latency per hop. | Diagnose routing issues, identify network bottlenecks between services |
| `netstat` | `netstat -tulpn` | Displays open ports, active connections, and associated processes. | Confirm a service is listening on the correct port; detect unexpected connections |
| `curl` | `curl -I https://example.com` | Makes HTTP/S requests from the CLI; shows headers, status codes, and response body. | Test APIs, health endpoints, check SSL certs, debug microservice responses |
| `dig` | `dig A example.com` | Performs detailed DNS lookups with query type control and server selection. | Verify DNS propagation, debug service discovery, check TTL values |
| `nslookup` | `nslookup example.com` | Simple DNS name resolution tool for quick lookups. | Quick hostname-to-IP verification; works on Windows and Linux |
| `ss` | `ss -tulpn` | Modern replacement for netstat. Faster, more detail on socket state. | Preferred over netstat on modern Linux systems for port inspection |
| `ip` | `ip addr show` | Manages and displays network interfaces, routes, and addresses. | Check instance IP assignments, add routes, configure VPC NICs |

---

### 4.1 Command Examples with Annotations

#### `ping` – Connectivity and Latency

```bash
# Basic reachability test
ping -c 4 google.com

# Continuous ping (useful for monitoring during maintenance)
ping 10.0.1.50

# Specify packet size (useful for MTU troubleshooting)
ping -s 1400 -c 3 192.168.1.1
```

> Key output fields: `icmp_seq` (sequence), `ttl` (Time to Live), `time` (round-trip ms), packet loss %.

---

#### `traceroute` – Route Tracing

```bash
# Trace path to a host (Linux)
traceroute google.com

# Use TCP instead of UDP (better for firewalled paths)
traceroute -T -p 443 google.com

# Windows equivalent
tracert google.com
```

> Each line shows a hop (router). `* * *` means the hop did not respond (firewall or ICMP blocked). Focus on where latency spikes.

---

#### `netstat` / `ss` – Open Ports and Connections

```bash
# Show listening TCP/UDP ports with process names (requires sudo)
sudo netstat -tulpn

# Modern alternative (faster, preferred)
sudo ss -tulpn

# Filter for a specific port
sudo ss -tulpn | grep :443

# Show established connections
ss -tn state established
```

> Flags: `-t` TCP, `-u` UDP, `-l` Listening, `-p` Process, `-n` Numeric (no DNS resolution).

---

#### `curl` – HTTP/S Testing

```bash
# Check HTTP response headers and status code
curl -I https://example.com

# Full request with verbose output (TLS handshake visible)
curl -v https://api.myservice.com/health

# POST JSON to an API endpoint
curl -X POST https://api.example.com/v1/data \
     -H 'Content-Type: application/json' \
     -d '{"key": "value"}'

# Test with a custom Host header (useful behind load balancers)
curl -H 'Host: myapp.internal' http://10.0.1.25/health

# Follow redirects and show final URL
curl -L -o /dev/null -s -w '%{url_effective}\n' http://example.com
```

> Use `-I` (HEAD) for quick checks. Use `-v` to debug TLS/certificate issues. Use `-w` to measure connection timing.

---

#### `dig` – DNS Lookup

```bash
# Standard A record lookup
dig A example.com

# Query a specific DNS server (bypass local cache)
dig @8.8.8.8 example.com

# Check MX (mail) records
dig MX example.com

# Check CNAME (alias) records
dig CNAME www.example.com

# Check TTL values (important during DNS migrations)
dig +nocmd example.com any +multiline +noall +answer

# Reverse DNS lookup
dig -x 8.8.8.8
```

> The `ANSWER SECTION` shows resolved records. The `AUTHORITY SECTION` identifies authoritative name servers. TTL shows seconds until cache expiry.

---

#### `nslookup` – Quick DNS Resolution

```bash
# Simple lookup
nslookup example.com

# Query against a specific DNS server
nslookup example.com 1.1.1.1

# Look up a specific record type
nslookup -type=MX example.com
```

---

### 4.2 Troubleshooting Workflow

When a service is unreachable, follow this structured sequence:

1. **`ping <host>`** – Is the host reachable at all? Is ICMP blocked?
2. **`dig` / `nslookup`** – Does DNS resolve to the correct IP?
3. **`traceroute`** – Where does the path fail or latency spike?
4. **`curl -v`** – Is the application responding on the expected port with the correct status?
5. **`ss -tulpn`** – Is the process actually listening on the expected port on the server?

---
