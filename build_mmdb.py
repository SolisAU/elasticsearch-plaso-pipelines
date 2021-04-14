import mmdbencoder

enc = mmdbencoder.Encoder(
    6, # IP version
    32, # Size of the pointers
    'GeoLite2-Country', # Name of the table
    ['en'], # Languages
    {'en': 'Tor/VPN lookup'}, # Description
    compat=True) # Map IPv4 in IPv6 (::abcd instead of ::ffff:abcd) to be read by official libraries

#tor = open("TorBulkExitList.txt", "r")
#for line in tor.read().splitlines(keepends=False):
#	if line.startswith('#'): continue
#	data = enc.insert_data({'country': {'iso_code': 'TOR', 'names': {'en': 'Tor exit node'}}})
#	enc.insert_network(u'%s/32' % line, data)

hosts = open("firehol_anonymous.txt", "r")
for n, line in enumerate(hosts.read().splitlines(keepends=False)):
	if line.startswith('#'): continue
	data = enc.insert_data({'country': {'iso_code': 'VPN', 'names': {'en': 'Tor/VPN exit node'}}})
	enc.insert_network(('%s/32' if '/' not in line else '%s') % line, data)

enc.write_file('Anonymous.mmdb')
