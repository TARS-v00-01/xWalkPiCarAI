# Public documentation publication

This is the separately curated, detailed public edition of the eight xWalk documentation chapters.
Only `chapters/` is rendered. Do not copy the complete developer-note site, private component source,
Gerrit administration pages, or operational configuration into this directory.

The public site is configured for `https://tars-v00-01.github.io/xWalkPiCarAI/`.
The content owner and rollback owner are the xWalkPiCarAI maintainers.

## Review and build

Review every changed page for internal addresses, credentials, personal data, private source links,
and internal-only operations. The checker catches common markers and requires an explicit page allowlist;
it does not replace that review. `manifest.json` records the reviewed file set and each file's SHA-256.
Update it explicitly after reviewing changed or new pages. Search indexes and rendered HTML receive the same
marker check. Loopback defaults and reserved documentation addresses are allowed; real deployment endpoints,
personalized text, internal links, and credential values are not. Exclude photos with unreviewed metadata.

The current technical snapshot derives from submitted developer-note change 1421. It retains module contracts,
build and test examples, configuration schemas, safety constraints, and guide attribution. Administration,
account and licence provisioning, internal readiness reports, and operational infrastructure pages are omitted.
The ten core API guides were expanded in developer-note change 1441 with implementation-checked contracts,
dated official references, and Mermaid diagrams. The public edition retains those guide bodies and uses
plain sidebar labels and matching previous/next links. Source locations are plain text for authorized
contributors; they are not links to private source downloads.

From the integration root, use an isolated environment:

```bash
python3 -m venv build-public-docs/venv
build-public-docs/venv/bin/python -m pip install -r docs/public/requirements.txt
build-public-docs/venv/bin/python docs/public/verify.py
build-public-docs/venv/bin/python -m mkdocs build --strict --config-file docs/public/mkdocs.yml
build-public-docs/venv/bin/python docs/public/verify.py build-public-docs/site
```

The build produces only ignored output. Preview it locally:

```bash
build-public-docs/venv/bin/python -m http.server 8000 --bind 127.0.0.1 --directory build-public-docs/site
```

## Publication

Upload source changes through Gerrit. The integration must pass complete CI, receive authorized review,
and be submitted before the synchronization service advances GitHub `master` to that exact commit.
The Public Documentation workflow then builds this directory with no component checkout or private credentials.
Its deployment job alone receives Pages and OIDC write permissions.

An administrator configures GitHub Pages with **Source: GitHub Actions** and restricts the `github-pages`
environment to `master`. The workflow refuses dispatches from another repository or branch.
Do not use a workflow dispatch to publish an unsubmitted Gerrit patch set.

Use the workflow's deployment result to confirm the live URL and deployed commit. Gerrit submission,
GitHub synchronization, and Pages deployment are separate outcomes; report each accurately.

For a content rollback, submit a revert through Gerrit and let the same pipeline deploy it.
For an urgent exposure, an authorized administrator can unpublish the Pages site immediately, then review
the correction through Gerrit before re-enabling deployment. Keep the private developer-note artifact separate.
