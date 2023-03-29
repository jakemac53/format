## Overview

This package is a simple wrapper script around the dart formatter which enables
configuration for its supported options via `format.dart.yaml` files.

It is intended to be globally activated `dart pub global activate format`. You
can then run it like either `dart pub global run format` or just `format`, if
you have your pub cache bin directory on your PATH.

Configuration files are loaded based on the directory paths passed to the
command, and will search from each provided path up the file system until it
finds a `format.dart.yaml` file, and load the first one it sees.

## File format

The config file accepts 3 top level options:

- **include**: A list of globs of file paths to format, defaults to `**/*.dart`.
  - Note that this does support non-dart extensions if you glob can match them,
    so be careful to be specific or it will choke on non-parseable files.
- **exclude**: A list of globs of file paths to not format, defaults empty.
  - This is a filter over files that matched the `includes` globs.
- **line_length**: Wrap lines longer than this many characters, defaults to 80.

## Gotchas

### Config files are loaded based on given paths, not formatted files

Since we load `format.dart.yaml` files based on paths given, if there is a
configuration file in a subdirectory of a given path, we _will not_ respect it.

The assumption is these config files will live at the package or repo level, or
in users home directories, and that users generally initiate formatting from
those same places, so this won't be something users hit often.

We may add support for this in the future though, if users run ask for it.

### Not all arguments to `dart format` are supported

These are mostly added on an as needed basis. If this command doesn't support
something that you want it to, please file an issue.

### Editor integration

There is not currently built a way to use this as your default formatter in
editors. You may wish to just disable formatting in your editor for now, until
extensions for that editor are available.

Please file issues for your desired editor support so that the demand can be
measured.

This is definitely an area where outside contributions would be welcome.
