# DDEV Axe accessibility checker

Run the [Axe accessibility checker](https://gitlab.com/Mschudders/accessibility_checker) on any URL from inside a DDEV project. One command, no local Node, Chrome or Puppeteer: everything lives in the add-on's container.

![Report screenshot](https://github.com/user-attachments/assets/2358373f-5255-4137-a328-2e4115643560)

## Installation

```sh
ddev add-on get Mschuddings/ddev-axe_a11y && ddev restart
```

Commit the generated `.ddev` files so the whole team gets the add-on with a `git pull` and a `ddev restart`.

## Usage

```sh
ddev axe_a11y https://www.example.be
```

The report opens in your browser automatically, and its path is printed as well.

Several URLs at once:

```sh
ddev axe_a11y https://www.example.be https://www.example.be/contact
```

Your own project:

```sh
ddev axe_a11y https://$(ddev describe -j | jq -r .raw.name).ddev.site
```

### A list of URLs

Put a `.csv` or `.txt` file with one URL per line in `.ddev/axe_a11y/config/`:

```text
https://www.example.be
https://www.example.be/contact
```

```sh
ddev axe_a11y urls.csv
```

Lines that are not `http(s)` URLs are skipped with a message, so a header row is harmless. Files exported from Excel work as-is, BOM and Windows line endings included.

To test a whole site, convert the sitemap with <https://www.bulkgpt.ai/tools/xmltocsv> and use that file.

### Options

| Option | Purpose |
| --- | --- |
| `--fail-on=<impact>` | Exit non-zero on `minor`, `moderate`, `serious` or `critical` findings. Useful in a script or a git hook. |
| `--baseline=<file>` | Accept the findings already recorded in this file and only report regressions. The file lives in `.ddev/axe_a11y/config/`. |
| `--update-baseline` | Record the current findings in the `--baseline` file. |
| `--no-open` | Print the report path without opening a browser. |

Recording what is already broken, then failing only on new problems:

```sh
ddev axe_a11y --baseline=a11y-baseline.json --update-baseline urls.csv
ddev axe_a11y --baseline=a11y-baseline.json --fail-on=serious urls.csv
```

Commit `a11y-baseline.json` so the whole team shares the same definition of "known".

## Reports

Every run writes two files to `reports/axe_a11y/results/` in the project root:

| File | For |
| --- | --- |
| `report-<timestamp>-<host>.html` | People. A summary per impact level and per rule first, then the detail per page. |
| `report-<timestamp>-<host>.json` | Scripts. The same results plus counts. |

Timestamps are sortable, so the directory lists chronologically. Add `reports/` to `.gitignore` unless you want to keep reports in version control.

## Staying up to date

The scanner image is pulled at most once per 24 hours per machine, by a `pre-start` hook, so everybody picks up scanner changes without having to reinstall the add-on and without a registry round trip on every `ddev start`. Working offline is fine: the start continues with the image already present and retries sooner than a day later.

To force a refresh:

```sh
rm ~/.ddev/.axe_a11y-last-pull && ddev restart
```

Override the interval per machine with `AXE_A11Y_MAX_IMAGE_AGE` (seconds).

The add-on itself updates with:

```sh
ddev add-on get Mschuddings/ddev-axe_a11y && ddev restart
```

## Configuration

The scanner reads these from the environment; set them in `.ddev/docker-compose.axe_a11y.yaml` under `environment:` if the defaults do not suit you.

| Variable | Default | Purpose |
| --- | --- | --- |
| `AXE_IGNORE_CERT_ERRORS` | `true` | Accept invalid certificates. On by default because a project's own mkcert certificate is not trusted inside the container. |
| `AXE_NAV_TIMEOUT_MS` | `90000` | Navigation timeout per URL. |
| `AXE_NAV_RETRY_ATTEMPTS` | `2` | Attempts per URL before reporting a scan error. |
| `AXE_TIMEZONE` | `Europe/Brussels` | Timezone used in timestamps. |

The full list is in the [scanner's README](https://gitlab.com/Mschudders/accessibility_checker#environment-variables).

## Removal

```sh
ddev add-on remove axe_a11y
```

URL lists, baselines and previous reports are left in place.

## Troubleshooting

**`The ddev-<project>-axe-a11y container is not running`** — run `ddev restart`. If it keeps failing, `ddev logs -s axe_a11y` shows why.

**`could not pull ... and no local copy exists`** — the machine cannot reach `registry.gitlab.com`. The add-on needs one successful pull before it can be used offline.

**A URL cannot be scanned** — the report says so per URL. For a site behind basic auth or a VPN, check that the container can reach it; it uses its own network, not your browser's session.

## Limitations

Automated scanning does not replace manual accessibility testing. It cannot judge whether alternative text is meaningful, whether reading order is logical, or whether an interactive journey is usable. According to Deque, the makers of axe-core, automated testing finds on average 57% of the issues a first manual audit would find.

## Credits

Maintained by [Michael Schuddings](https://github.com/Mschuddings). The scanner lives at [gitlab.com/Mschudders/accessibility_checker](https://gitlab.com/Mschudders/accessibility_checker).
