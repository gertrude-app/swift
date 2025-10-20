POST {{API_URL}}/pairql/gertrude-am/CreateDatabaseUpload
{
  "installId": "deadbeef-dead-beef-dead-beefdeadbeef"
}

HTTP 200
[Asserts]
jsonpath "$.uploadUrl" exists
jsonpath "$.uploadUrl" matches "podcast-dbs"
jsonpath "$.uploadUrl" matches "deadbeef-dead-beef-dead-beefdeadbeef"
jsonpath "$.uploadUrl" matches "\\.db"
