# Linux System Hardening Scripts

These scripts are designed to enhance the security of various components of the Linux system, following the best practices recommended by ANSSI (Agence nationale de la sécurité des systèmes d'information).

## Table of Contents

- [Introduction](#introduction)
- [Scripts Overview](#scripts-overview)
  - [FS.sh](#fssh)
  - [Network.sh](#networksh)
  - [Hardware.sh](#hardwaresh)
  - [Kernel.sh](#kernelsh)
  - [Auth.sh](#authsh)
  - [System.sh](#systemsh)
  - [script](#script)
- [Installation](#installation)
- [Usage](#usage)

## Introduction

These scripts aim to provide a comprehensive and systematic approach to securing a Linux system. Each script focuses on specific aspects of system security, ensuring a thorough hardening process.

## Scripts Overview

### FS.sh

This script contains configurations and settings to strengthen the security of the file system. It includes permissions, access controls, and other file-related security measures.

### Network.sh

Dedicated to securing the network configuration and settings, especially IPV4 and IPV6.

### Hardware.sh

Focuses on securing the hardware components of the system, such as the BIOS/UEFI, Secure Boot, etc.

### Kernel.sh

Involves configurations related to kernel parameters, memory, etc., to enhance the security of the Linux kernel.

### Auth.sh

Dedicated to strengthening the authentication mechanisms of the system. It involves configurations related to user authentication, password policies, and other measures to enhance authentication security using PAM modules.

### System.sh

Addresses a comprehensive set of system-wide security measures such as partitioning, access control using SELinux, sensitive files and directories, etc.

### script

The main script that orchestrates the execution of the individual hardening scripts and manages the overall security configuration.

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/saaida1/Linux-OS-Hardening.git
2. Change into the project directory:
   
   ```bash
   cd Linux-OS-Hardening
   
4. Run the main script with elevated privileges:
   
   ```bash
   sudo ./script

## Usage
Each script can be executed individually or collectively through the main script. Refer to the specific script sections for more details on their usage.
