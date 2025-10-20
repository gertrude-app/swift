POST {{API_URL}}/pairql/gertrude-am/PodcastProducts

HTTP 200
[Asserts]
jsonpath "$" count == 1
jsonpath "$[0]" == "gertrude.am.yearly.unrestricted.access"
