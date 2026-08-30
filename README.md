# i2c_writing_master
Implementation of an I2C Master Writer based on university project specifications

## Overview

This repository contains the VHDL implementation of an **I²C Writing Master** designed for the **Electronics and Communication System** class (A.Y. 2025/2026). The device acts as a master in the I²C protocol, capable of **write-only operations** to communicate with lower-speed peripheral ICs in embedded systems.

The Writing Master provides a simple interface for microcontrollers/processors to send data to slaves (actuators, display drivers, sensors) over a 2-wire bus (SDA and SCL), handling all protocol timing and sequencing.

---

## Key Features

- **I²C Write-Only Master**: transmits data to slave devices, no read operation implemented
- **7-bit Addressing**: supports up to 128 slave addresses
- **8-bit Data Transmission**: sends one data byte per transaction
- **Clock Division**: I²C SCL clock is 32x slower than system clock
- **Valid Signal**: enables controlled transaction initiation by the processor
- **Asynchronous Active-Low Reset**: initializes the system
- **NACK Handling**: properly handles NACK on address or data by generating a STOP condition
- **Consecutive Transfers**: supports multiple messages to same or different slaves without releasing the bus

---

## Architecture

The system is structured into three main components:

1. **REG_STATE Logic** (Synchronous), it manages registers, current state, counters, and data sampling
2. **NEXT_STATE Logic** (Combinatorial), it computes the next FSM state based on inputs
3. **OUTPUT Logic** (Combinatorial), it generates I²C protocol signals and serializes data

The following signals are used in the interface:
- `clk`, global system clock
- `reset`, active-low asynchronous reset
- `valid`, indicates valid address/data from processor
- `addr`, 7-bit slave address
- `data`, 8-bit data to transmit
- `scl`, I²C serial clock (output)
- `sda`, I²C serial data (bidirectional, inout)

---

## State Machine

The FSM implements the following states:
- **IDLE**, waiting for a new transaction
- **START**, generates START condition
- **ADDR**, transmits 7-bit address + write bit
- **ACK_ADDR**, checks acknowledgment from slave
- **DATA**, transmits 8-bit data
- **ACK_DATA**, checks acknowledgment from slave
- **STOP**, generates STOP condition

---

## Testing

The implementation has been tested with the following scenarios:
- ✅ Single message transmission to an existing slave
- ✅ Multiple messages to the same address
- ✅ Multiple messages to different addresses
- ✅ NACK received on address
- ✅ NACK received on data
- ✅ Asynchronous reset during protocol

All tests were performed with a **system clock period of 8 ns** (125 MHz), matching the ZyBo development board's Programmable Logic clock.

---

## Synthesis & Implementation

The design was synthesized and implemented using **Vivado** in out-of-context mode.

### Resource Utilization
| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs     | 26   | 17,600    | 0.15%       |
| Registers| 47   | 35,200    | 0.13%       |

### Timing Performance
- **Post-Synthesis**: Worst Negative Slack = +4.450 ns → max frequency ≈ **281 MHz**
- **Post-Implementation**: Worst Negative Slack = +3.728 ns → max frequency ≈ **234 MHz**
- **I²C Clock (SCL)** at max frequency: **≈ 7.3 MHz** (well above standard I²C modes)

### Power Consumption
- **Total On-Chip Power**: 0.091 W (99% static, 1% dynamic)
- Extremely power-efficient design suitable for embedded applications

---

## License

This project was developed for educational purposes at the University.

---
