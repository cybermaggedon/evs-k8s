
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
# 	-kubectl delete secret login-keys
	kubectl create secret generic portal-keys \
	    --from-file=server.key=web-certs/portal.key \
	    --from-file=server.crt=web-certs/portal.crt
# 	kubectl create secret generic login-keys \
# 	    --from-file=server.key=login.key \
# 	    --from-file=server.crt=login.crt

CERT_TOOLS=github.com/cybermaggedon/certificate-tools/...
go:
	GOPATH=$$(pwd)/go go get ${CERT_TOOLS}
	GOPATH=$$(pwd)/go go install ${CERT_TOOLS}

PORTAL=test.portal.cyberapocalypse.co.uk
ADMIN=admin@cyberapocalypse.co.uk
CERT_DIR=web-certs
ORG=cyberapocalypse

certs: go ${CERT_DIR}/ca.crt ${CERT_DIR}/portal.crt

${CERT_DIR}/ca.crt:
	-mkdir -p ${CERT_DIR}
	go/bin/create-key > ${CERT_DIR}/ca.key
	go/bin/create-ca-cert -E ${ADMIN} -N '${ORG} CA' \
	    -k ${CERT_DIR}/ca.key -v 3560 > ${CERT_DIR}/ca.crt

${CERT_DIR}/portal.crt:
	go/bin/create-key > ${CERT_DIR}/portal.key
	go/bin/create-cert-request -k ${CERT_DIR}/portal.key \
	    --hosts '1.2.3.4' --hosts '${PORTAL}' \
	    -E ${ADMIN} -N '${PORTAL}'  > ${CERT_DIR}/portal.req
	go/bin/create-cert -r ${CERT_DIR}/portal.req -k ${CERT_DIR}/ca.key \
	    -c ${CERT_DIR}/ca.crt -S > ${CERT_DIR}/portal.crt
	cat ${CERT_DIR}/ca.crt >> ${CERT_DIR}/portal.crt
