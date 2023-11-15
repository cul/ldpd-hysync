# README

This application pulls data from Voyager and transforms it into a Hyacinth digital object JSON update.

## Ruby version
This app is designed to run on Ruby 3.0

## System dependencies

### OCI

This app depends on oci8; this requires installing the Oracle client libraries and setting the `OCI_DIR` environment variable before installing the gem set.  Note that the version of Oracle that we currently use with Voyager is 12.1.

Check out the ruby-oci8 repository for setup instructions: https://github.com/kubo/ruby-oci8

### For INTEL-ONLY** macOS

(Hopefully this is still up to date by the time you're reading this, and still supports Oracle 12.1.)

Use homebrew, just run the following:

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

# For ARM-based Macs

Unfortunately, Oracle doesn't currently offer a release of the above libraries that are compatible with ARM-based Macs.  As an alternative, you can run an Ubuntu 22 VM and download the following files:

https://download.oracle.com/otn_software/linux/instantclient/instantclient-basic-linux-arm64.zip
https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linux-arm64.zip
https://download.oracle.com/otn_software/linux/instantclient/instantclient-sqlplus-linux-arm64.zip

Save them in a new directory at `/opt/oracle/downloads` and then cd to `/opt/oracle` and unzip them:

```
cd /opt/oracle
find ./downloads -name '*.zip' -exec unzip {} \;
```

Then add this to your .bash_profile:
```
# For oci8 gem (connecting to Oracle DB)
export OCI_DIR=/opt/oracle/instantclient_19_19
export NLS_LANG='AMERICAN_AMERICA.US7ASCII'
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/oracle/instantclient_19_19
```

When you run `bundle install`, you might encounter an issue with OpenSSL on Ubuntu 22.  The problem is that Ubuntu 22 comes with OpenSSL 3, but Ruby 3.0 expects OpenSSL 1.  You can fix this by uninstalling and reinstalling Ruby 3.0, but specifying OpenSSL 1:

```
rvm pkg install openssl # Use RVM to install OpenSSL 1
rvm install ruby-3.0.3 --with-openssl-dir=$HOME/.rvm/usr # Point to RVM-installed OpenSSL 1
```

If you have bundle install issues related to bootsnap, you may need to install a JS runtime.  One way to fix this is to install nvm and then install Node 12.

### NLS_LANG setup

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

Or using apt on Ubuntu 22:

```
apt install yaz libyazpp-dev
```

## Deployment instructions
The deployment is standard CUL deployment via capistrano.
