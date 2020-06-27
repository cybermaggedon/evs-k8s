
all: all.json

SOURCES=$(wildcard *.jsonnet */*.jsonnet */*.libsonnet)
all.yaml: all.json
	./json2yaml $< > $@

all.json: ${SOURCES}
	jsonnet -J defs all.jsonnet > $@

