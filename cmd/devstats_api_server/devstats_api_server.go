package main

import (
	lib "devstats"
	"encoding/json"
	"io/ioutil"
	"net/http"

	"github.com/gorilla/mux"
	yaml "gopkg.in/yaml.v2"
)

// endPoint - single API endpoint definition
type endPoint struct {
	Method   string `json:"method"`
	Path     string `json:"path"`
	function func(http.ResponseWriter, *http.Request)
}

// apiContext holds global API server context
type apiContext struct {
	ctx          lib.Ctx
	dataPrefix   string
	allProjects  lib.AllProjects
	projectNames []string
	projects     []lib.Project
	endpoints    []endPoint
}

// outputJSON write final JSON from "data" to "writer"
// depending on "pretty" param presence in "request"
func (actx *apiContext) outputJSON(writer http.ResponseWriter, request *http.Request, data interface{}) {
	encoder := json.NewEncoder(writer)
	// params := mux.Vars(request)
	//_, pretty := params["pretty"]
	_, pretty := request.URL.Query()["pretty"]
	if pretty {
		encoder.SetIndent("", "  ")
	}
	encoder.Encode(data)
}

// getProjects - return projects data
func (actx *apiContext) getProjects() []lib.Project {
	return actx.projects
}

// getProjectsJSON - return projects as JSON
func (actx *apiContext) getProjectsJSON(w http.ResponseWriter, r *http.Request) {
	actx.outputJSON(w, r, actx.getProjects())
}

// getAllProjects - return all projects data
func (actx *apiContext) getAllProjects() lib.AllProjects {
	return actx.allProjects
}

// getAllProjectsJSON - return all projects as JSON
func (actx *apiContext) getAllProjectsJSON(w http.ResponseWriter, r *http.Request) {
	actx.outputJSON(w, r, actx.getAllProjects())
}

// getProjectNames - return projects names data
func (actx *apiContext) getProjectNames() []string {
	return actx.projectNames
}

// getProjectnamesJSON - return projects names as JSON
func (actx *apiContext) getProjectNamesJSON(w http.ResponseWriter, r *http.Request) {
	actx.outputJSON(w, r, actx.getProjectNames())
}

// getEndpoints - return projects names data
func (actx *apiContext) getEndpoints() interface{} {
	var result = struct {
		Message   string     `json:"message"`
		Endpoints []endPoint `json:"endpoints"`
	}{
		Message:   "You can add ?pretty flag to make JSONs human readable",
		Endpoints: actx.endpoints,
	}
	return result
}

// getEndpointsJSON - return projects names as JSON
func (actx *apiContext) getEndpointsJSON(w http.ResponseWriter, r *http.Request) {
	actx.outputJSON(w, r, actx.getEndpoints())
}

func main() {
	// Environment context parse
	var actx apiContext
	actx.ctx.Init()

	// Local or cron mode?
	actx.dataPrefix = actx.ctx.DataDir
	if actx.ctx.Local {
		actx.dataPrefix = "./"
	}

	// Read defined projects
	data, err := ioutil.ReadFile(actx.dataPrefix + actx.ctx.ProjectsYaml)
	lib.FatalOnError(err)
	lib.FatalOnError(yaml.Unmarshal(data, &actx.allProjects))
	actx.projectNames, actx.projects = lib.GetProjectsList(&actx.ctx, &actx.allProjects)

	// Define endpoints
	actx.endpoints = []endPoint{
		{Method: "GET", Path: "/endpoints", function: actx.getEndpointsJSON},
		{Method: "GET", Path: "/projects", function: actx.getProjectsJSON},
		{Method: "GET", Path: "/projectnames", function: actx.getProjectNamesJSON},
		{Method: "GET", Path: "/allprojects", function: actx.getAllProjectsJSON},
	}

	// Router
	router := mux.NewRouter()
	for _, endpoint := range actx.endpoints {
		router.HandleFunc(endpoint.Path, endpoint.function).Methods(endpoint.Method)
	}
	lib.FatalOnError(http.ListenAndServe(":2018", router))
}
