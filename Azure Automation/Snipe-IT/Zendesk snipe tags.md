This script will compares Zendesk users to Snipe users via shared employee ids from HR. Once it finds a match it will add a tag to the user in zendesk with the corrisponding asset tag. If there are leftover device tags that do not appear in Snipe they will be removed

## Workflow

* Get all devices from snipe
* Get all users from Zendesk
* Match users via employee ID
* Find all non asset Zendesk tags and add them to a New Tag list
* Compare current asset tags with current Zendesk tags and add them to new tag list
* Update zendesk via API with new tags

## Dependancies 
* Azure automation
* Zendesk API
* Snipe IT Api

## Updating

The only thing you should ever need to do is update the variables in Azure Automation with current API keys 
