#!/usr/bin/perl
#
use Net::SMTP;


my $MailFrom = "cmu\@opse1.somehost.com";
my $MailTo = "rajendra.prashad\@somecompany.com";
my $subject = "SMTP Test";
my $MailBody = "This is the mail body";

$smtp = Net::SMTP->new('smtp.somehost.com', Debug => 1, Port => 25);

# Send the From and Recipient for the mail servers that require it
$smtp->mail($MailFrom);
$smtp->to($MailTo);

# Start the mail
$smtp->data();

# Send the header.
$smtp->datasend("To: $MailTo\n");
$smtp->datasend("From: $MailFrom\n");
$smtp->datasend("Subject: $subject\n");
$smtp->datasend("\n");

# Send the message
$smtp->datasend("$MailBody\n\n");

# Send the termination string
$smtp->dataend();
$smtp->quit;
