# DDEV add-on Axe accessiblity checker

Run Axe accessibility checker on a URL.

## Installation

ddev add-on get Mschuddings/ddev-axe_a11y && ddev restart

## Usage

ddev axe_a11y https://www.example.be

It will open the report automatically in your browser.

It is possible to test multiple urls via for example:
ddev axe_a11y https://www.example.be https://www.example2.be https://www.example.be

## Previous reports.

All reports will be in your .ddev/axe_a11y folder.
