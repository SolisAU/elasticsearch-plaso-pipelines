ES_SERVER := http://localhost:9200

all: install test

install:
	curl -s -X PUT -H content-type:application/json $(ES_SERVER)/_ingest/pipeline/plaso-olecf?pretty -d @plaso-olecf.json | tee /dev/stderr | grep -sq '"acknowledged" : true'
	curl -s -X PUT -H content-type:application/json $(ES_SERVER)/_ingest/pipeline/plaso-evidenceof?pretty -d @plaso-evidenceof.json | tee /dev/stderr | grep -sq '"acknowledged" : true'
	curl -s -X PUT -H content-type:application/json $(ES_SERVER)/_ingest/pipeline/plaso-geoip?pretty -d @plaso-geoip.json | tee /dev/stderr | grep -sq '"acknowledged" : true'
	curl -s -X PUT -H content-type:application/json $(ES_SERVER)/_ingest/pipeline/plaso-winevt?pretty -d @plaso-winevt.json | tee /dev/stderr | grep -sq '"acknowledged" : true'
	curl -s -X PUT -H content-type:application/json $(ES_SERVER)/_ingest/pipeline/plaso-normalise?pretty -d @plaso-normalise.json | tee /dev/stderr | grep -sq '"acknowledged" : true'
	curl -s -X PUT -H content-type:application/json $(ES_SERVER)/_ingest/pipeline/iis-normalise?pretty -d @iis-normalise.json | tee /dev/stderr | grep -sq '"acknowledged" : true'
	curl -s -X PUT -H content-type:application/json $(ES_SERVER)/_ingest/pipeline/plaso?pretty -d @plaso.json | tee /dev/stderr | grep -sq '"acknowledged" : true'


test:
	curl -s -X POST -H content-type:application/json -d @test_data/test_documents.json  $(ES_SERVER)/_ingest/pipeline/plaso/_simulate?pretty | egrep "(relay|ip_address|country|city|username|logon_type|error)"

download-lists:
	rm -f firehol_anonymous.txt
	curl -o firehol_anonymous.txt https://iplists.firehol.org/files/firehol_anonymous.netset
	rm -f torbulkexitlist.txt
	curl -o torbulkexitlist.txt https://check.torproject.org/torbulkexitlist

build-mmdb:
	python3 -m pip install -r requirements.txt
	rm -f Anonymous.mmdb
	python3 build_mmdb.py
