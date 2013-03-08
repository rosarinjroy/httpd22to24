#!/bin/env perl
# Copyright (c) 2013, Roy (rosarinjroy at hotmail dot com)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# This utility script will scan the httpd 2.2.x configuration file and provide suggestions on what directives need to be modified.
# The information contained in this file is taken from this URL:  http://httpd.apache.org/docs/2.4/upgrading.html
#

use strict;
use warnings;

sub print_message {
    my $line_printed = shift;
    my $line_number = shift;
    my $line = shift;
    my $message = shift;
    unless($line_printed) {
        print "-----------------\n";
        printf "Line %4d: %s\n", $line_number, $line;
    }
    print "      $message\n";

    return 1;
}

sub process_line {
    my $line_number = shift;
    my $line = shift;
    my $line_printed = 0;

    # Skip comments and empty lines.
    return if ($line =~ /^\s*$/);
    return if ($line =~ /^\s*\#/);

    # Check for obsolete directives.
    if ($line =~ /^\s*(AuthzLDAPAuthoritative|AuthzDBDAuthoritative|AuthzDBMAuthoritative|AuthzGroupFileAuthoritative|AuthzUserAuthoritative|AuthzOwnerAuthoritative)\b/) {
        $line_printed = print_message ($line_printed, $line_number, $line, "Don't use $1. Perform authorization the new way. Refer: http://httpd.apache.org/docs/2.4/howto/auth.html");
    }
    if ($line =~ /^\s*(Order|Allow|Deny|Satisfy)\b/) {
        $line_printed = print_message ($line_printed, $line_number, $line, "Don't use $1. Use Require instead. Refer: http://httpd.apache.org/docs/2.4/mod/mod_authz_core.html#require");
    }
    if ($line =~ /^\s*(MaxRequestsPerChild)\b/) {
        $line_printed = print_message ($line_printed, $line_number, $line, "Rename MaxRequestsPerChild to MaxConnectionsPerChild. Refer: http://httpd.apache.org/docs/2.4/mod/mpm_common.html#maxconnectionsperchild");
    }
    if ($line =~ /^\s*(MaxClients)\b/) {
        $line_printed = print_message ($line_printed, $line_number, $line, "Rename MaxClients to MaxRequestWorkers. Refer: http://httpd.apache.org/docs/2.4/mod/mpm_common.html#maxrequestworkers");
    }
    if ($line =~ /^\s*(DefaultType)\b/) {
        $line_printed = print_message ($line_printed, $line_number, $line, "DefaultType doesn't have any effect. Remove this line.");
    }
    if ($line =~ /^\s*(DavLockDB)\b/) {
        $line_printed = print_message ($line_printed, $line_number, $line, "DavLockDB semantics have been changed. Refer: http://httpd.apache.org/docs/2.4/mod/mod_dav_fs.html#davlockdb");
    }
    if ($line =~ /^\s*(KeepAlive)\b/) {
        if($line !~ /KeepAlive\s+(On|Off)/) {
            $line_printed = print_message ($line_printed, $line_number, $line, "KeepAlive accepts only 'On' or 'Off' as arguments.");
        }
    }
    if ($line =~ /^\s*(AcceptMutex|LockFile|RewriteLock|SSLMutex|SSLStaplingMutex|WatchdogMutexPath)\b/) {
        $line_printed = print_message ($line_printed, $line_number, $line, "$1 has been replaced with Mutex directive. Refer to documentation for correct usage. Refer: http://httpd.apache.org/docs/2.4/mod/core.html#mutex");
    }
    if ($line =~ /^\s*(NameVirtualHost)\b/) {
        $line_printed = print_message ($line_printed, $line_number, $line, "NameVirtualHost directive has been removed. Remove this line.");
    }
    if ($line =~ /^\s*(SSLProtocol)\b/) {
        if ($line =~ /\b(SSLv2)\b/) {
            $line_printed = print_message ($line_printed, $line_number, $line, "SSLv2 support has been removed. Please remove SSLv2 from the list of protocols. Refer: http://httpd.apache.org/docs/2.4/mod/mod_ssl.html#sslprotocol");
        }
    }
}

sub process_file {
    my $file_name = shift;
    print "Processing file [$file_name] ...\n";

    open INFILE, $file_name or die "Unable to open file [$file_name]: $!";

    my $line_num = 0;
    while (my $line = <INFILE>) {
        $line_num++;
        chomp $line;
        process_line($line_num, $line);
    }
    close INFILE;

    print "=========================================\n\n";
}

if ( length(@ARGV) <= 0) {
    print STDERR "Expected at least one file name to process. Aborting.\n";
    exit 1;
}

for my $file_name (@ARGV) {
    process_file($file_name);
}
