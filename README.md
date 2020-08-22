# <img src="mariachi.png" alt="mariachi image" width="80" /> Mariachi 


## What is Mariachi?
Mariachi sends Pull Request review reminders to MSFT Teams channels.  You can configure it to run for Pull Requests in your GitHub repo with a single `mariachi.yml` file, or set it up to run on your servers when you want.  Set the minimum required reviews for each PR, PR labels you wish to ignore and add head branch prefixes to exclude.

### Requirements
You only need to be able to do the following 2 things to add Mariachi and start receiving review reminders in Teams:
1. Create an Incoming Webhook Connector in MSFT Teams (see [Creating an Incoming Webhook Connector MSFT Teams](https://github.com/schlagelk/Mariachi#creating-an-incoming-webhook-connector-msft-teams)).
2. Configure the Mariachi exectuable to run when you want (see [Configuring Mariachi](https://github.com/schlagelk/Mariachi#configuring-mariachi) for examples).

### Creating an Incoming Webhook Connector MSFT Teams
Follow the steps [here](https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook#add-an-incoming-webhook-to-a-teams-channel) to create a connector in the Teams channel where you wish to receive reminders.  Copy the URL at the last step, as we you will need it when configuring Mariachi next.

### Configuring Mariachi ###
Mariachi needs to only be configured with a few parameters in order to start singing.  You can set Mariachi to run on a schedule or on any event your heart desires - below are a few examples.

#### Using GitHub Actions (Recommended) ####
Just add a `mariachi.yml` config file to your `.github/workflows` directory like below.  This will pull our latest Docker image and run once per day - see [here](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#scheduled-events) for how to configure this on a schedule.

```yml
name: Mariachi
on:
  schedule:
  - cron: "0 15 * * *" # time in GMT
jobs:
  look_for_prs_needing_reviews:
    runs-on: ubuntu-latest
    steps:
    - name: Mariachi
      uses: docker://schlagelk/mariachi:latest
      with:
      github_token: ${{ secrets.GITHUB_TOKEN }} # this is the default token created by GitHub. you can also use a personal access token with repo scope enabled
        teams_url: ${{ secrets.TEAMS_TOKEN }} # your Teams channel's webhook URL
        exclude_heads: release,foo,bar # optional
        exclude_labels: skip-reminder,do not review # optional 
        min_reviews: 3 # optional
```

#### CircleCI Example ####
You need to do 2 things to set up Mariachi as a CircleCI workflow:
1. Add 2 environment variables to your project:
    1. `INPUT_GITHUB_TOKEN` - the GitHub Access token to use
    2. `INPUT_TEAMS_URL` - the webhook URL for your Teams channel
2. Create a job in your project's config file and run it on a schedule.  See [this link](https://circleci.com/docs/2.0/workflows/#scheduling-a-workflow) for how to set up a workflow to run on a schedule.  Here's an example job definition which pulls our Docker file and runs with a few parameters:

```yml
pr_review_reminders:
  docker:
    - image: schlagelk/mariachi:latest
  environment:
    GITHUB_REPOSITORY: your-org/your-repo
    INPUT_EXCLUDE_LABELS: skip-reminder, do-not-review
  steps:
    - run:
        name: Notify Teams if PRs Need Reviews
        command: |
          cd /src && ./entrypoint.sh
```


### Input Parameters ###
Checkout the entrypoint.sh file in the root of this repo to see an example of how to call Mariachi - it takes 3 required inputs and 3 optional inputs.  If using a GitHub Action approach, some of these variables are set for you automatically.

***1.  Your GitHub Token (required)***
The GitHub token to use - if using our Docker approach, this needs to be set to a variable named `INPUT_GITHUB_TOKEN` (GitHub Actions will set this for you by default).

***2. Your MSFT Teams Webhook URL (required)***
The URL you created for your MSFT Teams channel's webhook - if using our Docker approach, this needs to be set to a variable named `INPUT_TEAMS_URL`.

***3. The GitHub Repo to Scan (required)***
The GitHub repo to scan for PRs matching your configured criteria - if using our Docker approach, this needs to be set to a variable named `GITHUB_REPOSITORY` (GitHub Actions will also set this for you by default).

***4. Head Prefixes to Ignore (optional)***
You can configure Mariachi to exclude PRs with head branches that begin with certain words.  Add them as a comma separated string without spaces between each prefix (eg: `release,test`).

***5. PR Labels to Ignore (optional)***
You can also configure Mariachi to exclude PRs with certain labels. Add them as a comma separated string without spaces in between each label (eg `skip-mariachi,do not review`).

***6. Minimum Reviews Required (optional)***
The minimum number of reviews needed to have Mariachi notify Teams (default is 2).  A review is either an approval or a request for changes, but not a comment review.


### FAQs ###
#### What Permissions Does Mariachi Need? ####
Mariachi does not require anything but read access, however there are certain limitations to GitHub's access tokens as modifying their access levels is limited.  If using a GitHub Action approach, the default token created by GitHub comes with the following permissions which are limited to your repo only - [see here for more](https://docs.github.com/en/actions/configuring-and-managing-workflows/authenticating-with-the-github_token#permissions-for-the-github_token).  If you are using a personal access token instead, you'll need to check the entire repo scope.

#### What Counts as a Review? ####
Mariachi considers a review to be either an approval or a request for changes.

#### What Does a Reminder Look Like? ####
<img src="mariachiinteams.png" alt="drawing"  />

#### Can I Fork Mariachi for My Enterprise Needs? ####
Yes - Mariachi is published under the Apache 2.0 license.  For more information, please view the [LICENSE.txt](https://github.com/schlagelk/Mariachi/blob/master/LICENSE.txt) file.


### Building and Developing Mariachi ###
Mariachi is built with Apple's Swift language, [Swift Argument Parser](https://github.com/apple/swift-argument-parser) and Swift Package Manager.  You can clone the repo and open `Package.swift` to launch the project in Xcode.  If you wish to build and run the Mariachi executbale, you can run `swift build -c release` from the project root - this gives you an exectuable located at `.build/release/mariachi` ready for release.

The project also comes with some very basic unit tests - you can run those from the project root using `swift test` or using Xcode's interface.

The suggested way of deploying the Mariachi executable is to use Docker.  This project contains a Dockerfile as well as an entrypoint script (entrypoint.sh) used by the Docker container.  This script just checks if certain variables are set before executing the Mariachi exectuable on the server where configured.
