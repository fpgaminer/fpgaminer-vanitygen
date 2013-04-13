Bitcoin Vanity Address generation, implemented on FPGAs.


This code is functional, but experimental. It is not currently designed for performance; it is a proof of concept.


Current Performance: ~40Kk/s



How to Use:

Right now, you will need an Altera Cyclone III 120 development kit. If you have a different FPGA board, you will have to adjust the synthesis project and code accordingly.

You will also need to know how to use Altera's In-System Sources and Probes Editor. A more convenient method is planned.

*Before you Begin*: Download pywallet (pywallet.py) and place it in the tools directory.


1) Compile project (e.g. boards/3C120/synthesis/fpgaminer-vanitygen.qpf)
2) Load bitstream into target FPGA.
3) Use tools/generate\_parms.py to get the Base Public Key's X and Y coordinates, and the hash range.
4) In Quartus, go to Tools->In-System Sources and Probes Editor
5) Make sure the In-System Sources and Probes Editor is connected to your target FPGA.
6) Run Edit->Recreate Instances From JTAG Device, to clean up the list of sources and probes.
7) Set the Bus Display Format (by right clicking) to Hexadecimal on all of the relavant sources and probes.
8) Input the Base Public Key's X and Y for the A and B sources, respectiely.
9) Input the min and max hash values.
10) Toggle RST to 1, and then back to 0.
11) Read MTCH. Ignore the first result, as it is likely old.
12) Re-read MTCH every so often to check for new results.
13) Use tools/check\_result.py to convert the result returned by MTCH into a private key.

NOTE: check\_result.py expects "Offset" to be entered as a base-10 number, not hex.



Performance:

As mentioned, the code is currently a proof of concept. It uses a serial design, which means that it tests a new key about every 1000 cycles. Pipelined designs, which can test one key per cycle, are under development.



How it Works:

The high level design is simple. In pseudo-code:

    int vanitygen (uint256 x, uint256 y, uint160 min, uint160 max)
    {
        int counter = 0;

        while (1)
        {
            // Increment the public key by adding the Generator
            add_public_key (&x, &y, G);
            counter += 1;

            uint160 hash = hash_public_key (x, y);

            if (hash >= min && hash <= max)
                return counter;
        }
    }

Starting from a Base Public Key, the algorithm searches through the key-space linearly and monotonically. Each public key is hashed to see if it falls within the desired hash range. If it does, it is likely that that particular public key has the desired Bitcoin address. On success, it returns the offset from the given Base Public Key.

To turn the Offset into a key that can be imported into a Bitcoin wallet, one merely adds the offset to the Base Private Key.

The Python scripts in the tools directory help calculate all the inputs to this algorithm, and interpet the results.





Donation Address:  1fpgaXxCpiP5CmKYpuc9wms3mXCdGSRGH

_Yes, that address was created with this firmware._
