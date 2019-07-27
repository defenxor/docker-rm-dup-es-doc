# docker-rm-dup-es-doc

Quick docker image for a bash script that removes duplicate IDs from daily Elasticsearch indices.

For example, given documents with the same ID in the following indices:
- myidx-2019.01.04
- myidx-2019.01.02
- myidx-2019.01.03

This script will keep the one in myidx-2019.01.04 and remove the others.

See `es-remove-duplicate.sh` for details.

## Usage

```shell
$ docker run -it \
-e "ES_URL=http://elasticsearch:9200" \
-e "ES_CRED=elastic:password" \
-e "ES_INDEX_PATTERN=myindex-*" \
-e "CURL_EXTRA_FLAGS=-m 30" \
defenxor/docker-rm-dup-es-doc
```
