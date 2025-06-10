# Digital Enhanced Cordless Telecommunications Link Level Simulation

This repository provides a MATLAB-based link-level simulation of the Physical (PHY) and Medium Access Control (MAC) layers for the classic DECT (Digital Enhanced Cordless Telecommunications) standard (V2.9.1), including enhancements from DECT Evolution such as higher-order modulations (16QAM, 64QAM) and the channel coding.
This repository was highly inspired by https://github.com/maxpenner/DECT-NR-Plus-Simulation and was designed to work with the same channel models.

## Features

**Classic DECT PHY/MAC Simulation**: Models the core elements of the DECT standard, including time/frequency slotting, packet structure, scrambling, CRC calculation and modulation (GMSK, DBPSK),

**DECT Evolution Extensions**: Supports advanced modulations (e.g. 16QAM, 64QAM) for higher data rates and channel coding (B Field Interleaving not implemented yet) as introduced in DECT Evolution Standard

- **Turbo Code**: Implements turbo codes for improved error correction performance.

**Transmitter and Receiver modeling**: A very basic synchronisation algorithm based on the preamble. Added receiver diversity modeling: Antenna Selection and Antenna Combining.

**Flexible Channel Modeling**: Any Channel Model can be used. The current channel model wrapper is taken from: https://github.com/maxpenner/DECT-NR-Plus-Simulation 

**Performance Metrics**: Calculates Bit Error Rate (BER) and Packet Error Rate (PER) versus Signal-to-Noise Ratio (SNR) for different fields (A-Field, B-Field).

## Background

DECT is a globally adopted standard for short-range wireless communication, used in cordless telephony and other applications. The classic DECT PHY uses GFSK and supports multiple access via FDMA/TDMA/TDD. DECT Evolution introduces higher-order modulations (such as 16QAM, 64QAM) and advanced channel coding for greater throughput and reliability14.

## Usage

There are two scripts provided:

**main_single_packet.m**: A single DECT packet is generated which can be passed through a channel and demodulated/ decoded by a receiver.

**main_PER.m**: Calculate the Packet Error Rate and Bit Error Rate in regards to the Signal-To-Noise_Ratio. The script is structured as follows:

- Parameter Setup: Configure DECT packet type, modulation, channel coding, receiver diversity etc.

- Channel Modeling: Set up an channel model (e.g. rayleigh).

- Simulation Loop: For each SNR value, transmit multiple packets, pass through the channel, decode, and record errors.

- Results: BER and PER curves are plotted for A-Field and B-Field; results are saved to results/var_all.mat.

## Example Plots

Here are some possible example plots shown were the performance is compared to DECT NR+.

![](gfx/100ns_n-1.pdf "Simulated packet error rates in a Rayleigh fading channel with one receving antenna.")

![](gfx/100ns_n-2.pdf "Simulated packet error rates in a Rayleigh fading channel with two receving antennas.")

## To Do
- implement B-Field interleaving which is specified to be used in conjunction to the channel coding for secured packets.
- improve synchronisation

## References

https://www.etsi.org/technologies/dect

https://www.etsi.org/committee/1394-dect

PHY and MAC specifications:
- ETSI EN 300 175-2
- ETSI EN 300 175-3


Note: For details on the DECT standard and its evolution, consult the ETSI DECT committee and Wikipedia.