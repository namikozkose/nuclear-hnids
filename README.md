Nuclear-HNIDS ☢️🛡️

Hardware-Level Network Intrusion Detection System (FPGA/VHDL) for Critical Infrastructure

Nuclear-HNIDS is an ultra-low-latency, FPGA-based hardware firewall designed to protect Operational Technology (OT) and critical infrastructure (such as nuclear power plant cooling systems) from advanced cyber-physical attacks (e.g., Stuxnet-style sabotage).

Unlike traditional software-based firewalls that rely on operating systems and CPU cycles, Nuclear-HNIDS operates directly at the Register-Transfer Level (RTL). It inspects Modbus TCP traffic in real-time and physically drops malicious packets within 10 nanoseconds (1 clock cycle at 100 MHz), completely bypassing software vulnerabilities.

⚙️ Core Architecture & Hardware Logic

The core of the defense mechanism is a VHDL-based Finite State Machine (FSM) that parses incoming Ethernet/Modbus frames byte-by-byte:

Deep Packet Inspection (Hardware Level): The FSM tracks the Modbus MBAP header and zeroes in on the 7th byte (Function Code).

Nanosecond Reaction Time: If a critical sabotage command is detected (e.g., 0x05 Write Single Coil or 0x0F Write Multiple Coils), the FSM instantly triggers the sabotage_alert and asserts drop_packet to '1'.

Air-Gap Equivalent Isolation: The malicious packet is dropped at the PHY/MAC layer before it ever reaches the PLC or RTU's memory, ensuring the physical safety of the facility.

🔬 Simulation & Verification (AMD Vivado)

The RTL logic was strictly verified using the AMD Vivado XSim simulator.
During the behavioral simulation, a simulated adversarial payload (0x05 payload) was injected into the testbench:

The byte stream flows normally: 00 01 00 00 00 06 01...

At the exact clock cycle the 0x05 byte arrives, the hardware detects the anomaly.

The sabotage_alert and drop_packet signals are locked to HIGH on the immediate rising edge, neutralizing the threat instantly.

🚀 Future Integrations
Implementation of hardware-accelerated Post-Quantum Cryptography (PQC) for signed telemetry.

Physical deployment on Xilinx Artix-7 or Zynq-7000 SoC series FPGAs.

Implementation of hardware-accelerated Post-Quantum Cryptography (PQC) for signed telemetry.

Physical deployment on Xilinx Artix-7 or Zynq-7000 SoC series FPGAs.
