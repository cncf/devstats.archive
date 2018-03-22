package devstats

import (
	"context"
	"io/ioutil"
	"strings"
	"time"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

// GetRateLimits - returns all and remaining API points and duration to wait for reset
// when core=true - returns Core limits, when core=flase returns Search limits
func GetRateLimits(gctx context.Context, gc *github.Client, core bool) (int, int, time.Duration) {
	rl, _, err := gc.RateLimits(gctx)
	FatalOnError(err)
	// rl: {Core:github.Rate{Limit:5000, Remaining:4997, Reset:github.Timestamp{2018-03-22 10:46:38 +0000 UTC}},
	//     {Search:github.Rate{Limit:30, Remaining:30, Reset:github.Timestamp{2018-03-22 10:28:32 +0000 UTC}}
	// }
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
		bytes, err := ioutil.ReadFile(ctx.GitHubOAuth)
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

	// Get Tags list
	/*
		opt := &github.ListOptions{PerPage: 1000}
		//var allTags []*github.RepositoryTag
		for {
			tags, resp, err := client.Repositories.ListTags(ghCtx, org, repo, opt)
			if _, ok := err.(*github.RateLimitError); ok {
				Printf("Hit rate limit on ListTags for  %s '%s'\n", orgRepo, annoRegexp)
			}
			FatalOnError(err)
			allTags := len(tags)
			dtStart := time.Now()
			lastTime := dtStart
			for i, tag := range tags {
				tagName := *tag.Name
				ProgressInfo(i, allTags, dtStart, &lastTime, time.Duration(10)*time.Second, tagName)
				if re != nil && !re.MatchString(tagName) {
					continue
				}
				sha := *tag.Commit.SHA
				commit, _, err := client.Repositories.GetCommit(ghCtx, org, repo, sha)
				if _, ok := err.(*github.RateLimitError); ok {
					Printf("hit rate limit on GetCommit for %s '%s'\n", orgRepo, annoRegexp)
				}
				FatalOnError(err)
			}
			if resp.NextPage == 0 {
				break
			}
			opt.Page = resp.NextPage
		}
	*/

	return
}
