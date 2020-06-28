
all: all.yaml

apply: all
	kubectl apply -f all.yaml

SOURCES=$(wildcard *.jsonnet */*.jsonnet */*.libsonnet *.yml */*.yml *.conf)
all.yaml: all.json
	./json2yaml $< > $@

all.json: ${SOURCES}
	jsonnet -J defs all.jsonnet > $@

upload-secrets:
	-kubectl delete secret portal-keys
	-kubectl delete secret login-keys
	kubectl create secret generic portal-keys \
	    --from-file=server.key=portal.key \
	    --from-file=server.crt=portal.crt
	kubectl create secret generic login-keys \
	    --from-file=server.key=login.key \
	    --from-file=server.crt=login.crt


