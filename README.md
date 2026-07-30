# SICK SIM300 IO-Link Modbus TCP Server Documentation

This repository stores public manuals and static documentation sites for the
SICK SIM300 IO-Link Modbus TCP Server AppSpace application.

The repository is organized so each manual can have its own versioned public
website while still sharing one GitHub Pages deployment.

Public entry points:

```text
/                         Documentation landing page
/usage-manual/            Latest usage manual
/api-manual/              Planned API manual page
/manuals/<slug>/versions.html  Version selector for a manual
```

## Repository Layout

```text
.
|-- .github/workflows/deploy-pages.yml  GitHub Pages CI/CD workflow
|-- assets/site/                        Shared CSS and JavaScript for the index pages
|-- manuals/                            Manual source files
|   `-- sim300-iolink-modbus-server/
|       |-- manifest.json               Manual metadata and published versions
|       `-- versions/
|           `-- v1.0.0/
|               |-- index.html          Versioned manual entry page
|               `-- assets/             Images, downloads, static files for this version
|-- tools/Build-Site.ps1                Builds the publishable static site into _site/
`-- _site/                              Generated site output, ignored by Git
```

## Add A New Manual Version

1. Create a new folder under
   `manuals/<manual-slug>/versions/<version>/`.
2. Add an `index.html` file and any static files under that version's
   `assets/` directory.
3. Update `manuals/<manual-slug>/manifest.json`:
   - Add the new version to `versions`.
   - Set `latest` to the new version when it should become the default.
   - Set `publicPath` when the manual should have a clean URL such as
     `usage-manual`.
   - Add `compatibleAppVersions` and `compatibleFirmwareVersions` for the
     version selector.
4. Build locally:

```powershell
.\tools\Build-Site.ps1
```

5. Open `_site/index.html` in a browser to check the generated site.

## Publish

The GitHub Actions workflow deploys the generated static site to GitHub Pages.

Recommended release flow:

```powershell
git add .
git commit -m "Add manual version v1.0.0"
git push origin main
./tools/release-docs.sh
```

You can also deploy manually from the GitHub Actions tab using the
`Deploy GitHub Pages` workflow.

The release script reads the default tag from
`manuals/sim300-iolink-modbus-server/manifest.json` field `latest`.

For a documentation-only update after a tag already exists, update the manifest
`latest` value to a new patch version, commit the change, and publish:

```powershell
git add .
git commit -m "Update usage manual"
git push origin main
./tools/release-docs.sh
```

To override the manifest value manually, pass `--tag v1.0.1`.

The release script builds the site, verifies there are no uncommitted changes,
checks that the tag does not already exist locally or on `origin`, creates an
annotated tag, and pushes it.

## Capture Application Screenshots

The usage manual includes screenshots under each application section. To capture
fresh screenshots from the running SIM300 web UI, run:

```powershell
.\tools\Capture-AppScreenshots.ps1 `
  -AppUrl "http://192.168.100.136:8080/#/home?msdd=App.msdd" `
  -Username "<username>" `
  -Password "<password>"
```

Screenshots are written to:

```text
manuals/sim300-iolink-modbus-server/versions/v1.0.0/assets/screenshots/
```

If the application opens the SICK authentication page and no valid credentials
are provided, the script saves `authentication-required.png` and stops.

## GitHub Pages Setup

In the GitHub repository settings:

1. Go to `Settings > Pages`.
2. Set `Source` to `GitHub Actions`.
3. Push a tag such as `v1.0.0`, or run the deployment workflow manually.
