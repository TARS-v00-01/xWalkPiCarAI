# Public documentation publication

This is the separately curated public edition of the eight xWalk documentation chapters.
Only `chapters/` is rendered. Do not copy the complete developer-note site, private component source,
Gerrit administration pages, or operational configuration into this directory.

The public site is configured for `https://tars-v00-01.github.io/xWalkPiCarAI/`.
The content owner and rollback owner are the xWalkPiCarAI maintainers.

## Review and build

Review every changed page for internal addresses, credentials, personal data, private source links,
and internal-only operations. The checker catches common markers and requires an explicit page allowlist;
it does not replace that review. Search indexes and rendered HTML receive the same marker check.

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
