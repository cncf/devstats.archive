package main

import (
	"crypto"
	"crypto/rsa"
	"crypto/sha1"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	lib "gha2db"
	"io/ioutil"
	"net/http"
	"net/url"
)

// Payload signature verification based on:
// https://gist.github.com/theshapguy/7d10ea4fa39fab7db393021af959048e

type payload struct {
	Branch        string `json:"branch"`
	Result        int    `json:"result"`
	ResultMessage string `json:"result_message"`
	Type          string `json:"type"`
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
		lib.Printf("webhook: error: %v", err)
		errMsg := fmt.Sprintf("error: %v", err)
		respondWithError(w, errMsg)
		return true
	}
	return false
}

// webhookHandler receives Travis CI webhook and parses it
func webhookHandler(w http.ResponseWriter, r *http.Request) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Payload checking
	if ctx.CheckPayload {
		key, err := travisPublicKey()
		if checkError(w, err) {
			return
		}
		signature, err := payloadSignature(r)
		if checkError(w, err) {
			return
		}
		payload := payloadDigest(r.FormValue("payload"))
		err = rsa.VerifyPKCS1v15(key, crypto.SHA1, payload, signature)
		if err != nil {
			lib.Printf("webhook: unauthorized payload: %v", err)
			respondWithError(w, errors.New("unauthorized payload").Error())
			return
		}
	}
	body, err := ioutil.ReadAll(r.Body)
	if checkError(w, err) {
		return
	}
	sBody, err := url.QueryUnescape(string(body))
	if checkError(w, err) {
		return
	}
	var payload payload
	jsonStr := []byte(sBody[8:])
	err = json.Unmarshal(jsonStr, &payload)
	if checkError(w, err) {
		return
	}
	//pretty := lib.PrettyPrintJSON(jsonStr)
	fmt.Printf("%+v\n", payload)
	respondWithSuccess(w, "ok")
}

func main() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Start webhook server
	// WebHookRoot defaults to "/"
	// WebHookPort defaults to ":1982"
	http.HandleFunc(ctx.WebHookRoot, webhookHandler)
	http.ListenAndServe(ctx.WebHookPort, nil)
}
