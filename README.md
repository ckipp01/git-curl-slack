# Curl git status information to Slack channels

This is  quick script I put together to live in main directories with a lot of git repositories. I wanted something that a cron job could just run daily or something that 
I could just drop in a directory with a lot of projects and get a message shot to me or my team with an alert of
repositories that may have various changes uncommitted or that may be ahead of origin.

This will gather up the following information on the repository:
1. Number of modified files
2. Number of deleted files
3. If there are untracked files
4. Whether the checked out branch is ahead of origin or not.

It will then shoot a curl message in json format to a webook that you'll need to set up in slack with the results.

#### Parameters
You have 2 options for parameters. If you pass in test, you'll need to be in the directory when you run it, or you can run it
and pass the directory in that you'd like it to cd into and run the script.

#### Setting up the webook
Folliwng the instruction [here in the slack docs](https://api.slack.com/incoming-webhooks) to set up your incoming webhook.
