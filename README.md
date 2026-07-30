# SICK SIM300 IO-Link Modbus Server Documentation

This repository stores public manuals and static documentation sites for the
SICK SIM300 IO-Link Modbus Server AppSpace application.

The repository is organized so each manual can have its own versioned public
website while still sharing one GitHub Pages deployment.

## Repository Layout

```text
.
|-- .github/workflows/deploy-pages.yml  GitHub Pages CI/CD workflow
|-- assets/site/                        Shared CSS and JavaScript for the index pages
|-- manuals/                            Manual source files
|   `-- sim300-iolink-modbus-server/
|       |-- manifest.json               Manual metadata and published versions
|       `-- versions/
|           `-- v0.1.0/
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
git tag v1.0.0
git push origin main --tags
```

You can also deploy manually from the GitHub Actions tab using the
`Deploy GitHub Pages` workflow.

## GitHub Pages Setup

In the GitHub repository settings:

1. Go to `Settings > Pages`.
2. Set `Source` to `GitHub Actions`.
3. Push a tag such as `v1.0.0`, or run the deployment workflow manually.
