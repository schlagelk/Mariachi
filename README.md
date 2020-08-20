# Mariachi <img src="mariachi.png" alt="drawing" width="80" />


## Set Up
You only need to be able to do the following 2 things to add Mariachi and start receiving PR reminders in Teams
- Add a `mariachi.yml` file to your repository.
- Create an Incoming Webhook Connector in MSFT Teams (see next paragraph).
- (optional) Add secrets to your GitHub repository. Although you can add your Teams webhook URL to your `mariachi.yml` file in plain text, we recommend storing it in your GitHub secrets store so that it is never committed to your history.

### Create an Incoming Webhook Connector MSFT Teams
Follow the steps [here](https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook#add-an-incoming-webhook-to-a-teams-channel) to create a connector in your Teams channel.  Copy the URL, and add it to your GitHub repository's [secret store](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets#creating-encrypted-secrets-for-a-repository).  If you are following the example below, give it the name `TEAMS_TOKEN` in your secrets store.

### Add a `mariachi.yml` file to your project.
You can set Mariachi to run on a schedule like below, or on any event your heart desires.  Just add a `mariachi.yml` config file to your `.github/workflows` directory. See [here](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#scheduled-events) for how to configure this on a schedule.

```yml
name: Mariachi
on:
  schedule:
    - cron: "0 0 * * *"
jobs:
  remind:
    runs-on: ubuntu-latest
    steps:
    - name: Mariachi
      uses: docker://schlagelk/mariachi:latest
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        teams_url: ${{ secrets.TEAMS_TOKEN }}
        exclude_heads: release,foo,bar
        exclude_labels: skip-mariachi,do not review
        min_reviews: 3
```

### Parameters
The example file above includes 5 parameters (after `with:`) - some of them are required and some are optional.

***github_token (required)***

The GitHub token to use - GitHub creates one by default for you and you can use that `${{ secrets.GITHUB_TOKEN }}`.

***teams_url (required)***

The Teams webhook URL.  If you followed the instructions above and added it to your secrets store, you can use `${{ secrets.TEAMS_TOKEN }}`.

***exclude_heads (optional)***

You can configure Mariachi to exclude PRs with head branches that begin with certain words.  Add them as a comma separated single string without spaces (eg: `release,test`).

***exclude_labels (optional)***

You can configure Mariachi to exclude PRs with certain labels. Add them as a comma separated single string without spaces in between (eg `skip-mariachi,do not review`).

***min_reviews (optional)***

The minimum number of reviews needed to have Mariachi notify Teams (default is 2).  A review is either an approval or a request for changes, but not a comment.


#### What Does a Reminder Look Like? ####
<img src="mariachiinteams.png" alt="drawing"  />
