#!/usr/bin/perl -w

=head1 NAME

db_uninst_mysql.pl - installation script to uninstall the MySQL database

=head1 DESCRIPTION

This script is called during C<make uninstall> to uninstall the 
MySQL Bricolage database.

=head1 AUTHOR

Sam Tregar <stregar@about-inc.com>

Scott Lanning <slanning@theworld.com>

=head1 SEE ALSO

L<Bric::Admin>

=cut

use strict;
use FindBin;
use lib "$FindBin::Bin/lib";
use File::Spec::Functions qw(:ALL);
use File::Find qw(find);
use DBI;

print "\n\n==> Deleting Bricolage MySQL Database <==\n\n";

our $DB;
do "./database.db" or die "Failed to read database.db : $!";
my $perl = $ENV{PERL} || $^X;

# Tell STDERR to ignore MySQL NOTICE messages by forking another Perl to
# filter them out. This *must* happen before setting $> below, or Perl will
# complain.
open STDERR, "| $perl -ne 'print unless /^NOTICE:  /'"
  or die "Cannot pipe STDERR: $!\n";


# setup database and user while connected to dummy template1
my $dbh = db_connect();
drop_db($dbh);
drop_user($dbh);
$dbh->disconnect();

print "\n\n==> Finished Deleting Bricolage PostgreSQL Database <==\n\n";

# connect to a database
sub db_connect {
    my $dsn = "dbi:mysql:database=$DB->{db_name}";
    $dsn .= ";host:$DB->{host_name}" if ( $DB->{host_name} ne "localhost" and $DB->{host_name} ne "");
    $dsn .= ";port:$DB->{host_port}" if ( $DB->{host_port} ne "" );    
    my $dbh = DBI->connect($dsn,$DB->{root_user}, $DB->{root_pass});
    hard_fail("Unable to connect to MySQL using supplied root username ",
              "and password: ", DBI->errstr, "\n")
        unless $dbh;
    $dbh->{PrintError} = 0;
    return $dbh;
}

# create the database, optionally dropping an existing database
sub drop_db {
    my $dbh = shift;

    if (ask_yesno("Drop database \"$DB->{db_name}\"?", 0)) {
        unless ($dbh->do("DROP DATABASE $DB->{db_name}")) {
            hard_fail("Failed to drop database.  The error from MySQL was:\n\n",
                      $dbh->errstr, "\n");
        }
        print "Database dropped.\n";
    }
}

# create SYS_USER, optionally dropping an existing syst
sub drop_user {
    my $dbh = shift;

    if (ask_yesno("Drop user \"$DB->{sys_user}\"?", 0)) {
        unless ($dbh->do("DROP USER $DB->{sys_user}")) {
            hard_fail("Failed to drop user.  The error from MySQL was:\n\n",
                      $dbh->errstr, "\n");
        }
        print "User dropped.\n";
    }
}