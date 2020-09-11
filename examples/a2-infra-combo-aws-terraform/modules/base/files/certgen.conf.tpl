[req]
default_bits = 4096
prompt = no
default_md = sha256
x509_extensions = v3_req
distinguished_name = dn
days = 364

[dn]
C = US
ST = WA
O = Chef Software
CN = ${fqdn}

[v3_req]
subjectAltName = @alt_names
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = ${fqdn}
