LED_AXI_GPIO_MB
Project Overview
This project was developed in AMD Xilinx Vivado using a MicroBlaze-based block design.
The design includes a MicroBlaze processor system, AXI-connected peripherals, AXI DMA, and a custom frame_receiver RTL module.
Main Components
MicroBlaze — embedded processor.
AXI GPIO — GPIO peripheral blocks.
AXI DMA — DMA engine configured with the S2MM channel enabled.
frame_receiver.v — custom RTL module used as a test data generator.
Block Design — design_1.bd.
Constraints — design_1.xdc.
Implementation Status
Vivado synthesis completed successfully.
Vivado implementation completed successfully.
The implemented design screenshot is included in this repository.
Repository Contents
LED_AXI_GPIO_MB.xpr — Vivado project file.
LED_AXI_GPIO_MB.srcs/ — design sources, Block Design, IP configuration files, and constraints.
design_1_wrapper.xsa — exported hardware platform.
LED_AXI_GPIO_MB_Implemented_Design.png — screenshot of the implemented design.
Tools
AMD Xilinx Vivado
MicroBlaze soft processor
AXI peripherals and AXI DMA
Verilog HDL