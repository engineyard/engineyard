# ChangeLog

## NEXT

  *

## v1.3.32 (2011-09-23)

  * Use the environments API to check whether run migrations or not when the flag is
    not provided.

## v1.3.31 (2011-09-21)

  *

## v1.3.30 (2011-09-19)

  *

## v1.3.29 (2011-09-15)

  *

## v1.3.27 (2011-09-14)

  *

## v1.3.26 (2011-09-13)

  *

## v1.3.25 (2011-09-12)

  *

## v1.3.24 (2011-09-11)

  *

## v1.3.23 (2011-09-08)

  * Update version of serverside gem for rails 3.1 assets support.

## v1.3.22 (2011-08-09)

  * Patch RestClient to stop sending cookies - they interfere with AWS S3.

## v1.3.21 (2011-08-03)

  * Update README to include more info about the ey.yml config.
  * Suggest ey environments --all when no environments match.
  * Fix an issue with uploading recipe tgz files on windows.

## v1.3.20 (2011-05-27)

  * Start recording the new load_balance_ip_address from the environment API.
  * Fix for deprecated API key "stack_name"

## v1.3.19 (2011-05-23)

  * `ey status` shows most recent deployment status of an app and environment.

## v1.3.18 (2011-05-08)

  * Add --file (-f) option to specify a .tgz file containing the custom cookbooks dirctory.
  * Add --apply option which automatically runs recipes uploaded with `ey recipes upload`.
  * Improve recipes documentation.
  * Alias ey update to ey rebuild to conform to the terminology on the AppCloud dashboard.
  * Improve the documentation in the README file.
  * Send a User-Agent header with all API requests.

## Begin ChangeLog (2011-05-05)
