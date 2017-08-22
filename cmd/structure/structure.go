package main

import (
	"fmt"
	lib "k8s.io/test-infra/gha2db"
	"os"
)

func structure() {
	// Environment controlling index creation, table & tools
	index := os.Getenv("GHA2DB_INDEX") != ""
	table := os.Getenv("GHA2DB_SKIPTABLE") == ""
	tools := os.Getenv("GHA2DB_SKIPTOOLS") == ""
	fmt.Printf("%v %v %v\n", index, table, tools)

	// Connect to Postgres DB
	c, err := lib.Conn()
	lib.FatalOnError(err)

	// gha_events
	// {"id:String"=>48592, "type:String"=>48592, "actor:Hash"=>48592, "repo:Hash"=>48592,
	// "payload:Hash"=>48592, "public:TrueClass"=>48592, "created_at:String"=>48592, "org:Hash"=>19451}
	// {"id"=>10, "type"=>29, "actor"=>278, "repo"=>290, "payload"=>216017, "public"=>4,
	// "created_at"=>20, "org"=>230}
	// const
	if table {
		_, err := lib.ExecSQL(c, "drop table if exists gha_events")
		lib.FatalOnError(err)
		_, err = lib.ExecSQL(
			c,
			lib.CreateTable(
				"gha_events("+
					"id bigint not null primary key, "+
					"type varchar(40) not null, "+
					"actor_id bigint not null, "+
					"repo_id bigint not null, "+
					"public boolean not null, "+
					"created_at {{ts}} not null, "+
					"org_id bigint, "+
					"actor_login varchar(120) not null, "+
					"repo_name varchar(160) not null"+
					")",
			),
		)
		lib.FatalOnError(err)
	}
}

func main() {
	structure()
}
