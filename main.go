package main

import (
	"fmt"
	//	"github.com/nlopes/slack"
	"encoding/json"
	"net/http"
	"os"

	"github.com/codegangsta/cli"
	"github.com/yamamoto-febc/slack-echo-bot/version"
)

const (
	defaultPort     = 8000
	defaultEndpoint = "/"
	defaultBotName  = "slack-echo-bot"
	defaultBotEmoji = ":information_source:"
)

var appHelpTemplate = `This is a Echo robot for slack.

Version: {{.Version}}{{if or .Author .Email}}

Author:{{if .Author}}
  {{.Author}}{{if .Email}} - <{{.Email}}>{{end}}{{else}}
  {{.Email}}{{end}}{{end}}
{{if .Flags}}
Options:
  {{range .Flags}}{{.}}
  {{end}}{{end}}
Commands:
  {{range .Commands}}{{.Name}}{{with .ShortName}}, {{.}}{{end}}{{ "\t" }}{{.Usage}}
  {{end}}
`

var flags = []cli.Flag{
	cli.IntFlag{
		Name:   "port, p",
		Value:  defaultPort,
		Usage:  "port for the listening incoming webhook",
		EnvVar: "SLACK_BOT_PORT",
	},
	cli.StringFlag{
		Name:   "endpoint, e",
		Value:  defaultEndpoint,
		Usage:  "path for the listening incoming webhook",
		EnvVar: "SLACK_BOT_PATH",
	},
	cli.StringFlag{
		Name:   "echoback-url, b",
		Value:  "",
		Usage:  "url for the echoback(outgoing) webhook ",
		EnvVar: "SLACK_ECHOBACK_URL",
	},
	cli.StringFlag{
		Name:   "token, t",
		Usage:  "token of slack bot",
		EnvVar: "SLACK_BOT_TOKEN",
	},
	cli.StringFlag{
		Name:   "name, n",
		Usage:  "name of slack bot",
		Value:  defaultBotName,
		EnvVar: "SLACK_BOT_NAME",
	},
	cli.StringFlag{
		Name:   "emoji, m",
		Usage:  "emoji of slack bot",
		Value:  defaultBotEmoji,
		EnvVar: "SLACK_BOT_EMOJI",
	},
}

func main() {
	cli.AppHelpTemplate = appHelpTemplate
	app := cli.NewApp()
	app.Name = "slack-echo-bot"
	app.Usage = "This is a Echo robot for slack."
	app.Author = "Kazumichi Yamamoto(yamamoto.febc@gmail.com)"
	app.Email = "https://github.com/yamamoto-febc/slack-echo-bot/"
	app.Version = version.Version
	app.CommandNotFound = cmdNotFound
	app.Action = func(c *cli.Context) {
		//TODO

		port := c.Int("port")
		endpoint := c.String("endpoint")
		// token := c.String("token")
		name := c.String("name")
		emoji := c.String("emoji")

		http.HandleFunc(endpoint, func(w http.ResponseWriter, r *http.Request) {
			text := r.FormValue("text")
			res, _ := json.Marshal(&map[string]string{
				"text":       fmt.Sprintf("response: %s", text),
				"username":   name,
				"icon_emoji": emoji,
			})
			w.Write(res)
		})
		http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
	}
	app.Flags = flags
	app.Run(os.Args)
}

func cmdNotFound(c *cli.Context, command string) {
	fmt.Printf(
		"%s: '%s' is not a %s command. See '%s --help'.",
		c.App.Name,
		command,
		c.App.Name,
		os.Args[0],
	)
	os.Exit(1)
}
