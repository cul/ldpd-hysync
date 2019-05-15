# README

This application pulls data from Voyager and transforms it into a Hyacinth digital object JSON update.

## Ruby version
This app is designed to run on MRI 2.5.x

## System dependencies

This app depends on oci8; this requires installing the Oracle client libraries and setting the `OCI_DIR` environment variable before installing the gem set.

When connecting to the Voyager OPAC, you must set environment variable `NLS_LANG` to `'AMERICAN_AMERICA.US7ASCII'`.  The best way to do this is by adding an export to your `.bashrc` file: `export NLS_LANG='AMERICAN_AMERICA.US7ASCII'`

To verify that NLS_LANG is set properly and being picked up by the OCI8 gem for all connections, you can run the `hysync:check_oci8_encoding` rake task. If set correctly, you should see the following output:

```
$ bundle exec rake hysync:check_oci8_encoding
OCI8 encoding is: #<Encoding:US-ASCII>
```

This app also depends on yaz, a Z39.50 client library.

## Deployment instructions
The deployment is standard CUL deployment via capistrano.
