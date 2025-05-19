# Screenshot
![image](https://github.com/user-attachments/assets/2358373f-5255-4137-a328-2e4115643560)

# DDEV add-on Axe accessiblity checker

Run Axe accessibility checker on a URL.

## Installation

ddev add-on get Mschuddings/ddev-axe_a11y && ddev restart

## Usage

ddev axe_a11y https://www.example.be

It will open the report automatically in your browser.

It is possible to test multiple urls via for example:
ddev axe_a11y https://www.example.be https://www.example2.be https://www.example.be

### File

It is possible to pass in a *CSV* file.
Note please don't add headers.

Then via:
``
ddev axe_a11y urls.csv
``

The file must be inside of ".ddev/axe_a11y/config"

It will only open one HTML report though but all urls will be checked of course.

## Previous reports.

All reports will be in your ".ddev/axe_a11y/results" folder.


## FAQ

### How do I test a whole site

Convert your sitemap to CSV via: https://www.bulkgpt.ai/tools/xmltocsv
And then just use that CSV to test your whole website.
