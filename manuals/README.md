# Manuals

Each manual is stored in its own folder:

```text
manuals/<manual-slug>/
|-- manifest.json
`-- versions/
    `-- <version>/
        |-- index.html
        `-- assets/
```

## Manifest Fields

- `slug`: URL-safe manual identifier.
- `title`: Public manual title.
- `description`: Short text shown on the documentation home page.
- `publicPath`: Optional clean public URL folder, such as `usage-manual`.
- `latest`: Version that should be copied to `/manuals/<slug>/`.
- `versions`: Published versions, newest first.
- `compatibleAppVersions`: App versions covered by a manual version.
- `compatibleFirmwareVersions`: Firmware versions covered by a manual version.

The build script validates that every manifest version has an `index.html`.
