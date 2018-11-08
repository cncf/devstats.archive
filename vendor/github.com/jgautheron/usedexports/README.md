# usedexports

Find exported variables (`const`, `var`, `func`, `struct`) in Go that could be unexported.

The [Go Challenge #5](http://golang-challenge.com/go-challenge5/) sparked the idea of detecting unused exports.  
My goal with `usedexports` is to report on unused exports for a local application, and not scan the whole `GOPATH`.

### Get Started

    $ go get github.com/jgautheron/usedexports
    $ usedexports ./...

### Usage

```
Usage:

  usedexports ARGS <directory>

Flags:

  -ignore        exclude files matching the given regular expression
  -force         scan the path even if there is no main package

Examples:

  usedexports ./...
  usedexports -ignore "yacc|\.pb\." $GOPATH/src/github.com/cockroachdb/cockroach/...
```

:warning: By default, `usedexports` will report only exports which are related to an application, not a library.  
For this reason, `usedexports` will stop if it won't find the `main` package in the specified path. You can ignore this behaviour by using the `-force` flag.

### Limitations

1. `usedexports` does not take into account the composed interfaces, so it will report by example on the `MarshalJSON` composed function.
2. If there are multiple `struct` methods in the same package, only the last occurrence will be reported.

### Other static analysis tools

- [gogetimports](https://github.com/jgautheron/gogetimports): Get a JSON-formatted list of imports.
- [goconst](https://github.com/jgautheron/goconst): Find repeated strings that could be replaced by a constant.

### License
MIT