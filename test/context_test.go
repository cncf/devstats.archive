package gha2db

import (
	"os"
	"testing"
	"time"

	lib "k8s.io/test-infra/gha2db"
)

func TestInit(t *testing.T) {
	var testCases = []struct {
		name            string
		environment     map[string]string
		expectedContext lib.Ctx
	}{
		{
			"Default values",
			map[string]string{},
			lib.Ctx{
				Debug:            0,
				CmdDebug:         0,
				JSONOut:          false,
				DBOut:            true,
				ST:               false,
				NCPUs:            0,
				PgHost:           "localhost",
				PgPort:           "5432",
				PgDB:             "gha",
				PgUser:           "gha_admin",
				PgPass:           "password",
				Index:            false,
				Table:            true,
				Tools:            true,
				Mgetc:            "",
				IDBHost:          "http://localhost",
				IDBPort:          "8086",
				IDBDB:            "gha",
				IDBUser:          "gha_admin",
				IDBPass:          "password",
				QOut:             false,
				CtxOut:           false,
				DefaultStartDate: time.Date(2015, 8, 6, 22, 0, 0, 0, time.UTC),
				LastSeries:       "all_prs_merged_d",
				SkipIDB:          false,
				ResetIDB:         false,
			},
		},
	}
	for index, test := range testCases {
		var (
			currEnv    map[string]string
			gotContext lib.Ctx
		)

		// Set new environment
		for key, value := range test.environment {
			currEnv[key] = os.Getenv(key)
			err := os.Setenv(key, value)
			if err != nil {
				t.Errorf(err.Error())
			}
		}

		// Initialize context while new environment is set
		gotContext.Init()

		// Restore original environment
		for key := range test.environment {
			err := os.Setenv(key, currEnv[key])
			if err != nil {
				t.Errorf(err.Error())
			}
		}

		// Check if we got expected context
		if gotContext != test.expectedContext {
			t.Errorf(
				"Test case number %d \"%s\"\nExpected:\n%+v\nGot:\n%+v\n",
				index+1, test.name, test.expectedContext, gotContext,
			)
		}
	}
}
