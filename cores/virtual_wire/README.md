This is a wrapper for an Altera In-System Source and Probe.
It allows a developer to monitor and drive signals within the design on a running FPGA.
This is occassionally abused to act as the sole means of input and output to an experimental design, since it's so easy to use and doesn't
require anything but a JTAG connection to the FPGA.


tx\_output is synchronous to clk.
INSTANCE\_ID may not be more than 4 alphanumeric characters.
The maximum input or output width is 511.
