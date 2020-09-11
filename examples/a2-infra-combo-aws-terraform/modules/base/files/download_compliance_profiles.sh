# Download profiles for Audit cookbook

for PROFILE in \
cis-amazonlinux2-level1 \
cis-centos6-level1 \
cis-centos7-level1 \
cis-oraclelinux7-level1 \
cis-rhel5-level1 \
cis-rhel6-level1-server \
cis-rhel7-level1-server \
cis-sles11-level1 \
cis-sles12-level1 \
cis-ubuntu12.04lts-level1 \
cis-ubuntu14.04lts-level1 \
cis-ubuntu16.04lts-level1-server \
cis-ubuntu18.04lts-level1-server \
cis-windows2012r2-level1-domaincontroller
do
  echo "${PROFILE}"
  VERSION=`curl -s -k -H "api-token: $TOK" https://localhost/api/v0/compliance/profiles/search -d "{\"name\":\"$PROFILE\"}" | jq -r .profiles[0].version`
  echo "Version:  ${VERSION}"
  curl -s -k -H "api-token: $TOK" -H "Content-Type: application/json" 'https://localhost/api/v0/compliance/profiles?owner=admin' -d  "{\"name\":\"$PROFILE\",\"version\":\"$VERSION\"}"
  echo
  echo
done
