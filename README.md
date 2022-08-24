# Application version
When an application is developed, it may be a good idea to have its version embedded into the executable. You may always check the application version by some command like `myapp --version`, etc. The repository proposes only a shell script, which will calculate the version based on the `git` commits and tags used. 

## How to use it
Just run the `verson.sh` in the application directory which contains your application. The script will print the version it calculated based on your branch state. Try this:

```shell
./version.sh --help
```

and even for the repo try this:
```shell
./version.sh
```

## Makefile example
This example if for Golang and the Makefile:

```makefile
# Versioning/build metadata
FULL_VERSION ?= `path_to_version_script/version.sh`
VERSION ?= `path_to_version_script/version.sh -s`
REV=$(shell git rev-parse HEAD)
NOW=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Linker flags
LDFLAGS="-X '$(MODULE)/pkg/version.Version=$(VERSION)' \
		 -X '$(MODULE)/pkg/version.GitCommit=$(REV)' \
		 -X '$(MODULE)/pkg/version.BuildDate=$(NOW)' \
		 -X '$(MODULE)/pkg/version.GoVersion=$(shell go version)' "
		 
.PHONY: build
build: 
	go build -ldflags=$(LDFLAGS)-v ./...
	
```

## How to refer to the version.sh from my repository?
To run the script use this for example: 

```shell
curl -s https://raw.githubusercontent.com/acquirecloud/appversion/inception/version.sh | bash -s -- --help
```

## How the version is calculated?
The executable versions are based on the git-tags. The following conventions are used:
1. A version complies [Semantic versioning](https://semver.org) rules. Examples: `v0.0.1`, `v0.0.1-rc1` etc.
2. git-tag for a version should have the format: _vMajor.Minor.Patch_. A tag defines the "base" for the versions derived from the tag. For example, the tags `v0.0.1`, `v1.2.3` are valid, but `v1.2.3-rc1` - is not a valid tag. The `v1.2.3-rc1` could be a valid version based on a tag like `v1.2.x`. **IMPORTANT**: `v1.2.3-rc1` is a valid VERSION(see above), but it is not a valid git-tag for the version.
3. No two git-version-tags could be applied to the same revision.
4. Every git-version-tag must be greater than any of the previous ones placed before it.
5. A version for any given commit is calculated as a distance between the closest version tag and its commit. Only _PATCH_ number of the tag is changed in this case. A suffix could be applied to the final version (see following rules).
6. Versions for a branch that is not `main` have the format _vMajor.Minor.Patch-Suffix_. For example, an artifact built from the branch `hot_fix` will have the version - `v1.12.2-hot_fix` etc.
7. Versions that are built with uncommitted changes will have the format - _vMajor.Minor.Patch-Suffix-uncommitted_. For example, an artifact built from the branch `hot_fix` with some uncommitted changes will have the version - `v1.12.2-hot_fix-uncommitted` etc.

Example:
```
         v0.1.1
master ----x----x----x----x----x----------------x----x----x-----> 
           C1   C2    \                         C3  /    C6
                       \         v0.2.0            /
test   . . . . . . . . .+---x------x-----x----x---+  
                            C7     C4         C5
```
On the picture above two tags were applied: `v0.1.1` at C1 and `v0.2.0` at C4. The commits C1-C7 will have the following versions:

C1 - `v0.1.1`

C2 - `v0.1.2`

C3 - `v0.1.6`

C4 - `v0.2.0-test`

C5 - `v0.2.2-test`

C6 - `v0.2.5`

C7 - `v0.1.4-test`

**IMPORTANT**: So, as merges are done by running `git ...` commands, some of the rules above (#4, for instance) could be violated by a branch merge. Please always double-check that the applied tags after a merge don't violate the above rules.

**IMPORTANT**: git rebase could be a problem. Rule of thumb - don't do it. If you want, just do it on branches with no version tags.
