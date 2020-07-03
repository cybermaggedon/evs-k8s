
all: all.yaml

apply: all
	kubectl apply -f all.yaml

SOURCES=$(wildcard *.jsonnet */*.jsonnet */*.libsonnet *.yml */*.yml *.conf *.html)
all.yaml: all.json
	./json2yaml $< > $@

all.json: ${SOURCES}
	jsonnet -J defs all.jsonnet > $@

NS=cyberapocalypse

upload-secrets:
	-kubectl -n ${NS} delete secret portal-keys
	kubectl -n ${NS} create secret generic portal-keys \
	    --from-file=server.key=web-certs/server.key \
	    --from-file=server.crt=web-certs/server.crt

CERT_TOOLS=github.com/cybermaggedon/certificate-tools/...
go:
	GOPATH=$$(pwd)/go go get ${CERT_TOOLS}
	GOPATH=$$(pwd)/go go install ${CERT_TOOLS}

DOMAIN=portal.cyberapocalypse.co.uk
ADMIN=admin@cyberapocalypse.co.uk
CERT_DIR=web-certs
ORG=cyberapocalypse

certs: go ${CERT_DIR}/ca.crt ${CERT_DIR}/server.crt

${CERT_DIR}/ca.crt:
	-mkdir -p ${CERT_DIR}
	go/bin/create-key > ${CERT_DIR}/ca.key
	go/bin/create-ca-cert -E ${ADMIN} -N '${ORG} CA' \
	    -k ${CERT_DIR}/ca.key -v 3560 > ${CERT_DIR}/ca.crt

${CERT_DIR}/server.crt:
	go/bin/create-key > ${CERT_DIR}/server.key
	go/bin/create-cert-request -k ${CERT_DIR}/server.key \
	    --hosts '${DOMAIN}' --hosts '*.${DOMAIN}' \
	    -E ${ADMIN} -N '${PORTAL}'  > ${CERT_DIR}/server.req
	go/bin/create-cert -r ${CERT_DIR}/server.req -k ${CERT_DIR}/ca.key \
	    -c ${CERT_DIR}/ca.crt -S > ${CERT_DIR}/server.crt
	cat ${CERT_DIR}/ca.crt >> ${CERT_DIR}/server.crt
