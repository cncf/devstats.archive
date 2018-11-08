package main

import (
	"errors"
	"flag"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

const usageDoc = `usedexports: find exported variables that could be unexported

Usage:

  usedexports ARGS <directory>

Flags:

  -ignore        exclude files matching the given regular expression
  -force         scan the path even if there is no main package

Examples:

  usedexports ./...
  usedexports -ignore "yacc|\.pb\." $GOPATH/src/github.com/cockroachdb/cockroach/...
`

var (
	flagIgnore = flag.String("ignore", "", "ignore files matching the given regular expression")
	flagForce  = flag.Bool("force", false, "scan the path even if there is no main package")

	sourcePath = ""
	exports    = map[string]*itemInfo{}
)

type itemInfo struct {
	name        string
	token       token.Token
	position    token.Position
	packageName string
	count       int
}

func main() {
	flag.Parse()
	log.SetPrefix("usedexports: ")

	args := flag.Args()
	if len(args) != 1 {
		usage()
	}
	sourcePath = args[0]

	var err error

	err = parseTree(parseExports)
	if err != nil {
		log.Println(err)
		os.Exit(1)
	}

	err = parseTree(parseUsedExports)
	if err != nil {
		log.Println(err)
		os.Exit(1)
	}

	printOutput()
}

func usage() {
	fmt.Fprintf(os.Stderr, usageDoc)
	os.Exit(1)
}

func printOutput() {
	for _, item := range exports {
		if item.count > 0 {
			continue
		}

		fmt.Printf(`%s %s "%s" is exported but not used locally`, item.position.String(), item.token.String(), item.name)
		fmt.Print("\n")
	}
}

func parseTree(fn func(string) error) error {
	pathLen := len(sourcePath)
	// Parse recursively the given path if the recursive notation is found
	if pathLen >= 5 && sourcePath[pathLen-3:] == "..." {
		filepath.Walk(sourcePath[:pathLen-3], func(p string, f os.FileInfo, err error) error {
			if err != nil {
				log.Println(err)
				// resume walking
				return nil
			}

			if f.IsDir() {
				fn(p)
			}
			return nil
		})
	} else {
		fn(sourcePath)
	}
	return nil
}

func parseExports(dir string) error {
	fset := token.NewFileSet()
	pkgs, err := parser.ParseDir(fset, dir, func(info os.FileInfo) bool {
		valid, name := true, info.Name()

		if len(*flagIgnore) != 0 {
			match, err := regexp.MatchString(*flagIgnore, dir+name)
			if err != nil {
				log.Fatal(err)
				return true
			}
			if match {
				valid = false
			}
		}

		return valid
	}, 0)
	if err != nil {
		return err
	}

	// Scan by default ONLY the main package since other
	// packages expose on purpose a public API
	if !*flagForce {
		if _, ok := pkgs["main"]; !ok {
			return errors.New("No main package has been found in the given path, use -force if you'd still like to get a report")
		}

	}

	for _, pkg := range pkgs {
		for fn, f := range pkg.Files {
			ast.Walk(&exportsVisitor{
				fileSet:     fset,
				packageName: pkg.Name,
				fileName:    fn,
			}, f)
		}
	}

	return nil
}

type exportsVisitor struct {
	fileSet               *token.FileSet
	packageName, fileName string
}

func (v *exportsVisitor) Visit(node ast.Node) ast.Visitor {
	if node == nil {
		return v
	}

	switch t := node.(type) {
	case *ast.GenDecl:
		if t.Tok != token.CONST && t.Tok != token.VAR {
			return v
		}

		for _, spec := range t.Specs {
			val := spec.(*ast.ValueSpec)
			for i := range val.Names {
				if val.Names[i].IsExported() {
					v.addExportedItem(val.Names[i].Name, val.Names[i].Pos(), t.Tok)
				}
			}
		}
	case *ast.FuncDecl:
		if t.Name.IsExported() {
			name := t.Name.String()
			// if t.Recv != nil {
			// 	// Handle only simple cases for now: single object
			// 	if len(t.Recv.List) == 1 {
			// 		if obj, ok := t.Recv.List[0].Type.(*ast.Ident); ok {
			// 			name = obj.String() + "." + name
			// 		}
			// 		if obj, ok := t.Recv.List[0].Type.(*ast.StarExpr); ok {
			// 			ident := obj.X.(*ast.Ident)
			// 			name = ident.Obj.Name + "." + name
			// 		}
			// 	}
			// }
			v.addExportedItem(name, t.Pos(), token.FUNC)
		}
	case *ast.TypeSpec:
		if t.Name.IsExported() {
			v.addExportedItem(t.Name.String(), t.Pos(), token.TYPE)
		}
	}

	return v
}

func (v *exportsVisitor) addExportedItem(name string, pos token.Pos, tok token.Token) {
	exports[v.packageName+"-"+name] = &itemInfo{
		name:     name,
		token:    tok,
		position: v.fileSet.Position(pos),
		count:    0,
	}
}

func parseUsedExports(dir string) error {
	fset := token.NewFileSet()
	pkgs, err := parser.ParseDir(fset, dir, nil, 0)
	if err != nil {
		return err
	}

	importPath, err := getImportPath()
	if err != nil {
		return err
	}

	for _, pkg := range pkgs {
		for fn, f := range pkg.Files {

			// Build the imports map
			imports, importIdent := map[string]*ast.ImportSpec{}, ""
			for _, imprt := range f.Imports {
				pathVal := imprt.Path.Value

				// Scan only internal packages
				if !strings.Contains(pathVal, "./") && !strings.Contains(pathVal, importPath) {
					continue
				}

				if imprt.Name != nil {
					importIdent = imprt.Name.String()
				} else if strings.Contains(pathVal, "/") {
					len := strings.LastIndex(pathVal, "/")
					importIdent = pathVal[len+1:]
				} else {
					importIdent = pathVal
				}

				importIdent = strings.Replace(importIdent, `"`, "", 2)
				imports[importIdent] = imprt
			}

			ast.Walk(&usedExportsVisitor{
				imports:     imports,
				fileSet:     fset,
				packageName: pkg.Name,
				fileName:    fn,
			}, f)
		}
	}

	return nil
}

type usedExportsVisitor struct {
	imports               map[string]*ast.ImportSpec
	fileSet               *token.FileSet
	packageName, fileName string
}

func (v *usedExportsVisitor) Visit(node ast.Node) ast.Visitor {
	if node == nil {
		return v
	}

	switch t := node.(type) {
	case *ast.SelectorExpr:
		ident, ok := t.X.(*ast.Ident)
		if !ok {
			return v
		}

		if _, ok := v.imports[ident.Name]; !ok {
			return v
		}

		mapIdx := ident.Name + "-" + t.Sel.String()
		if _, ok := exports[mapIdx]; ok {
			exports[mapIdx].count++
		}
	}

	return v
}

// getImportPath deduces the local import path prefix.
func getImportPath() (string, error) {
	path := strings.Replace(sourcePath, "/...", "", 1)

	fullPath, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}

	// Only support codebases located in the GOPATH
	gopathSrc := os.Getenv("GOPATH") + "/src/"
	if strings.Index(fullPath, gopathSrc) == -1 {
		return "", fmt.Errorf("The given path (%s) is not located in the GOPATH (%s)", fullPath, gopathSrc)
	}

	importPath := strings.Replace(fullPath, gopathSrc, "", 1)
	return importPath, nil
}
