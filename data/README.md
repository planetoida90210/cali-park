# CaliPark Park data

`parks-osm-pl.json` lists the Parks (public outdoor places where OpenStreetMap maps a pull-up bar, parallel bars or dip bars) that the CaliPark app shows in Poland: location, name, equipment, status and source.

- **Source:** © OpenStreetMap contributors, <https://www.openstreetmap.org/copyright>.
- **Licence:** Open Database License (ODbL) 1.0, see [LICENSE-ODbL.md](LICENSE-ODbL.md). You may copy, share and adapt the data as long as you attribute OpenStreetMap and CaliPark and keep adapted databases under the ODbL.
- **How it is made:** `scripts/osm/build_parks_snapshot.py`, documented in [scripts/osm/README.md](../scripts/osm/README.md). The file is the same data the app bundles, refreshed when the snapshot is rebuilt; `osmDataTimestamp` says how fresh the OSM data is.
- **What is not here:** reviews, ratings and photos (CaliPark Community content, not part of this database) and any personal data.
