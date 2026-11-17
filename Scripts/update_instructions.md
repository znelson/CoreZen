### Dependency Update

CoreZen ships Apple Silicon (arm64) dependencies only. Intel/x86_64 support was dropped in
November 2026: Apple ended Intel Mac support with macOS 26, and Homebrew stopped building
Intel bottles in September 2026. Everything below runs against the native Homebrew at
`/opt/homebrew`.

1. Update dependencies in Homebrew

```commandline
brew update
brew outdated
brew upgrade
brew cleanup
```

2. Gather dependencies

```commandline
./stage_dependencies.py
```

This deletes `../Dependencies`, then copies libmpv and everything it links against out of
`/opt/homebrew` into `../Dependencies/lib`, rewrites their install names to `@rpath`, copies
headers into `../Dependencies/include`, and writes `../Dependencies/dependencies.resolved`.
It refuses any library without an arm64 slice.

3. Update Xcode project

```commandline
./update_project.py
```

This updates `project.pbxproj` to match the current contents of `Dependencies/lib` and
`Dependencies/include`. It replaces all library file references, header references,
Copy Files entries, and Link Binary with Libraries entries.

Libraries listed under `linked_libraries` in `dependencies.json` are added to
Link Binary with Libraries. Use `--dry-run` to preview changes without writing.

4. Build

Build the CoreZen scheme and fix anything the new library versions broke:

```commandline
xcodebuild build -scheme CoreZen -project ../CoreZen.xcodeproj
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
