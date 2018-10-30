package main

import (
	"database/sql"
	lib "devstats"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type esRawCommit struct {
	Type                 string   `json:"type"`
	SHA                  string   `json:"sha"`
	EventID              int64    `json:"event_id"`
	AuthorName           string   `json:"author_name"`
	Message              string   `json:"message"`
	ActorLogin           string   `json:"actor_login"`
	RepoName             string   `json:"repo_name"`
	CreatedAt            string   `json:"time"`
	EncryptedEmail       string   `json:"encrypted_author_email"`
	AuthorEmail          string   `json:"author_email"`
	CommitterName        string   `json:"committer_name"`
	CommitterEmail       string   `json:"committer_email"`
	AuthorLogin          string   `json:"author_login"`
	CommitterLogin       string   `json:"committer_login"`
	Org                  string   `json:"org"`
	RepoGroup            string   `json:"repo_group"`
	RepoAlias            string   `json:"repo_alias"`
	ActorName            string   `json:"actor_name"`
	ActorCountryCode     string   `json:"actor_country_code"`
	ActorGender          string   `json:"actor_gender"`
	ActorGenderProb      *float64 `json:"actor_gender_prob"`
	ActorTZ              string   `json:"actor_tz"`
	ActorTZOffset        *int     `json:"actor_tz_offset"`
	ActorCountry         string   `json:"actor_country"`
	AuthorCountryCode    string   `json:"author_country_code"`
	AuthorGender         string   `json:"author_gender"`
	AuthorGenderProb     *float64 `json:"author_gender_prob"`
	AuthorTZ             string   `json:"author_tz"`
	AuthorTZOffset       *int     `json:"author_tz_offset"`
	AuthorCountry        string   `json:"author_country"`
	CommitterCountryCode string   `json:"committer_country_code"`
	CommitterGender      string   `json:"committer_gender"`
	CommitterGenderProb  *float64 `json:"committer_gender_prob"`
	CommitterTZ          string   `json:"committer_tz"`
	CommitterTZOffset    *int     `json:"committer_tz_offset"`
	CommitterCountry     string   `json:"committer_country"`
	ActorCompany         string   `json:"actor_company"`
	AuthorCompany        string   `json:"author_company"`
	Committer            string   `json:"committer_company"`
	Size                 int      `json:"size"`
}

type esRawIssue struct {
	Type                string   `json:"type"`
	ID                  int64    `json:"id"`
	EventID             int64    `json:"event_id"`
	EventCreatedAt      string   `json:"time"`
	CreatedAt           string   `json:"created_at"`
	Body                string   `json:"body"`
	ClosedAt            *string  `json:"closed_at"`
	Comments            int      `json:"comments"`
	Locked              bool     `json:"locked"`
	Number              int      `json:"number"`
	State               string   `json:"state"`
	Title               string   `json:"title"`
	UpdatedAt           string   `json:"updated_at"`
	IsPR                bool     `json:"is_pr"`
	EventType           string   `json:"event_type"`
	RepoName            string   `json:"repo_name"`
	Org                 string   `json:"org"`
	RepoGroup           string   `json:"repo_group"`
	RepoAlias           string   `json:"repo_alias"`
	MilestoneNumber     *int     `json:"milestone_number"`
	MilestoneState      string   `json:"milestone_state"`
	MilestoneTitle      string   `json:"milestone_title"`
	AssigneeLogin       string   `json:"assignee_login"`
	AssigneeName        string   `json:"assignee_name"`
	AssigneeCountryCode string   `json:"assignee_country_code"`
	AssigneeGender      string   `json:"assignee_gender"`
	AssigneeGenderProb  *float64 `json:"assignee_gender_prob"`
	AssigneeTZ          string   `json:"assignee_tz"`
	AssigneeTZOffset    *int     `json:"assignee_tz_offset"`
	AssigneeCountry     string   `json:"assignee_country"`
	ActorLogin          string   `json:"actor_login"`
	ActorName           string   `json:"actor_name"`
	ActorCountryCode    string   `json:"actor_country_code"`
	ActorGender         string   `json:"actor_gender"`
	ActorGenderProb     *float64 `json:"actor_gender_prob"`
	ActorTZ             string   `json:"actor_tz"`
	ActorTZOffset       *int     `json:"actor_tz_offset"`
	ActorCountry        string   `json:"actor_country"`
	UserLogin           string   `json:"creator_login"`
	UserName            string   `json:"creator_name"`
	UserCountryCode     string   `json:"creator_country_code"`
	UserGender          string   `json:"creator_gender"`
	UserGenderProb      *float64 `json:"creator_gender_prob"`
	UserTZ              string   `json:"creator_tz"`
	UserTZOffset        *int     `json:"creator_tz_offset"`
	UserCountry         string   `json:"creator_country"`
	AssigneeCompany     string   `json:"assignee_company"`
	ActorCompany        string   `json:"actor_company"`
	UserCompany         string   `json:"creator_company"`
}

type esRawPR struct {
	Type                string   `json:"type"`
	ID                  int64    `json:"id"`
	EventID             int64    `json:"event_id"`
	EventCreatedAt      string   `json:"time"`
	CreatedAt           string   `json:"created_at"`
	Body                string   `json:"body"`
	ClosedAt            *string  `json:"closed_at"`
	Comments            *int     `json:"comments"`
	Locked              *bool    `json:"locked"`
	Number              int      `json:"number"`
	State               string   `json:"state"`
	Title               string   `json:"title"`
	UpdatedAt           string   `json:"updated_at"`
	BaseSHA             string   `json:"base_sha"`
	HeadSHA             string   `json:"head_sha"`
	MergedAt            *string  `json:"merged_at"`
	MergeCommitSHA      *string  `json:"merge_commit_sha"`
	Merged              *bool    `json:"merged"`
	Mergeable           *bool    `json:"mergeable"`
	Rebaseable          *bool    `json:"rebaseable"`
	MergeableState      *string  `json:"mergeable_state"`
	ReviewComments      *int     `json:"review_comments"`
	MaintainerCanModify *bool    `json:"maintainer_can_modify"`
	Commits             *int     `json:"commits"`
	Additions           *int     `json:"additions"`
	Deletions           *int     `json:"deleteions"`
	ChangedFiles        *int     `json:"changed_files"`
	EventType           string   `json:"event_type"`
	RepoName            string   `json:"repo_name"`
	Org                 string   `json:"org"`
	RepoGroup           string   `json:"repo_group"`
	RepoAlias           string   `json:"repo_alias"`
	MilestoneNumber     *int     `json:"milestone_number"`
	MilestoneState      string   `json:"milestone_state"`
	MilestoneTitle      string   `json:"milestone_title"`
	AssigneeLogin       string   `json:"assignee_login"`
	AssigneeName        string   `json:"assignee_name"`
	AssigneeCountryCode string   `json:"assignee_country_code"`
	AssigneeGender      string   `json:"assignee_gender"`
	AssigneeGenderProb  *float64 `json:"assignee_gender_prob"`
	AssigneeTZ          string   `json:"assignee_tz"`
	AssigneeTZOffset    *int     `json:"assignee_tz_offset"`
	AssigneeCountry     string   `json:"assignee_country"`
	ActorLogin          string   `json:"actor_login"`
	ActorName           string   `json:"actor_name"`
	ActorCountryCode    string   `json:"actor_country_code"`
	ActorGender         string   `json:"actor_gender"`
	ActorGenderProb     *float64 `json:"actor_gender_prob"`
	ActorTZ             string   `json:"actor_tz"`
	ActorTZOffset       *int     `json:"actor_tz_offset"`
	ActorCountry        string   `json:"actor_country"`
	UserLogin           string   `json:"creator_login"`
	UserName            string   `json:"creator_name"`
	UserCountryCode     string   `json:"creator_country_code"`
	UserGender          string   `json:"creator_gender"`
	UserGenderProb      *float64 `json:"creator_gender_prob"`
	UserTZ              string   `json:"creator_tz"`
	UserTZOffset        *int     `json:"creator_tz_offset"`
	UserCountry         string   `json:"creator_country"`
	MergedByLogin       string   `json:"merged_by_login"`
	MergedByName        string   `json:"merged_by_name"`
	MergedByCountryCode string   `json:"merged_by_country_code"`
	MergedByGender      string   `json:"merged_by_gender"`
	MergedByGenderProb  *float64 `json:"merged_by_gender_prob"`
	MergedByTZ          string   `json:"merged_by_tz"`
	MergedByTZOffset    *int     `json:"merged_by_tz_offset"`
	MergedByCountry     string   `json:"merged_by_country"`
	AssigneeCompany     string   `json:"assignee_company"`
	ActorCompany        string   `json:"actor_company"`
	UserCompany         string   `json:"creator_company"`
	MergedByCompany     string   `json:"merged_by_company"`
}

type esRawText struct {
	Type             string   `json:"type"`
	EventID          int64    `json:"event_id"`
	CreatedAt        string   `json:"created_at"`
	Body             string   `json:"body"`
	EventType        string   `json:"event_type"`
	RepoName         string   `json:"repo_name"`
	Org              string   `json:"org"`
	RepoGroup        string   `json:"repo_group"`
	RepoAlias        string   `json:"repo_alias"`
	ActorLogin       string   `json:"actor_login"`
	ActorName        string   `json:"actor_name"`
	ActorCountryCode string   `json:"actor_country_code"`
	ActorGender      string   `json:"actor_gender"`
	ActorGenderProb  *float64 `json:"actor_gender_prob"`
	ActorTZ          string   `json:"actor_tz"`
	ActorTZOffset    *int     `json:"actor_tz_offset"`
	ActorCountry     string   `json:"actor_country"`
	ActorCompany     string   `json:"actor_company"`
}

func generateRawES(ch chan struct{}, ctx *lib.Ctx, con *sql.DB, es *lib.ES, dtf, dtt time.Time, sqls map[string]string) {
	if ctx.Debug > 0 {
		lib.Printf("Working on %v - %v\n", dtf, dtt)
	}

	// Replace dates
	sFrom := lib.ToYMDHMSDate(dtf)
	sTo := lib.ToYMDHMSDate(dtt)

	// ES bulk inserts
	bulkDel, bulkAdd := es.Bulks()

	// Commits
	sql := strings.Replace(sqls["commits"], "{{from}}", sFrom, -1)
	sql = strings.Replace(sql, "{{to}}", sTo, -1)

	// Execute query
	rows := lib.QuerySQLWithErr(con, ctx, sql)
	defer func() { lib.FatalOnError(rows.Close()) }()

	var (
		commit    esRawCommit
		createdAt time.Time
	)
	shas := make(map[string]struct{})
	commit.Type = "commit"
	nCommits := 0
	for rows.Next() {
		lib.FatalOnError(
			rows.Scan(
				&commit.SHA,
				&commit.EventID,
				&commit.AuthorName,
				&commit.Message,
				&commit.ActorLogin,
				&commit.RepoName,
				&createdAt,
				&commit.EncryptedEmail,
				&commit.AuthorEmail,
				&commit.CommitterName,
				&commit.CommitterEmail,
				&commit.AuthorLogin,
				&commit.CommitterLogin,
				&commit.Org,
				&commit.RepoGroup,
				&commit.RepoAlias,
				&commit.ActorName,
				&commit.ActorCountryCode,
				&commit.ActorGender,
				&commit.ActorGenderProb,
				&commit.ActorTZ,
				&commit.ActorTZOffset,
				&commit.ActorCountry,
				&commit.AuthorCountryCode,
				&commit.AuthorGender,
				&commit.AuthorGenderProb,
				&commit.AuthorTZ,
				&commit.AuthorTZOffset,
				&commit.AuthorCountry,
				&commit.CommitterCountryCode,
				&commit.CommitterGender,
				&commit.CommitterGenderProb,
				&commit.CommitterTZ,
				&commit.CommitterTZOffset,
				&commit.CommitterCountry,
				&commit.ActorCompany,
				&commit.AuthorCompany,
				&commit.Committer,
				&commit.Size,
			),
		)
		nCommits++
		commit.CreatedAt = lib.ToYMDHMSDate(createdAt)
		commit.Message = lib.TruncToBytes(commit.Message, 0x400)
		shas[commit.SHA] = struct{}{}
		es.AddBulksItemsI(ctx, bulkDel, bulkAdd, commit, lib.HashArray([]interface{}{commit.Type, commit.SHA, commit.EventID}))
		if nCommits%10000 == 0 {
			// Bulk insert to ES
			es.ExecuteBulks(ctx, bulkDel, bulkAdd)
		}
	}
	lib.FatalOnError(rows.Err())

	// Issues
	sql = strings.Replace(sqls["issues"], "{{from}}", sFrom, -1)
	sql = strings.Replace(sql, "{{to}}", sTo, -1)

	// Execute query
	rows = lib.QuerySQLWithErr(con, ctx, sql)
	defer func() { lib.FatalOnError(rows.Close()) }()

	var (
		issue          esRawIssue
		eventCreatedAt time.Time
		closedAt       *time.Time
		updatedAt      time.Time
	)
	iids := make(map[int64]struct{})
	issue.Type = "issue"
	nIssues := 0
	for rows.Next() {
		lib.FatalOnError(
			rows.Scan(
				&issue.ID,
				&issue.EventID,
				&eventCreatedAt,
				&createdAt,
				&issue.Body,
				&closedAt,
				&issue.Comments,
				&issue.Locked,
				&issue.Number,
				&issue.State,
				&issue.Title,
				&updatedAt,
				&issue.IsPR,
				&issue.EventType,
				&issue.RepoName,
				&issue.Org,
				&issue.RepoGroup,
				&issue.RepoAlias,
				&issue.MilestoneNumber,
				&issue.MilestoneState,
				&issue.MilestoneTitle,
				&issue.AssigneeLogin,
				&issue.AssigneeName,
				&issue.AssigneeCountryCode,
				&issue.AssigneeGender,
				&issue.AssigneeGenderProb,
				&issue.AssigneeTZ,
				&issue.AssigneeTZOffset,
				&issue.AssigneeCountry,
				&issue.ActorLogin,
				&issue.ActorName,
				&issue.ActorCountryCode,
				&issue.ActorGender,
				&issue.ActorGenderProb,
				&issue.ActorTZ,
				&issue.ActorTZOffset,
				&issue.ActorCountry,
				&issue.UserLogin,
				&issue.UserName,
				&issue.UserCountryCode,
				&issue.UserGender,
				&issue.UserGenderProb,
				&issue.UserTZ,
				&issue.UserTZOffset,
				&issue.UserCountry,
				&issue.AssigneeCompany,
				&issue.ActorCompany,
				&issue.UserCompany,
			),
		)
		nIssues++
		issue.CreatedAt = lib.ToYMDHMSDate(createdAt)
		issue.EventCreatedAt = lib.ToYMDHMSDate(eventCreatedAt)
		issue.UpdatedAt = lib.ToYMDHMSDate(updatedAt)
		issue.Body = lib.TruncToBytes(issue.Body, 0x400)
		if closedAt != nil {
			tm := lib.ToYMDHMSDate(*closedAt)
			issue.ClosedAt = &tm
		} else {
			issue.ClosedAt = nil
		}
		iids[issue.ID] = struct{}{}
		es.AddBulksItemsI(ctx, bulkDel, bulkAdd, issue, lib.HashArray([]interface{}{issue.Type, issue.ID, issue.EventID}))
		if nIssues%10000 == 0 {
			// Bulk insert to ES
			es.ExecuteBulks(ctx, bulkDel, bulkAdd)
		}
	}
	lib.FatalOnError(rows.Err())

	// PRs
	sql = strings.Replace(sqls["prs"], "{{from}}", sFrom, -1)
	sql = strings.Replace(sql, "{{to}}", sTo, -1)

	// Execute query
	rows = lib.QuerySQLWithErr(con, ctx, sql)
	defer func() { lib.FatalOnError(rows.Close()) }()

	var (
		pr       esRawPR
		mergedAt *time.Time
	)
	prids := make(map[int64]struct{})
	pr.Type = "pr"
	nPRs := 0
	for rows.Next() {
		lib.FatalOnError(
			rows.Scan(
				&pr.ID,
				&pr.EventID,
				&eventCreatedAt,
				&createdAt,
				&pr.Body,
				&closedAt,
				&pr.Comments,
				&pr.Locked,
				&pr.Number,
				&pr.State,
				&pr.Title,
				&updatedAt,
				&pr.BaseSHA,
				&pr.HeadSHA,
				&mergedAt,
				&pr.MergeCommitSHA,
				&pr.Merged,
				&pr.Mergeable,
				&pr.Rebaseable,
				&pr.MergeableState,
				&pr.ReviewComments,
				&pr.MaintainerCanModify,
				&pr.Commits,
				&pr.Additions,
				&pr.Deletions,
				&pr.ChangedFiles,
				&pr.EventType,
				&pr.RepoName,
				&pr.Org,
				&pr.RepoGroup,
				&pr.RepoAlias,
				&pr.MilestoneNumber,
				&pr.MilestoneState,
				&pr.MilestoneTitle,
				&pr.AssigneeLogin,
				&pr.AssigneeName,
				&pr.AssigneeCountryCode,
				&pr.AssigneeGender,
				&pr.AssigneeGenderProb,
				&pr.AssigneeTZ,
				&pr.AssigneeTZOffset,
				&pr.AssigneeCountry,
				&pr.ActorLogin,
				&pr.ActorName,
				&pr.ActorCountryCode,
				&pr.ActorGender,
				&pr.ActorGenderProb,
				&pr.ActorTZ,
				&pr.ActorTZOffset,
				&pr.ActorCountry,
				&pr.UserLogin,
				&pr.UserName,
				&pr.UserCountryCode,
				&pr.UserGender,
				&pr.UserGenderProb,
				&pr.UserTZ,
				&pr.UserTZOffset,
				&pr.UserCountry,
				&pr.MergedByLogin,
				&pr.MergedByName,
				&pr.MergedByCountryCode,
				&pr.MergedByGender,
				&pr.MergedByGenderProb,
				&pr.MergedByTZ,
				&pr.MergedByTZOffset,
				&pr.MergedByCountry,
				&pr.AssigneeCompany,
				&pr.ActorCompany,
				&pr.UserCompany,
				&pr.MergedByCompany,
			),
		)
		nPRs++
		pr.CreatedAt = lib.ToYMDHMSDate(createdAt)
		pr.EventCreatedAt = lib.ToYMDHMSDate(eventCreatedAt)
		pr.UpdatedAt = lib.ToYMDHMSDate(updatedAt)
		pr.Body = lib.TruncToBytes(pr.Body, 0x400)
		if closedAt != nil {
			tm := lib.ToYMDHMSDate(*closedAt)
			pr.ClosedAt = &tm
		} else {
			pr.ClosedAt = nil
		}
		if mergedAt != nil {
			tm := lib.ToYMDHMSDate(*mergedAt)
			pr.MergedAt = &tm
		} else {
			pr.MergedAt = nil
		}
		prids[pr.ID] = struct{}{}
		es.AddBulksItemsI(ctx, bulkDel, bulkAdd, pr, lib.HashArray([]interface{}{pr.Type, pr.ID, pr.EventID}))
		if nPRs%10000 == 0 {
			// Bulk insert to ES
			es.ExecuteBulks(ctx, bulkDel, bulkAdd)
		}
	}
	lib.FatalOnError(rows.Err())

	// Texts
	sql = strings.Replace(sqls["texts"], "{{from}}", sFrom, -1)
	sql = strings.Replace(sql, "{{to}}", sTo, -1)

	// Execute query
	rows = lib.QuerySQLWithErr(con, ctx, sql)
	defer func() { lib.FatalOnError(rows.Close()) }()

	var (
		text esRawText
	)
	textids := make(map[int64]struct{})
	text.Type = "text"
	nTexts := 0
	for rows.Next() {
		lib.FatalOnError(
			rows.Scan(
				&text.EventID,
				&text.Body,
				&createdAt,
				&text.EventType,
				&text.RepoName,
				&text.Org,
				&text.RepoGroup,
				&text.RepoAlias,
				&text.ActorLogin,
				&text.ActorName,
				&text.ActorCountryCode,
				&text.ActorGender,
				&text.ActorGenderProb,
				&text.ActorTZ,
				&text.ActorTZOffset,
				&text.ActorCountry,
				&text.ActorCompany,
			),
		)
		nTexts++
		text.CreatedAt = lib.ToYMDHMSDate(createdAt)
		text.Body = lib.TruncToBytes(text.Body, 0x1000)
		textids[text.EventID] = struct{}{}
		es.AddBulksItemsI(ctx, bulkDel, bulkAdd, text, lib.HashArray([]interface{}{text.Type, text.EventID, text.Body}))
		if nTexts%10000 == 0 {
			// Bulk insert to ES
			es.ExecuteBulks(ctx, bulkDel, bulkAdd)
		}
	}
	lib.FatalOnError(rows.Err())

	// Bulk insert to ES
	es.ExecuteBulks(ctx, bulkDel, bulkAdd)

	if ctx.Debug > 0 {
		lib.Printf(
			"%v - %v: %d commits (%d unique SHAs), %d issue events (%d unique issues), "+
				"%d PR events (%d unique PRs), %d texts (%d unique)\n",
			sFrom, sTo, nCommits, len(shas), nIssues, len(iids),
			nPRs, len(prids), nTexts, len(textids),
		)
	}

	// Synchronize go routine
	if ch != nil {
		ch <- struct{}{}
	}
}

// gha2es - main working function
func gha2es(args []string) {
	var (
		ctx      lib.Ctx
		err      error
		hourFrom int
		hourTo   int
		dFrom    time.Time
		dTo      time.Time
	)

	// Environment context parse
	ctx.Init()
	if !ctx.UseESRaw {
		return
	}
	// Connect to ElasticSearch
	es := lib.ESConn(&ctx, "d_raw_")
	// Create index
	exists := es.IndexExists(&ctx)
	if !exists {
		es.CreateIndex(&ctx, true)
	}

	// Connect to Postgres DB
	con := lib.PgConn(&ctx)
	defer func() { lib.FatalOnError(con.Close()) }()

	// Get raw commits to ES SQL
	sqls := make(map[string]string)
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}
	data := [][2]string{
		{"commits", "util_sql/es_raw_commits.sql"},
		{"issues", "util_sql/es_raw_issues.sql"},
		{"prs", "util_sql/es_raw_prs.sql"},
		{"texts", "util_sql/es_raw_texts.sql"},
	}
	for _, row := range data {
		bytes, err := lib.ReadFile(
			&ctx,
			dataPrefix+row[1],
		)
		lib.FatalOnError(err)
		sqls[row[0]] = string(bytes)
	}

	// Current date
	now := time.Now()
	startD, startH, endD, endH := args[0], args[1], args[2], args[3]

	// Parse from day & hour
	if strings.ToLower(startH) == lib.Now {
		hourFrom = now.Hour()
	} else {
		hourFrom, err = strconv.Atoi(startH)
		lib.FatalOnError(err)
	}

	if strings.ToLower(startD) == lib.Today {
		dFrom = lib.DayStart(now).Add(time.Duration(hourFrom) * time.Hour)
	} else {
		dFrom, err = time.Parse(
			time.RFC3339,
			fmt.Sprintf("%sT%02d:00:00+00:00", startD, hourFrom),
		)
		lib.FatalOnError(err)
	}

	// Parse to day & hour
	if strings.ToLower(endH) == lib.Now {
		hourTo = now.Hour()
	} else {
		hourTo, err = strconv.Atoi(endH)
		lib.FatalOnError(err)
	}

	if strings.ToLower(endD) == lib.Today {
		dTo = lib.DayStart(now).Add(time.Duration(hourTo) * time.Hour)
	} else {
		dTo, err = time.Parse(
			time.RFC3339,
			fmt.Sprintf("%sT%02d:00:00+00:00", endD, hourTo),
		)
		lib.FatalOnError(err)
	}

	// Get number of CPUs available and optimal time window for threads
	thrN := lib.GetThreadsNum(&ctx)
	hours := int(dTo.Sub(dFrom).Hours()) / thrN
	if hours < 1 {
		hours = 1
	}
	if hours > 480 {
		hours = 480
	}
	lib.Printf("gha2es.go: Running (%v CPUs): %v - %v, interval %dh\n", thrN, dFrom, dTo, hours)

	dt := dFrom
	dtN := dt
	if thrN > 1 {
		ch := make(chan struct{})
		nThreads := 0
		for dt.Before(dTo) || dt.Equal(dTo) {
			dtN = dt.Add(time.Hour * time.Duration(hours))
			go generateRawES(ch, &ctx, con, es, dt, dtN, sqls)
			dt = dtN
			nThreads++
			if nThreads == thrN {
				<-ch
				nThreads--
			}
		}
		lib.Printf("Final threads join\n")
		for nThreads > 0 {
			<-ch
			nThreads--
		}
	} else {
		lib.Printf("Using single threaded version\n")
		for dt.Before(dTo) || dt.Equal(dTo) {
			dtN = dt.Add(time.Hour * time.Duration(hours))
			generateRawES(nil, &ctx, con, es, dt, dtN, sqls)
			dt = dtN
		}
	}
	// Finished
	lib.Printf("All done.\n")
}

func main() {
	dtStart := time.Now()
	// Required args
	if len(os.Args) < 4 {
		lib.Printf("Arguments required: date_from_YYYY-MM-DD hour_from_HH date_to_YYYY-MM-DD hour_to_HH\n")
		os.Exit(1)
	}
	gha2es(os.Args[1:])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
