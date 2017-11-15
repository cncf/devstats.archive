package main

import (
	"crypto"
	"crypto/rsa"
	"crypto/sha1"
	"crypto/x509"
	lib "devstats"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"time"
)

// Payload signature verification based on:
// https://gist.github.com/theshapguy/7d10ea4fa39fab7db393021af959048e

type repository struct {
	Name      string `json:"name"`
	OwnerName string `json:"owner_name"`
}

type payload struct {
	Branch        string     `json:"branch"`
	Result        int        `json:"result"`
	ResultMessage string     `json:"result_message"`
	Type          string     `json:"type"`
	AuthorEmail   string     `json:"author_email"`
	AuthorName    string     `json:"author_name"`
	Repo          repository `json:"repository"`
}

type configKey struct {
	Config struct {
		Host        string `json:"host"`
		ShortenHost string `json:"shorten_host"`
		Assets      struct {
			Host string `json:"host"`
		} `json:"assets"`
		Pusher struct {
			Key string `json:"key"`
		} `json:"pusher"`
		Github struct {
			APIURL string   `json:"api_url"`
			Scopes []string `json:"scopes"`
		} `json:"github"`
		Notifications struct {
			Webhook struct {
				PublicKey string `json:"public_key"`
			} `json:"webhook"`
		} `json:"notifications"`
	} `json:"config"`
}

func respondWithError(w http.ResponseWriter, m string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(401)
	message := fmt.Sprintf("{\"message\": \"%s\"}", m)
	w.Write([]byte(message))
}

func respondWithSuccess(w http.ResponseWriter, m string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(200)
	message := fmt.Sprintf("{\"message\": \"%s\"}", m)
	w.Write([]byte(message))
}

func payloadSignature(r *http.Request) ([]byte, error) {
	signature := r.Header.Get("Signature")
	b64, err := base64.StdEncoding.DecodeString(signature)
	if err != nil {
		return nil, errors.New("cannot decode signature")
	}
	return b64, nil
}

func payloadDigest(payload string) []byte {
	hash := sha1.New()
	hash.Write([]byte(payload))
	return hash.Sum(nil)
}

func parsePublicKey(key string) (*rsa.PublicKey, error) {
	// https://golang.org/pkg/encoding/pem/#Block
	block, _ := pem.Decode([]byte(key))

	if block == nil || block.Type != "PUBLIC KEY" {
		return nil, errors.New("invalid public key")
	}

	publicKey, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return nil, errors.New("invalid public key")
	}

	return publicKey.(*rsa.PublicKey), nil
}

func travisPublicKey() (*rsa.PublicKey, error) {
	response, err := http.Get("https://api.travis-ci.org/config")

	if err != nil {
		return nil, errors.New("cannot fetch travis public key")
	}
	defer response.Body.Close()

	decoder := json.NewDecoder(response.Body)
	var t configKey
	err = decoder.Decode(&t)
	if err != nil {
		return nil, errors.New("cannot decode travis public key")
	}

	key, err := parsePublicKey(t.Config.Notifications.Webhook.PublicKey)
	if err != nil {
		return nil, err
	}

	return key, nil
}

// checkError: report error to HTTP writer if present
func checkError(w http.ResponseWriter, err error) bool {
	if err != nil {
		lib.Printf("webhook: error: %v\n", err)
		errMsg := fmt.Sprintf("error: %v", err)
		respondWithError(w, errMsg)
		return true
	}
	return false
}

// successPayload: is this a success payload?
func successPayload(ctx *lib.Ctx, pl payload) bool {
	if pl.Repo.Name != "devstats" || pl.Repo.OwnerName != "cncf" {
		return false
	}
	ok := false
	for _, status := range ctx.DeployStatuses {
		if pl.ResultMessage == status {
			ok = true
			break
		}
	}
	if !ok {
		return false
	}
	ok = false
	for _, result := range ctx.DeployResults {
		if pl.Result == result {
			ok = true
			break
		}
	}
	if !ok {
		return false
	}
	ok = false
	for _, typ := range ctx.DeployTypes {
		if pl.Type == typ {
			ok = true
			break
		}
	}
	if !ok {
		return false
	}
	ok = false
	for _, branch := range ctx.DeployBranches {
		if pl.Branch == branch {
			ok = true
			break
		}
	}
	return ok
}

