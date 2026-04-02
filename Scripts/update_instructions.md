### Dependency Update

1. Update dependencies in Homebrew

```commandline
brew update
brew outdated
brew upgrade
brew cleanup
```

2. Update x86 dependencies in Homebrew

```commandline
arch -x86_64 /usr/local/bin/brew update
arch -x86_64 /usr/local/bin/brew outdated
arch -x86_64 /usr/local/bin/brew upgrade
arch -x86_64 /usr/local/bin/brew cleanup
```

3. Gather dependencies

```commandline
./stage_dependencies.py
```

4. Combine ARM and x86 libraries

```commandline
./stage_dependencies.py --lipo
```

5. Clean up ARM and x86 library remnants

```commandline
rm -rv ../Dependencies/lib/arm ../Dependencies/lib/x86
```

6. Clean up ARM and x86 headers

```commandline
mv -v ../Dependencies/include/arm/* ../Dependencies/include
rm -rv ../Dependencies/include/x86 ../Dependencies/include/arm
```

7.  Clean up resolved dependencies files

```commandline
mv -v ../Dependencies/dependencies.arm.resolved ../Dependencies/dependencies.resolved
rm -v ../Dependencies/dependencies.x86.resolved
```

8. Create dependency archive

```commandline
./stage_dependencies.py --compress
```

9. Update download URL in dependencies.json 

Upload archive to AWS. Remember to set read permissions to "world".

10. Update libraries in Xcode

Under `CoreZen > Dependencies > lib`, select and delete all libraries. Choose the "Remove References" option.

From Finder, drag everything from `../Dependencies/lib` into Xcode under `CoreZen > Dependencies > lib`. Do not check the boxes to add the libraries to CoreZen or CoreZenTests automatically.

Under `CoreZen > Build Phases > Link Binary with Libraries`, add the following by dragging from the left sidebar:
* libavcodec
* libavformat
* libmpv
* libswscale

Under `CoreZen > Build Phases > Copy Files`, add everything under `Dependencies > lib` by clicking the `+` button at the bottom.

11. Update headers in Xcode

Under `CoreZen > Dependencies > include`, select and delete all folders of headers. Choose the "Remove References" option.

From Finder, drag everything from `../Dependencies/include` into Xcode under `CoreZen > Dependencies > include`.
