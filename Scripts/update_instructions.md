### Dependency Update

CoreZen's media dependencies (FFmpeg, libmpv and the libraries they need) are built from
pinned sources by `build_dependencies.py`, for Apple Silicon (arm64) only and a fixed minimum
macOS: `macos_deployment_target` in `build_dependencies.json`, which must match
`MACOSX_DEPLOYMENT_TARGET` in `CoreZen.xcodeproj`. The builds are LGPL and decode-only. Only
Xcode (or its command line tools), git and Python 3 need to be installed; Homebrew isn't used.

Intel/x86_64 support was dropped in November 2026, when Apple ended Intel Mac support with
macOS 26.

1. Update the pinned sources

Edit `build_dependencies.json`: each package's version, URL and SHA-256 (or git tag and
commit), and its build options. If you change `macos_deployment_target`, change
`MACOSX_DEPLOYMENT_TARGET` in the Xcode project to match.

2. Build and stage dependencies

```commandline
./build_dependencies.py --output ../Dependencies
```

This builds each package under `../build/dependencies`, skipping packages that haven't changed
since they were last built, then replaces `../Dependencies` with `lib/` (dylibs with `@rpath`
install names and ad-hoc signatures), `include/` and `dependencies.resolved`. It stops if a
library isn't arm64 only or isn't built for the deployment target. A full build takes about
five minutes on a 10-core Apple silicon Mac. Use `--only <package>` to rebuild one package, or
`--clean` to start from scratch.

3. Update Xcode project

```commandline
./update_project.py
```

This updates `project.pbxproj` to match the current contents of `Dependencies/lib` and
`Dependencies/include`. It replaces all library file references, header references,
Copy Files entries, and Link Binary with Libraries entries.

Libraries listed under `linked_libraries` in `dependencies.json` are added to
Link Binary with Libraries. Use `--dry-run` to preview changes without writing.

4. Build and test

Build and test the CoreZen scheme, and fix anything the new library versions broke:

```commandline
xcodebuild test -scheme CoreZen -project ../CoreZen.xcodeproj
```

5. Create dependency archive

```commandline
./stage_dependencies.py --compress
```

This writes `Dependencies_<date>.tar.gz` into this directory and copies
`dependencies.resolved` here so the staged versions are tracked in git.

6. Upload archive and update download URL

Upload the archive to AWS. Remember to set read permissions to "world". Then set
`download_url` in `dependencies.json` to the new archive. CI fetches it with
`./stage_dependencies.py --download`, so the build fails until the upload is done.

#### Staging from Homebrew

Running `./stage_dependencies.py` with no options still stages libmpv and everything it links
against from Homebrew (`search_paths` and `headers` in `dependencies.json`). Homebrew's bottles
are built for recent macOS versions, so they can need a newer macOS than CoreZen's deployment
target, which is why the source build replaced it.
