🛰 Passive Reconnaissance Report
-----
## Target: **holbertonschool.com**

**Tool Used:** Shodan
**Reconnaissance Type:** Passive (OSINT)

---

## 1. Executive Summary

This report presents the results of a **passive reconnaissance** operation conducted on the domain **holbertonschool.com** using **Shodan**.
The objective was to identify:

* Publicly exposed IP addresses and infrastructure
* IP ranges associated with the domain
* Subdomains discovered via Shodan
* Technologies, services, and frameworks in use
* SSL/TLS configurations

All data was collected **without direct interaction** with the target systems.

---

## 2. Methodology

The following Shodan techniques were used:

* Reverse DNS lookup
* Hostname and SSL certificate analysis
* HTTP banner inspection
* Infrastructure metadata extraction (ASN, cloud provider, geolocation)

Example Shodan queries:

```text
hostname:holbertonschool.com
ssl.cert.subject.cn:holbertonschool.com
```

---

## 3. Identified IP Addresses & Infrastructure

### 3.1 Public IP Addresses

| IP Address        | Reverse DNS                                       | Cloud Provider | ASN Owner                   | Location      |
| ----------------- | ------------------------------------------------- | -------------- | --------------------------- | ------------- |
| **35.180.27.154** | ec2-35-180-27-154.eu-west-3.compute.amazonaws.com | Amazon AWS     | Amazon Data Services France | Paris, France |
| **52.47.143.83**  | ec2-52-47-143-83.eu-west-3.compute.amazonaws.com  | Amazon AWS     | Amazon Data Services France | Paris, France |

### 3.2 IP Ranges (Inferred)

Based on AWS infrastructure and region (`eu-west-3`):

```
35.180.0.0/16
52.47.0.0/16
```

> These CIDR blocks belong to **Amazon Web Services (AWS)** and are used for cloud-hosted services.

---

## 4. Subdomains Identified

The following subdomain was discovered through SSL certificate analysis:

```
yriry2.holbertonschool.com
```

This subdomain appears to host internal or forum-related content.

---

## 5. Services & Technologies Detected

### 5.1 Web Services Overview

| Host                       | Port | Protocol | HTTP Status | Redirect                                                                   |
| -------------------------- | ---- | -------- | ----------- | -------------------------------------------------------------------------- |
| 35.180.27.154              | 80   | HTTP     | 301         | → [http://holbertonschool.com](http://holbertonschool.com)                 |
| 52.47.143.83               | 80   | HTTP     | 301         | → [https://yriry2.holbertonschool.com](https://yriry2.holbertonschool.com) |
| yriry2.holbertonschool.com | 443  | HTTPS    | 200         | No                                                                         |

---

### 5.2 Web Server & Frameworks

| Component         | Detected Technology  |
| ----------------- | -------------------- |
| Web Server        | **nginx**            |
| nginx Version     | 1.18.0, 1.21.6       |
| Operating System  | Ubuntu               |
| Hosting Platform  | AWS EC2              |
| Redirect Handling | HTTP 301 (Permanent) |

---

## 6. SSL / TLS Analysis

### SSL Certificate Details

| Field                  | Value                      |
| ---------------------- | -------------------------- |
| Issuer                 | Let’s Encrypt              |
| Certificate Type       | Domain Validated (DV)      |
| Common Name (CN)       | yriry2.holbertonschool.com |
| Supported TLS Versions | TLSv1.2, TLSv1.3           |

The presence of **Let’s Encrypt** and **modern TLS versions** indicates proper encryption practices.

---

## 7. HTTP Security Headers Observed

From `yriry2.holbertonschool.com`:

| Header                 | Value      |
| ---------------------- | ---------- |
| X-Frame-Options        | SAMEORIGIN |
| X-XSS-Protection       | 0          |
| X-Content-Type-Options | nosniff    |
| X-Download-Options     | noopen     |

> ⚠ `X-XSS-Protection: 0` disables browser-based XSS filtering.

---

## 8. Observations & Analysis

* Holberton School infrastructure is **hosted on AWS (eu-west-3 / Paris)**.
* **nginx** is used consistently as the web server.
* HTTP traffic is redirected using **301 Moved Permanently**, indicating enforced canonical URLs.
* TLS configuration supports **modern encryption standards**.
* At least one subdomain (`yriry2`) appears to serve forum or internal content.

---

## 9. Security Posture Assessment

### Positive Findings

✅ HTTPS enabled
✅ TLS 1.2 / 1.3 supported
✅ Reputable cloud provider (AWS)
✅ Proper use of HTTP redirects

### Potential Improvements

⚠ Review XSS protection headers
⚠ Audit exposed subdomains for necessity
⚠ Minimize information disclosure in HTTP banners

---

## 10. Conclusion

This passive reconnaissance exercise demonstrates that **holbertonschool.com** maintains a modern cloud-based infrastructure with secure transport encryption.
No direct vulnerabilities were exploited or tested, in accordance with passive reconnaissance principles.

---

## 11. References

* Shodan Search Engine — [https://www.shodan.io](https://www.shodan.io)
* AWS EC2 Infrastructure
* Let’s Encrypt Documentation
##

Yaxshi Sariyeva
