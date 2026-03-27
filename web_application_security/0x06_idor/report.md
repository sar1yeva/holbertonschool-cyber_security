
# **CyberBank Web Application Security Assessment Report**

---

## **1. Introduction**

This report documents the findings of a comprehensive security assessment conducted on the CyberBank web application. The primary objective of this assessment was to identify vulnerabilities related to access control, transaction processing, and authentication mechanisms.

The testing focused particularly on **Insecure Direct Object Reference (IDOR)** vulnerabilities, business logic flaws in financial transactions, and weaknesses in the 3D Secure payment verification process.

The assessment was performed in a controlled lab environment, simulating real-world attack scenarios that could be exploited by malicious actors to compromise sensitive financial data and manipulate transactions.

---

## **2. Methodology**

The assessment followed a structured penetration testing methodology combining manual analysis and controlled exploitation techniques.

The primary tool used during testing was Burp Suite, utilizing the following features:

* Interception of HTTP/HTTPS traffic via Proxy
* Request modification using Repeater
* Traffic analysis through HTTP History
* Manual parameter manipulation
* Transaction flow analysis

The testing process included:

* Enumeration of user identifiers and account numbers
* API endpoint manipulation
* Authorization bypass attempts
* Transaction tampering
* Authentication flow analysis (3D Secure)

All tests were conducted with the goal of identifying weaknesses in:

* Access control enforcement
* Input validation
* Transaction integrity
* Authentication binding

---

## **3. Vulnerability Details**

---

### **3.1 Insecure Direct Object Reference (IDOR)**

#### **Description**

The application exposes direct references to internal objects such as account identifiers without enforcing proper authorization checks. By modifying these identifiers, an attacker can access resources belonging to other users.

#### **Technical Analysis**

The `api/accounts/info/{id}` endpoint returns account details based solely on the provided identifier, without verifying whether the authenticated user is authorized to access the requested resource.

This indicates a lack of server-side access control validation.

#### **Impact**

* Unauthorized access to sensitive financial information
* Exposure of account balances and transaction data
* Violation of user privacy
* Increased risk of targeted financial attacks

#### **Reproduction Steps**

1. Log in as a valid user
2. Send a request to retrieve account details:

```
api/accounts/info/1sd32....
```

3. Modify the account ID:

```
api/accounts/info/652q...
api/accounts/info/4rdf...
```

4. Observe that data from other users is returned without restriction

#### **Evidence**

* API responses showing account data of multiple users
* Lack of authorization checks in response behavior

---

### **3.2 Wire Transfer Manipulation (Business Logic Vulnerability)**

#### **Description**

The wire transfer functionality does not properly validate transaction logic, allowing manipulation of transfer parameters to artificially increase account balances.

#### **Technical Analysis**

The application processes transfer requests without enforcing strict validation on:

* Transaction amount (including negative values)
* Source and destination account relationships
* Ownership of accounts

This allows attackers to exploit logical flaws in transaction handling.

#### **Impact**

* Unauthorized increase of account balance
* Financial fraud
* Integrity compromise of the banking system
* Potential large-scale abuse

#### **Reproduction Steps**

1. Initiate a wire transfer via the dashboard
2. Intercept the request using Burp Suite
3. Modify parameters such as:

```json
{
  "from_account": "attacker_account",
  "to_account": "attacker_account",
  "amount": 1000
}
```

4. Test additional payloads:

   * Negative amounts
   * Large values
   * Transferring from unauthorized accounts
5. Send the modified request
6. Observe that the account balance increases unexpectedly

#### **Evidence**

* Modified request payloads
* Account balance exceeding expected limits (e.g., >10,000)
* Successful transaction responses despite invalid logic

---

### **3.3 3D Secure Verification Bypass**

#### **Description**

The 3D Secure authentication mechanism is improperly implemented. The OTP (One-Time Password) is not securely bound to the specific transaction or cardholder, allowing attackers to bypass authentication.

#### **Technical Analysis**

The OTP verification endpoint:

```
POST /api/cards/confirm_payment/{transaction_id}
```

accepts:

```json
{
  "otp": "...",
  "number": "card_number"
}
```

However, the backend fails to validate the relationship between:

* OTP and transaction
* OTP and card number
* OTP and authenticated user session

This allows cross-context authentication abuse.

#### **Impact**

* Unauthorized payment authorization
* Ability to charge other users’ cards
* Severe financial fraud risk
* Compromise of payment security mechanisms

#### **Reproduction Steps**

1. Initiate a payment using a victim’s card number
2. Trigger the 3D Secure verification process
3. In parallel, initiate a second payment using your own card
4. Receive a valid OTP for your own transaction
5. Intercept the OTP confirmation request:

```
POST /api/cards/confirm_payment/{transaction_id}
```

6. Modify the request:

```json
{
  "otp": "VALID_OTP_FROM_ATTACKER",
  "number": "VICTIM_CARD"
}
```

7. Ensure the session remains the attacker’s
8. Send the request
9. Observe that the transaction is successfully authorized

#### **Evidence**

* OTP accepted for a different card
* Successful transaction execution
* System failure to bind authentication context

---

## **4. Additional Findings**

During testing, the following additional security concerns were identified:

* Lack of strict input validation across multiple endpoints
* Predictable object identifiers enabling enumeration
* Insufficient linkage between authentication and authorization layers
* Weak error handling revealing internal logic (e.g., “Invalid card number”, “Invalid 3D Secure Code”)

These issues increase the likelihood of successful exploitation when combined with other vulnerabilities.

---

## **5. Recommendations**

---

### **Access Control (IDOR)**

* Implement strict server-side authorization checks
* Ensure object access is validated against the authenticated user
* Replace predictable IDs with secure identifiers (e.g., UUIDs)

---

### **Transaction Security**

* Enforce strict validation on all transaction parameters
* Prevent negative or invalid transaction values
* Validate ownership of source and destination accounts
* Implement transaction integrity checks

---

### **3D Secure Protection**

* Bind OTP to:

  * Specific transaction
  * Specific user session
  * Specific card number
* Reject OTP reuse across different contexts
* Implement multi-layer verification

---

### **General Security Improvements**

* Apply input validation and sanitization
* Implement logging and monitoring
* Introduce rate limiting
* Conduct regular penetration testing

---

## **6. Conclusion**

The CyberBank application contains multiple critical vulnerabilities related to access control, transaction processing, and authentication mechanisms.

These weaknesses allow attackers to:

* Access unauthorized user data
* Manipulate financial transactions
* Bypass secure payment verification systems

Immediate remediation is essential to ensure the security, integrity, and trustworthiness of the platform.

---

## **7. References**

* OWASP Top 10 (Broken Access Control, Business Logic Vulnerabilities)
* OWASP Web Security Testing Guide
* Burp Suite Documentation
* General Web Application Security Testing Practices


