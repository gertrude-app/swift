POST {{API_URL}}/pairql/super-admin/CreateDashAnnouncement
X-SuperAdminToken: deadbeef-dead-beef-dead-beefdeadbeef
{
  "icon": "fa fa-bolt",
  "html": "We just released a brand-new <b>podcast&nbsp;app</b> called <b>Gertrude&nbsp;AM</b> that allows kids to listen to only approved podcasts. Searching and adding shows is protected behind a PIN.",
  "learnMoreUrl": "https://gertrude.app/blog/safe-podcast-app-for-kids"
}

HTTP 200
[Asserts]
jsonpath "$.success" == true
