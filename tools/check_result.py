#
#
# Copyright (c) 2013 fpgaminer@bitcoin-mining.com
#
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
#


#
# Use this script to interpret the results returned by the firmware.
#
# NOTE: You will need to download pywallet.py from the pywallet project and place it in the current directory.
#
from pywallet import *
import sys

# Read Base Secret and offset from user
base_secret = raw_input ("Base Secret (HEX): ")
offset = int (raw_input ("Offset: "), 10)


if len (base_secret) != 64:
	print "Secret must be a 256-bit hexidecimal integer."
	sys.exit (-1)

base_secret = int('0x' + base_secret, 16)

# Calculate Public Key
secret = (base_secret + offset) % (2 ** 256)
key = EC_KEY (secret)
public_key = i2o_ECPublicKey (key, compressed=True) # Current firmware always compresses
address = public_key_to_bc_address (public_key)
wif = SecretToASecret (('%064X' % secret).decode('hex'), True)

print "\nSecret: %064X" % (secret)
print "Address: ", address
print "importprivkey ", wif

print "\nDouble check that the above address is correct; the current firmware occasionally returns bad results\n"
