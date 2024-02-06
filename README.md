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

`prefetch`, `olecf` and `winreg` have a number of artefacts that use different field names. If I'm trying to look at a bunch of artefacts that show File and Folder Opening, and I want to keep my columns nice and tidy so I can export the results to CSV and add to my report, I don't want to see the `path` (of the file or folder) in 4 different fields. ie: prefetch: `path_hints`; olecf: `local_path`, `network_path` and `shell_item_path`; winreg: `shell_item_path`, `value_name`.

Since Plaso switched from supporting Elasticsearch to OpenSearch they seem to have dropped the `parser` field as a default output field. See below in installation on how to add this back in for now.

### Enrich Data ###

Once we've pulled out additional fields and normalised the field names, we can start thinking about how to enrich the data with additional intelligence that helps us quickly exclude and include items that we know to be good and know to be bad. 

#### IP Address Enrichment ####
So far we are only performing GeoIP lookup on IP Address, then using a mashed together list of Tor Exit Nodes and VPN Servers to help identify IP addresses, but more could be added here with file hashes and file names as well.

#### Evidence Of Enrichment ####
This is _really_ basic, but we've added an `evidence_of` field, which can be used to create a filter (ie: `evidence_of: exists`) so you can filter down on artefacts that represent that type of activity based on the SANS poster of the same name. Thus far we've added in `AccountUsage` and `FileAndFolderOpening`, although the latter does overlap some artefacts that also represent `ApplicationUsage`, but we felt that File and Folder was probably better to reference. We'll look at ways to add more.

## Installation ##

Pull down the project and run `make install`. This will create a bunch of ElasticSearch pipelines, with the primary (starting) one being called `plaso`.

You then need to create an index template (ie: plaso) in ElasticSearch that pushes indexes with a certain name to use that pipeline.

Mine looks like this:

```
{
  "order": 1,
  "index_patterns": [
    "plaso-*",
    "dfir-*",
  ],
  "settings": {
    "index": {
      "default_pipeline": "plaso"
    }
  },
  "mappings": {},
  "aliases": {}
}
```

I use Cerebro to edit this, then all indexes I push from Plaso (via psort.py) are named plaso-casename-devicename (or similar), where the plaso- portion will match up with my index template and thus get processed by my ingestion pipelines.

As of Plaso 20230724 the 'parser' event attribute has been removed from the OpenSearch output, as has the 'filename' attribute. Whilst we are re-working the processors to use other attributes, you can modify the Plaso code to add these back in by editing `/usr/lib/python3/dist-packages/plaso/output/shared_opensearch.py` and changing the section about `_FIELD_FORMAT_CALLBACKS` to the following:

```
  _FIELD_FORMAT_CALLBACKS = {
      'datetime': '_FormatDateTime',
      'display_name': '_FormatDisplayName',
      'filename': '_FormatFilename',
      'inode': '_FormatInode',
      'message': '_FormatMessage',
      'parser': '_FormatParser',
      'source_long': '_FormatSource',
      'source_short': '_FormatSourceShort',
      'tag': '_FormatTag',
      'timestamp': '_FormatTimestamp',
      'timestamp_desc': '_FormatTimestampDescription',
      'yara_match': '_FormatYaraMatch'}
```

And adding `--additional-fields filename,parser` to your psort commandline.

## READ ME BEFORE PROCEEDING ##

Currently `plaso-geoip.json` references a customised mmdb (MaxMind DataBase) file called `Anonymous.mmdb`. This file needs to be created and stored in `/etc/elasticsearch/ingest-geoip/` on every node of your ElasticSearch cluster. You must do this *FIRST* before pushing the pipelines to Elastic (`make install`).

If you want to build this first do `make build-lists` and it will download the relevant TOR Exit Node and VPN Service lists; then do `make build-mmdb`. Make sure the device you build the mmdb on has more than 8GB of memory or it will bomb out. You can then run `make install-mmdb` and it will copy the `Anonymous.mmdb` to `/etc/elasticsearch/ingest-geoip/`. You then need to restart elasticsearch for it to pickup this file.

If you don't want to use this, comment it out of `plaso-geoip.json`.

You also need to ensure you've added `script.painless.regex.enabled: true` to `/etc/elasticsearch/elasticsearch.yml` or some of the RegEx's may not work. 

The use of this file is currently commented out. Thanks to @blueteam0ps :)

## Change Log

* 05.02.2024
  * There's probably a tonne of changes that have happened between the last update and now. but we forgot to update this.
  * Have fixed issues with values in the xml field (windows events) bleeding out into other fields by sanitising the xml field better.
  * Fixed a few of the regex's for the winevent section.
  * Worked out why Elasticsearch would just crash on ingestion with certain data - was a regex that died due to the xml field not being sanitised!
* 30.09.2021  
  * Fixed documentation relating to the Anonymous.mmdb and how to properly install this
* 28.09.2021  
  * Updated Makefile to download the necessary files to build Anonymous.mmdb
  * Had to fix up a few things that were breaking that I just couldn't get my head around in the build process
  * You need to have 8GB minimum to build the file (make build-mmdb)

