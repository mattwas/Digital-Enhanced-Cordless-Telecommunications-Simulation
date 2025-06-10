# Digital Enhanced Cordless Telecommunications Link Level Simulation

This repository provides a MATLAB-based link-level simulation of the Physical (PHY) and Medium Access Control (MAC) layers for the classic DECT (Digital Enhanced Cordless Telecommunications) standard, including enhancements from DECT Evolution such as higher-order modulations (16QAM, 64QAM) and the channel coding.

## Features

    Classic DECT PHY/MAC Simulation: Models the core elements of the DECT standard, including time/frequency slotting, channel models, and packet structure1.

    DECT Evolution Extensions: Supports advanced modulations (16QAM, 64QAM) for higher data rates and channel coding (B Field Interleaving not implemented yet) as introduced in DECT Evolution Standard

        Turbo Coding: Implements turbo codes for improved error correction performance.

    Flexible Channel Modeling: Any Channel Model can be used. The current Model is adapted from: 

    Performance Metrics: Calculates Bit Error Rate (BER) and Packet Error Rate (PER) versus Signal-to-Noise Ratio (SNR) for different fields (A-Field, B-Field).

## Background

DECT is a globally adopted standard for short-range wireless communication, used in cordless telephony and other applications. The classic DECT PHY uses GFSK and supports multiple access via FDMA/TDMA/TDD. DECT Evolution introduces higher-order modulations (such as 16QAM, 64QAM) and advanced channel coding for greater throughput and reliability14.

# Usage

    The script is structured as follows:

        Parameter Setup: Configure DECT packet type, slot, channel, oversampling, code rate, and modulation.

        Transmitter/Receiver Initialization: Instantiate DECT PHY/MAC transmitter and receiver objects.

        Channel Modeling: Set up Rayleigh fading and AWGN channel models.

        Simulation Loop: For each SNR value, transmit multiple packets, pass through the channel, decode, and record errors.

        Results: BER and PER curves are plotted for A-Field and B-Field; results are saved to results/var_all.mat.

Example Plots

    PER vs. SNR for B-Field and A-Field

    BER vs. SNR for B-Field and A-Field

# References

    ETSI DECT Standard Overview2

    DECT Evolution and DECT-2020 NR specifications

Note: For details on the DECT standard and its evolution, consult the ETSI DECT committee and Wikipedia.