// webhookHandler receives Travis CI webhook and parses it
func webhookHandler(w http.ResponseWriter, r *http.Request) {
	// Start date
	dtStart := time.Now()

	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Processing new webhook
	lib.Printf("WebHook processing event at %v\n", time.Now())

	// Payload checking
	var jsonStr string
	if ctx.CheckPayload {
		key, err := travisPublicKey()
		if checkError(w, err) {
			return
		}
		signature, err := payloadSignature(r)
		if checkError(w, err) {
			return
		}
		jsonStr = r.FormValue("payload")
		payload := payloadDigest(jsonStr)
		err = rsa.VerifyPKCS1v15(key, crypto.SHA1, payload, signature)
		if err != nil {
			lib.Printf("webhook: unauthorized payload: %v", err)
			respondWithError(w, errors.New("unauthorized payload").Error())
			return
		}
	} else {
		body, err := ioutil.ReadAll(r.Body)
		if checkError(w, err) {
			return
		}
		sBody, err := url.QueryUnescape(string(body))
		if checkError(w, err) {
			return
		}
		jsonStr = sBody[8:]
	}
	//pretty := lib.PrettyPrintJSON([]byte(jsonStr))
	var payload payload
	err := json.Unmarshal([]byte(jsonStr), &payload)
	if checkError(w, err) {
		return
	}
	lib.Printf("WebHook: repo: %s/%s, allowed: cncf/devstats\n", payload.Repo.OwnerName, payload.Repo.Name)
	lib.Printf("WebHook: branch: %s, allowed branches: %v\n", payload.Branch, ctx.DeployBranches)
	lib.Printf("WebHook: status: %s, allowed statuses: %v\n", payload.ResultMessage, ctx.DeployStatuses)
	lib.Printf("WebHook: type: %s, allowed types: %v\n", payload.Type, ctx.DeployTypes)
	lib.Printf("WebHook: result: %d, allowed results: %v\n", payload.Result, ctx.DeployResults)
	lib.Printf("WebHook: author: name: %s, email: %s\n", payload.AuthorName, payload.AuthorEmail)
	if !successPayload(&ctx, payload) {
		checkError(w, errors.New("webhook: skipping deploy due to wrong status, result, branch and/or type"))
		return
	}
	err = os.Chdir(ctx.ProjectRoot)
	if checkError(w, err) {
		return
	}
	// Do deployment
	lib.Printf("WebHook: deploying via `%s`\n", "make install")
	ctx.ExecFatal = false
	lib.Printf("WebHook: git checkout %s\n", payload.Branch)
	err = lib.ExecCommand(&ctx, []string{"git", "checkout", payload.Branch}, nil)
	if checkError(w, err) {
		return
	}
	lib.Printf("WebHook: %s\n", "git pull")
	err = lib.ExecCommand(&ctx, []string{"git", "pull"}, nil)
	if checkError(w, err) {
		return
	}
	lib.Printf("WebHook: %s\n", "make")
	err = lib.ExecCommand(&ctx, []string{"make"}, nil)
	if checkError(w, err) {
		return
	}
	lib.Printf("WebHook: %s\n", "make install")
	err = lib.ExecCommand(&ctx, []string{"make", "install"}, nil)
	if checkError(w, err) {
		return
	}
	dtEnd := time.Now()
	lib.Printf("WebHook: deployed via `make install` in %v\n", dtEnd.Sub(dtStart))
	respondWithSuccess(w, "ok")
}

func main() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()
	if ctx.ProjectRoot == "" {
		lib.Printf("You need to define reposiory path via GHA2DB_PROJECT_ROOT=/path/to/repo %s\n", os.Args[0])
		return
	}

	// Start webhook server
	// WebHookHost defaults to "127.0.0.1"
	// WebHookPort defaults to ":1982"
	// WebHookRoot defaults to "/"
	http.HandleFunc(ctx.WebHookRoot, webhookHandler)
	http.ListenAndServe(ctx.WebHookHost+ctx.WebHookPort, nil)
}
