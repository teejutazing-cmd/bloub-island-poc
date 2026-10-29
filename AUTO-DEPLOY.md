# Bloub Appetize Auto-Deploy

> **CONNECTED & VERIFIED:** 2026-10-29 — GitHub Actions secret `APPETIZE_API_TOKEN` is configured and [run #2](https://github.com/teejutazing-cmd/bloub-island-poc/actions/runs/40847983431) completed successfully, including Appetize upload. The steps below are for **recovery/reconfiguration only**. For resuming a session, read [SESSION-HANDOFF.md](SESSION-HANDOFF.md).

This deploy pipeline publishes the **real native iOS Simulator .app** to Appetize, rather than an HTML mock-up or a signed physical-device IPA.

## One-time secure connection (required)

1. In Appetize, visit **Organization Settings → API Tokens** and generate a Developer-role token labeled `Bloub GitHub CI`. The token is shown **only once**. Do not paste it into the repository, commit, screenshots, ChatGPT messages or the app itself.
2. In GitHub, go to **teejutazing-cmd/bloub-island-poc → Settings → Secrets and variables → Actions → New repository secret**.
3. Name it **`APPETIZE_API_TOKEN`** and paste the Appetize token as its secret value. GitHub masks stored secrets in workflow logs.
4. Open https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/deploy-appetize.yml and click **Run workflow** once.

Before the secret exists, a small preflight runs but **the macOS build/upload steps are skipped** to avoid wasting CI work. Adding a secret alone does not fire a GitHub Actions workflow; trigger the workflow once after adding it.

## Regular use

Every commit pushed to `main` that changes Bloub app source, assets, the XcodeGen project, or this workflow triggers the following:
- Build real ARM64 `iphonesimulator` Bloub `.app` on a standard macOS GitHub Actions runner.
- Validate the bundle ID `com.bloub.island.poc`, Live Activity and both embedded extensions.
- Save the verified ZIP as a GitHub artifact, then call the **official Appetize GitHub Action** using the repository secret.
- Create a new build in the existing Appetize application group (identified by the **same iOS bundle ID**). This preserves prior builds instead of overwriting their unique build IDs.

Open **https://appetize.io/apps/ios/com.bloub.island.poc**, and start a **new session** after the CI run finishes. The app page should resolve to the latest build. Existing running sessions are **not** hot-reloaded.

To publish manually after adding a token, use the GitHub **Run workflow** button. The headless native XCTest/recording workflow remains separate in `simulator-lab.yml`.

### Safety, cost and limits

- Scope: `main` only; no token on forked pull requests. `permissions: contents: read`.
- Appetize token resides in the encrypted GitHub Actions repository secret, never in source or local files.
- The official action is `appetizeio/github-action-appetize@v1.1.0`; validate any future version bump independently.
- The GitHub repo is public; don't commit proprietary code, personal data or credentials.
- GitHub standard macOS runners for public repos currently do not consume billed Actions minutes, but Appetize's free session minutes, upload quotas and plan terms still apply.
- This CI deploy produces a **Simulator ZIP**, not an installable iPhone IPA. The known-working v4 physical-device IPA stays untouched, and on-device installation is still manual at approved milestones.
- If upload fails, the preceding Simulator artifact remains available for manual upload and logs show the reason (without revealing the token).
- Disable by removing the `APPETIZE_API_TOKEN` secret or disabling this GitHub Actions workflow.

## Troubleshooting

If upload is skipped: repository secret is not set. If upload fails with 401: regenerate the Appetize token and replace the GitHub secret. If a new build appears under the same app ID but does not open: confirm it is an ARM64 iOS Simulator ZIP and that the Appetize device supports the requested extensions.

Appetize Dashboard: https://appetize.io/apps/ios/com.bloub.island.poc
CI: https://github.com/teejutazing-cmd/bloub-island-poc/actions/workflows/deploy-appetize.yml
