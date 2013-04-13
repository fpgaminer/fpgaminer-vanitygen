################################################################################
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
################################################################################

#
# This program accepts a private key (secret) and desired bitcoin address prefix.
# It returns the Base Public Key's X and Y coordinates, and the minimum and maximum
# hash values. These four values can be fed to the FPGA, where it will begin searching
# for a valid offset.
#
# The minimum and maximum hash values are calculated by base58 decoding the minimum and maximum
# address for the given prefix. This is not 100% accurate, but it should be good enough.
# 
# NOTE: You will need to download pywallet.py from the pywallet project and place it in the current directory.
#
from pywallet import *
import sys


# Read desired prefix from user
prefix = raw_input ("Vanity Prefix (e.g. fpga): ")

if len (prefix) > 0:
	# Calculate minimum and maximum hash values for given prefix
	remaining_len = 33 - 1 - len (prefix)
	address_min = '1' + prefix + ('1' * remaining_len)
	address_max = '1' + prefix + ('z' * remaining_len)
	min_hash = b58decode (address_min, None).encode('hex')
	max_hash = b58decode (address_max, None).encode('hex')

	if len (min_hash) != len (max_hash) and len (min_hash) != 50:
		print "ERROR: Did not generate valid hashes. This is probably a bug in this script, but it's also possible the given prefix isn't valid."
		sys.exit (-1)
	print "Hash Min: ", min_hash[2:-8]
	print "Hash Max: ", max_hash[2:-8]
else:
	print "Hash range calculation skipped."

print ""

# Read Base Secret from user
base_secret = raw_input ("Base Secret (HEX): ")

if len (base_secret) > 0:

	if len (base_secret) != 64:
		print "Secret must be a 256-bit hexidecimal integer."
		sys.exit (-1)

	base_secret = int('0x' + base_secret, 16)

	# Calculate Base Public Key
	key = EC_KEY (base_secret)
	base_public_key = i2o_ECPublicKey (key)
	base_public_key_x = base_public_key[1:33]
	base_public_key_y = base_public_key[33:65]

	print "Base X: ", base_public_key_x.encode ('hex')
	print "Base Y: ", base_public_key_y.encode ('hex')
else:
	print "Public Key calculation skipped."
