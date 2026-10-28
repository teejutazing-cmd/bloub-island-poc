# BLOUB Dynamic Island POC

Offline native iOS Live Activity test: Start -> Update +20% -> End.
No OpenClaw or Craft connection, no Apple Push, no credentials.

Build: push these files to a GitHub repository, use Actions > Build Bloub Island POC, download 'BloubIslandPOC-unsigned-IPA', extract IPA from downloaded artifact.

Install: on Windows, use https://sideloadly.io/ with free Apple Account and a USB-connected Dynamic-Island iPhone (iOS 17+). If installation strips or rejects the embedded Widget extension, treat the test as failed and keep the error logs. Free signing expires after 7 days.

Pass criteria: custom Bloub face appears on Dynamic Island and Lock Screen; progress updates 10% -> 30%; expanded view works; End dismisses activity. No pass until tested on real iPhone.
