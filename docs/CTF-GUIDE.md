# 🏁 CTF & Security Tools Guide

This guide covers the security and CTF-specific tools and workflows included in your dotfiles setup.

## 🔍 Quick CTF Commands

### Network Reconnaissance
```bash
# Quick port scan
portscan target.com

# Fast mass scan
masscanfast target.com

# Nmap with scripts
nmapquick target.com
nmapfull target.com
```

### Web Application Testing
```bash
# Directory enumeration
webenum http://target.com
dirbuster -u http://target.com -w /usr/share/wordlists/dirb/common.txt

# Web analysis
whatweb target.com
```

### File Analysis & Forensics
```bash
# Complete file analysis
ctf-extract suspicious_file.bin

# Quick file info
fileinfo mysterious_file
entropy suspicious_file.bin

# String analysis
strings binary_file | grep -i flag
```

### Cryptography & Encoding
```bash
# Base64 auto-detect and convert
b64 "SGVsbG8gV29ybGQ="

# Hash identification
hashid "5d41402abc4b2a76b9719d911017c592"

# Quick hashing
echo "password" | md5
echo "password" | sha256
```

### Reverse Engineering
```bash
# Disassembly with Radare2
r2 -A binary_file

# Debugging with GDB
gdb ./binary_file

# Ghidra (GUI)
ghidra
```

## 🐚 Reverse Shells & Listeners

### Generate Reverse Shell Payloads
```bash
# Get various reverse shell payloads
revshell 10.10.10.10 4444
```

### Set Up Listeners
```bash
# Quick netcat listener
listen 4444

# Advanced listeners with logging
nc -nlvp 4444 | tee session.log
```

## 💉 SQL Injection

### Common Payloads
```bash
# Display SQL injection payloads
sqli
```

### Manual Testing
```bash
# Basic SQLi tests
' OR '1'='1
' OR 1=1--
admin'--

# Union-based
' UNION SELECT null,null,null--
' UNION SELECT 1,user(),database()--
```

## 🏗️ CTF Workspace Management

### Create Challenge Workspace
```bash
# Set up organized CTF workspace
ctf-workspace "hackthebox-machine-name"
```

This creates:
```
~/ctf/hackthebox-machine-name/
├── scripts/     # Custom scripts
├── files/       # Downloaded files
├── notes/       # Challenge notes
├── exploits/    # Exploit code
├── wordlists/   # Custom wordlists
└── notes/README.md  # Auto-generated notes template
```

## 🔧 Tool Configurations

### Burp Suite Setup
```bash
# Launch Burp Suite Community
burpsuite

# Configure proxy: 127.0.0.1:8080
# Import CA certificate for HTTPS interception
```

### Browser Configuration
```bash
# Firefox with proxy
firefox --new-instance --profile-manager

# Chromium with proxy
chromium --proxy-server="127.0.0.1:8080"
```

## 🐍 Python Security Tools

### Pwntools Examples
```python
from pwn import *

# Connect to service
r = remote('target.com', 1337)

# Craft payload
payload = b'A' * 64 + p64(0xdeadbeef)
r.sendline(payload)
```

### Scapy Network Analysis
```python
from scapy.all import *

# Packet capture
packets = sniff(count=10)

# Craft custom packet
packet = IP(dst="target.com")/TCP(dport=80)
send(packet)
```

## 🗂️ Installed Security Tools

### Network Analysis
- **Nmap** - Network mapper and port scanner
- **Masscan** - Fast port scanner
- **Wireshark** - Network protocol analyzer

### Web Security
- **Burp Suite** - Web application security testing
- **Gobuster** - Directory/file brute-forcer
- **DIRB** - Web content scanner

### Reverse Engineering
- **Ghidra** - NSA's reverse engineering suite
- **Radare2** - Advanced command-line RE framework
- **GDB** - GNU debugger with scripting

### Cryptography
- **Hashcat** - Advanced password recovery
- **John the Ripper** - Password cracker
- **Steghide** - Steganography tool

### Forensics
- **Binwalk** - Firmware analysis tool
- **Volatility3** - Memory forensics framework

### Python Libraries
- **Pwntools** - CTF framework and exploit development
- **Scapy** - Interactive packet manipulation
- **Impacket** - Network protocol implementations
- **Requests** - HTTP library for Python

## 🎓 CTF Workflow Example

### 1. Initial Reconnaissance
```bash
# Create workspace
ctf-workspace "example-challenge"

# Port scan
portscan target.com

# Web enumeration
webenum http://target.com
```

### 2. File Analysis
```bash
# Download and analyze files
wget http://target.com/file.bin
ctf-extract file.bin
```

### 3. Exploitation
```bash
# Generate payloads
revshell 10.10.10.10 4444

# Set up listener in another terminal
listen 4444
```

### 4. Documentation
```bash
# Edit notes (auto-created in workspace)
nvim notes/README.md
```

## 🔗 Useful Resources

### Wordlists
- **SecLists**: `/usr/share/seclists/` (install separately)
- **Dirb**: `/usr/share/wordlists/dirb/`
- **Rockyou**: `/usr/share/wordlists/rockyou.txt`

### Online Resources
- **GTFOBins**: https://gtfobins.github.io/
- **PayloadsAllTheThings**: https://github.com/swisskyrepo/PayloadsAllTheThings
- **HackTricks**: https://book.hacktricks.xyz/
- **CyberChef**: https://gchq.github.io/CyberChef/

### Practice Platforms
- **HackTheBox**: https://www.hackthebox.eu/
- **TryHackMe**: https://tryhackme.com/
- **PicoCTF**: https://picoctf.org/
- **OverTheWire**: https://overthewire.org/

---

**Happy Hacking!** 🎭🔓

*Remember: Only use these tools on systems you own or have explicit permission to test.*
