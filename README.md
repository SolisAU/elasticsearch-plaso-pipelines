# What Is This? #

This repo contains our ingest pipeline for getting data from Plaso (https://github.com/log2timeline/plaso) into ElasticSearch, whilst normalising, standardising and enriching some of the data to help our forensic analysts work more efficiently.

## Why do we need this? ##

Plaso does a pretty good job of taking a forensic triage image (whether CyLR or Kape based), processing the artefacts and creating a super timeline. Whilst most the Open-Source-DFIR community appear to favour the use of TimeSketch, I find searching & filtering in Kibana easier, but Plaso doesn't pull out certain fields, or uses the field name from the artefact and this creates differences between artefacts, or between different records in the same artefact!

## Project Goals ##

Help analysts quickly answer key questions to direct the investigation faster.

We achieve this by performing the following steps:

1. Pull out key values from artefacts to help with searching and filtering
2. Normalise the field names of certain artefacts to help with searching and filtering
3. Enrich data to help more quickly identify known good from known bad and unknown

### Pull Out Key Values ###

One major PITA when performing Windows forensics is that a lot of really great data exists within the Windows Event Logs (parser: winevtx), but sadly the data you really want is left in the `xml` field. This includes `Logon_Type` (was it an interactive logon?), `IP_Address`, `Session_ID` and a bunch of others, which if existed in individual fields allow you to quickly include or exclude records. 

### Normalise Field Names ###

`prefetch`, `olecf` and `winreg` have a number of artefacts that use different field names. If I'm trying to look at a bunch of artefacts that show File and Folder Opening, and I want to keep my columns nice and tidy so I can export the results to CSV and add to my report, I don't want to see the "path" (of the file or folder) in 4 different fields. ie: prefetch: `path_hints`; olecf: `local_path`, `network_path` and `shell_item_path`; winreg: `shell_item_path`, `value_name`.

### Enrich Data ###

Once we've pulled out additional fields and normalised the field names, we can start thinking about how to enrich the data with additional intelligence that helps us quickly exclude and include items that we know to be good and know to be bad. 

So far we are only performing GeoIP lookup on IP Address, then using a mashed together list of Tor Exit Nodes and VPN Servers to help identify IP addresses, but more could be added here with file hashes and file names as well.

## Installation ##

Pull down the project and run `make install`. This will create a bunch of ElasticSearch pipelines, with the primary (starting) one being called `plaso`.

You then need to create an index template (ie: default) in ElasticSearch that pushes indexes with a certain name to use that pipeline.

Mine looks like this:
`{
  "order": 0,
  "index_patterns": [
    "o365-*",
    "plaso-*",
    "dfir-*",
    "iis-*",
    "siem*"
  ],
  "settings": {
    "index": {
      "default_pipeline": "plaso"
    }
  },
  "mappings": {},
  "aliases": {}
}`

I use Cerebro to edit this, then all indexes I push from Plaso (via psort.py) are named plaso-casename-devicename (or similar), where the plaso- portion will match up with my index template and thus get processed by my ingestion pipelines.

## READ ME BEFORE PROCEEDING ##

Currently `plaso-geoip.json` references a customised mmdb (MaxMind DataBase) file called `Anonymous.mmdb`. This file needs to be created and stored in /etc/elasticsearch/ingest-geo/ on every node of your ElasticSearch cluster. I am yet to document how this all comes together and I would recommend commenting this section OUT of plaso-geoip.json so that your system doesn't break trying to look for a file that doesn't exist.
