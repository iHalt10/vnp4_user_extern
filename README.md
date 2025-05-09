# VNP4-UserExtern

This is a sample project that enables simple transmission and reception with the following two ports enabled:
- PCIe 0 PF 0
- QSFP 0

Additionally, when receiving packets with a custom 'multiplication' header, it performs calculations using the 'multiplication' User Extern and stores the calculation results in the header.

## Usage

### Preparation

#### Install Vitis/Vivado 2024.2.2

For GUI installation, enable the `Vitis Networking P4` checkbox under `Design Tools`.
For CLI installation, modify the `Modules=` entry in `install_config.txt` from `Vitis Networking P4:0` to `Vitis Networking P4:1`.

- [AMD Xilinx Download Site](https://japan.xilinx.com/support/download/index.html/content/xilinx/ja/downloadNav/vivado-design-tools.html)

#### Obtain Xilinx IP Licenses

- CMAC license
    - [cmac-license (Github: OpenNIC Shell)](https://github.com/Xilinx/open-nic-shell?tab=readme-ov-file#cmac-license)
    - [UltraScale+ 100G Ethernet Subsystem (Xilinx)](https://japan.xilinx.com/products/intellectual-property/cmac_usplus.html)
- Vitis Networking P4 (sdnet_p4) license
    - [Vitis Networking P4 (Xilinx)](https://japan.xilinx.com/products/intellectual-property/ef-di-vitisnetp4.html)

#### Clone Project

```shell
$ git clone https://github.com/iHalt10/vnp4_user_extern
$ cd vnp4_user_extern
$ git submodule update --init --recursive
```

### Build OpenNIC Shell

First, change the "BOARD" definition in the Makefile to the name of the FPGA Device you are using, then run `make`.

```shell
## Build options
BOARD           := au50
```

The following are supported:
- au45n
- au50
- au55n
- au55c
- au200
- au250
- au280
- soc250
- vck5k

```shell
$ make
```

### Program MCS/BIT Files
Program the program file (bit or mcs) to the FPGA device.
First, set the IP address that can connect to the "hw_server" process in the `PROGRAM_HW_SERVER` in the Makefile.
For local development environments, you can leave the local IP address as is.
Next, get the `DEVICE_NAME` of the recognized FPGA Board.
You can get it with the following command:

```shell
$ make get-devices
```

Set the obtained `DEVICE_NAME` in the `PROGRAM_DEVICE_NAME` in the Makefile.
Next, set the `FLASH_PART` name of the FPGA device you are using in the `PROGRAM_FLASH_PART` in the Makefile.

- FLASH_PART
    - au45n: mt25qu01g-spi-x1_x2_x4
    - au50:  mt25qu01g-spi-x1_x2_x4
    - au55c: mt25qu01g-spi-x1_x2_x4
    - au200: mt25qu01g-spi-x1_x2_x4
    - au250: mt25qu01g-spi-x1_x2_x4
    - au280: mt25qu01g-spi-x1_x2_x4

The names of the flash parts above are listed in the device's User Guide.
For au55n, soc250, and vck5k devices, please refer to the respective device documentation if you need detailed information about the corresponding flash parts.

Finally, write the program file to the FPGA device with the following command:
```shell
$ make program-bit # and warm reboot
# or
$ make program-mcs # and cold reboot
```

#### Program Options
The following Makefile options are available for programming:

```makefile
###########################################################################
##### Program Options
###########################################################################
PROGRAM_HW_SERVER   := 127.0.0.1:3121
PROGRAM_DEVICE_NAME := xcu50_u55n_0
PROGRAM_FLASH_PART  := mt25qu01g-spi-x1_x2_x4
```

### Build OpenNIC Driver

```shell
$ cd vnp4_framework/open-nic-driver
$ make
$ sudo insmod onic.ko
```

For detailed information, refer to [OpenNIC Driver Documentation (Github: OpenNIC Driver)](https://github.com/Xilinx/open-nic-driver).
