# ChangeLog

## NEXT

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
