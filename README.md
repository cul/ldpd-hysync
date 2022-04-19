# README

This application pulls data from Voyager and transforms it into a Hyacinth digital object JSON update.

## Ruby version
This app is designed to run on Ruby 3.0

## System dependencies

### OCI

This app depends on oci8; this requires installing the Oracle client libraries and setting the `OCI_DIR` environment variable before installing the gem set.  Note that the version of Oracle that we currently use with Voyager is 12.1.

Check out the ruby-oci8 repository for setup instructions: https://github.com/kubo/ruby-oci8

Or if you want quick macOS setup instructions (which are hopefully still up to date by the time you're reading this, and still support Oracle 12.1) and you use homebrew, just run the following:

```
brew tap InstantClientTap/instantclient
brew install instantclient-basic
brew install instantclient-sdk
brew install instantclient-sqlplus
```

And then add this environment variable to your bash/zsh profile:

```
export OCI_DIR=$(brew --prefix)/lib
```

**Important note:** When connecting to the Voyager OPAC, you must set environment variable `NLS_LANG` to `'AMERICAN_AMERICA.US7ASCII'`.  The best way to do this is by adding an export to your `.bashrc`/`.zshrc` file: `export NLS_LANG='AMERICAN_AMERICA.US7ASCII'`

To verify that NLS_LANG is set properly and being picked up by the OCI8 gem for all connections, you can run the `hysync:check_oci8_encoding` rake task. If set correctly, you should see the following output:

```
$ bundle exec rake hysync:check_oci8_encoding
OCI8 encoding is: #<Encoding:US-ASCII>
```

This app also depends on yaz, a Z39.50 client library.  You can install it via homebrew by running:

```
 brew install yaz
 ```

## Deployment instructions
The deployment is standard CUL deployment via capistrano.
