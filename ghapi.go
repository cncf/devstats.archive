package devstats

import (
	"context"
	"os"
	"strings"
	"time"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

// IssueConfig - holds issue data
type IssueConfig struct {
	Repo        string
	Number      int
	IssueID     int64
	Pr          bool
	MilestoneID *int64
	Labels      string
	LabelsMap   map[int64]string
	GhIssue     *github.Issue
	CreatedAt   time.Time
}

// IssueConfigAry - allows sorting IssueConfig array by IssueID annd then event creation date
type IssueConfigAry []IssueConfig

func (ic IssueConfigAry) Len() int      { return len(ic) }
func (ic IssueConfigAry) Swap(i, j int) { ic[i], ic[j] = ic[j], ic[i] }
func (ic IssueConfigAry) Less(i, j int) bool {
	if ic[i].IssueID != ic[j].IssueID {
		return ic[i].IssueID < ic[j].IssueID
	}
	return ic[i].CreatedAt.Before(ic[j].CreatedAt)
}

// HandlePossibleError - display error specific message, detect rate limit and abuse
func HandlePossibleError(err error, cfg *IssueConfig, info string) {
	if err != nil {
		_, rate := err.(*github.RateLimitError)
		_, abuse := err.(*github.AbuseRateLimitError)
		if abuse || rate {
			Printf("Hit rate limit (%s) for %v\n", info, cfg)
		}
		//FatalOnError(err)
		Printf("%s error: %v, non fatal, exiting 0 status\n", os.Args[0], err)
		os.Exit(0)
	}
}

// GetRateLimits - returns all and remaining API points and duration to wait for reset
// when core=true - returns Core limits, when core=false returns Search limits
func GetRateLimits(gctx context.Context, gc *github.Client, core bool) (int, int, time.Duration) {
	rl, _, err := gc.RateLimits(gctx)
	if err != nil {
		Printf("GetRateLimit: %v\n", err)
	}
	if rl == nil {
		return -1, -1, time.Duration(5) * time.Second
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
