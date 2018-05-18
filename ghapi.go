package devstats

import (
	"context"
	"strings"
	"sync"
	"time"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

// I know global variables are bad, but sometimes GitHub is not returning rate limits
// butt error instead (when 0 API points are available), we can use last known value then
var globalRL *github.RateLimits
var globalRLMutex = &sync.Mutex{}

// GetRateLimits - returns all and remaining API points and duration to wait for reset
// when core=true - returns Core limits, when core=false returns Search limits
func GetRateLimits(gctx context.Context, gc *github.Client, core bool) (int, int, time.Duration) {
	rl, _, err := gc.RateLimits(gctx)
	if err != nil {
		rl = globalRL
	} else {
		globalRLMutex.Lock()
		globalRL = rl
		globalRLMutex.Unlock()
	}
	if core {
		return rl.Core.Limit, rl.Core.Remaining, rl.Core.Reset.Time.Sub(time.Now()) + time.Duration(1)*time.Second
	}
	return rl.Search.Limit, rl.Search.Remaining, rl.Search.Reset.Time.Sub(time.Now()) + time.Duration(1)*time.Second
}

// GHClient - get GitHub client
func GHClient(ctx *Ctx) (ghCtx context.Context, client *github.Client) {
	// Get GitHub OAuth from env or from file
	oAuth := ctx.GitHubOAuth
	if strings.Contains(ctx.GitHubOAuth, "/") {
		bytes, err := ReadFile(ctx, ctx.GitHubOAuth)
		FatalOnError(err)
		oAuth = strings.TrimSpace(string(bytes))
	}

	// GitHub authentication or use public access
	ghCtx = context.Background()
	if oAuth == "-" {
		client = github.NewClient(nil)
	} else {
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: oAuth},
		)
		tc := oauth2.NewClient(ghCtx, ts)
		client = github.NewClient(tc)
	}

	return
}
