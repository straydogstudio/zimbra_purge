Zimbra Purge &mdash; Schedule Zimbra email purges
===================================================

Previous to Zimbra 8 you could not specify individual folder retention policies. This script addresses that shortcoming by purging emails according to your specifications. It relies upon the [Zimbra query language](http://www.zimbra.com/desktop/help/en_US/Search/query_language_description.htm).

I have not tried this on Zimbra 8. When I get there I will update this description with my findings unless someone else wishes to offer their experience with the new folder retention policy.

##Requirements

* Tested with Zimbra 7
* Ruby (currently tested on 1.9.3)
* [TExp](https://github.com/jimweirich/texp) - for scheduling. If you wish to run queries on every run, you can comment out this requirement.

##Installation

Install ruby, the TExp gem, place the script where you please, and enter it in your crontab.

Install the TExp gem as follows:
```ruby
gem install texp
```
or
```ruby
sudo gem install texp
```

##Note

In Zimbra 8, you can now configure per folder/tag retention policies both individually and as an administrator. I post this script here in case someone is stuck at 7 and needs the ability to purge individual folders.

##Usage

- Adjust the following variables:
	- queries: specify accounts and the search query. See examples below.
	- domains: list domains to retrieve emails from (for searching :all mailboxes)
	- from_email: email address to send from
	- admin_emails: email addresses to send to
	- smtp_server: email server
	- exclude_emails: email addresses (or regular expressions) used to exclude emails from :all

- Schedule in the zimbra account crontab

##Settings

There are three parts to each query:

- *:account* - This can either be an email address, a domain from the domains variable (the query will be applied to all accounts in the domain), or they symbol :all.
- *:query* - This can be any search string used in the Zimbra query box. See examples below or view the [Zimbra query language description](http://www.zimbra.com/desktop/help/en_US/Search/query_language_description.htm).
- *:schedule* - Specify when this query should run using the [TExp temporal expression](https://github.com/jimweirich/texp) syntax.

##:examples

```ruby
   { :account => 'user@domain.com', :query => 'in:"Folder/Name" before:-60day' },
   { :account => 'domain.com', :query => 'in:Inbox from:viagra', :schedule => TExp::DayOfWeek.new(Date::DAYNAMES.index("Monday")) },
   { :account => :all, :query => 'in:Inbox attachment:any before:-12month', :schedule => TExp::DayOfWeek.new(Date::DAYNAMES.index("Monday")) },
```

##Limitations

This script uses the zmmailboxsearch command line tool. At least in Zimbra 7 it returns at most 500 messages. Theoretically this should be changeable using zimbraGalMaxResults, but I've not had success so far. If you want to purge more than 500 emails per day from a single query, this script will not suffice. At some point I may change the script to permit this.

##Dependencies

- [TExp temporal expression](https://github.com/jimweirich/texp)

##Authors

* [Noel Peden](https://github.com/straydogstudio)

##Change log

- **September 26, 2012**: 0.0.1 release
	- Initial posting.
