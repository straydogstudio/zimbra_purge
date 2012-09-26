#!/usr/bin/env ruby

require 'rubygems'
require 'date'
require 'time'
require 'net/smtp'
require 'texp'

#Variables to change
queries = [
   { :account => 'user@domain.com', :query => 'in:"Folder/Name" before:-60day' },
   { :account => 'domain.com', :query => 'in:Inbox from:viagra', :schedule => TExp::DayOfWeek.new(Date::DAYNAMES.index("Monday")) },
   { :account => :all, :query => 'in:Inbox attachment:any before:-12month', :schedule => TExp::DayOfWeek.new(Date::DAYNAMES.index("Monday")) },
]
domains = ['domain.com', 'domain2.com']
from_email   = 'admin@domain.com'
admin_emails = ['admin1@domain.com','admin2@domain2.com']
smtp_server = 'your.smtp.server.com'
exclude_emails = ['^ham','^spam','^virus','^wiki']

#No changes required after this point

puts "Retrieving emails"
all_emails = {}
exclude_pattern = /#{exclude_emails.join('|')}/
domains.each do |domain|
   all_emails[domain] = []
   puts "Getting emails for #{domain}"
   $stdout.flush
   IO.popen("zmprov -l gaa -v -e #{domain} | grep '# name'") { |f|
      until f.eof?
         line = f.gets.strip
         if line =~ /^# name/
            email = line.gsub(/^# name\s+/,'')
            next if exclude_emails.length > 0 && email =~ exclude_pattern
            all_emails[domain] << email
         end
      end
   }
end

puts "Purging folders on #{Date.today}\n"

emails = {}
success = []
skipped = []
today = Date.today()
queries.each do |setting|
   query = setting[:query]
   puts "\n#####################################"
   puts " Purge: #{setting[:account]} q:#{query}"
   if setting[:schedule]
      print " Sched: #{setting[:schedule]}"
      unless setting[:schedule].include?(today)
         puts " - Not today\n\n"
         skipped << "#{setting[:account]} q:#{setting[:query]}"
         next
      end
      puts " - Today!"
   end

   if setting[:account] == :all
      accounts = all_emails.keys.map {|dom| all_emails[dom]}.flatten
   elsif domains.include?(setting[:account])
      accounts = all_emails[setting[:account]]
   else
      accounts = [ setting[:account] ]
   end
   accounts.each do |account|
      puts "Search: #{account} q:#{query}" if accounts.length > 1
      output = `/opt/zimbra/bin/zmmboxsearch -q '#{query}' -m '#{account}' -l 500`
      messages = output =~ /No results found/i ? [] : output.split(/\n/)

      puts " Count: #{messages.length.to_s} messages found"

      if messages.length > 0
         messages.each do |m|
            id = m.gsub(/^.*\sid="([^"]+)"\s.*/, '\1')
            sending_account = m.gsub(/^.*\sa="([^"]+)".*/, '\1')
            if account == "*" # only works for sent emails
               emails[sending_account] ||= []
               emails[sending_account] << id
            else
               emails[account] ||= []
               emails[account] << id
            end
         end
      end
   end
   success << "#{setting[:account]} q:#{query}"
end

purges = []
puts "\nDeleting emails:"
emails.sort.each do |account, ids|
   purges << "#{account} #{ids.length}"
   puts "\t\t#{account} #{ids.length} ... "
   $stdout.flush
   ids.each_slice(1000) do |ids_slice|
      puts `/opt/zimbra/bin/zmmailbox -z -m "#{account}" dm #{ids_slice.join(',')}`
   end
   puts "Done"
end

hostname = `hostname`.chomp
email_message = <<MESSAGE_END
From: #{hostname} Server <#{from_email}>
To: #{admin_emails.first}
Subject: AUTO: Mail Purge on #{hostname} Zimbra


Successful purges:
* #{success.join("\n* ")}

Skipped purges:
* #{skipped.join("\n* ")}

Purge counts:
* #{purges.join("\n* ")}
MESSAGE_END

Net::SMTP.start(smtp_server) do |smtp|
   smtp.send_message email_message, from_email, admin_emails
end

