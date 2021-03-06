# Stata

A collection of my Stata routines. If you find them useful, please cite! **Comments** and **pull-request** are _most welcome_.

# How to install the packages 

To install a package you can type the following directly from Stata command bar (version 13 onwards) 

`. net install <package_name>, from(https://raw.github.com/fbelotti/Stata/master)`

For Stata 12 or older Stata versions you can download the package as a zip, unzip it, and then

`. net install <package_name>, from(full_local_path_to_files)`

If you want just update the package, add the option `replace` to previous commands.

If you would like to get older version of the packages, then you should clone the repo and then use rev-list as noted [here](http://stackoverflow.com/questions/6990484/git-checkout-by-date).

## SSC

Some of the older packages are also available via the Boston SSC archive. To install them you can type 

`. ssc install <package_name>`

# Disclaimer

_You can use the Stata commands available in this repo at your own risk. The author is not responsible for any mistake that may be caused by these programs._ 

