#!/bin/bash -x
DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -us -uc -b
token=$(pass show Sites/api.github.com/sarg^forge)
version=$(cat debian/rules | grep -Po '(?<=^VERSION = ).+')
path=repos/sarg/tdlib-debian/releases

release_id=$(
curl -v https://api.github.com/$path \
    -H "Authorization: token $token" \
    -H "Content-Type: application/json" \
    -d "$(cat <<EOF
{
  "tag_name": "v$version",
  "target_commitish": "master",
  "name": "v$version",
  "body": "Upstream release $version",
  "draft": false,
  "prerelease": false
}
EOF
)" | jq '.id')

for deb in ../tdlib*${version}*deb; do
  [[ $deb =~ "dbgsym" ]] && continue
  onlyname=$(basename $deb)
  curl -v https://uploads.github.com/$path/$release_id/assets?name=$onlyname \
    -H "Authorization: token $token" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @$deb
done

./debian/rules clean
