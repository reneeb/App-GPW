#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;


use FindBin;
use lib "$FindBin::Bin/lib";

use Mojo::File qw(path tempdir);

require App::GPW::Command::add;

my $plugin = App::GPW::Command::add;

ok $plugin->description, 'has a description';
like $plugin->usage, qr/plugin/, 'has usage information';

$plugin->run('2019');

my $cwd = path;
my $dir = tempdir CLEANUP => 1;
chdir $dir;

my $buffer = '';
{
  open my $handle, '>', \$buffer;
  local *STDOUT = $handle;
  $plugin->run( 'test_plugin' );
}

like $buffer, qr/TestPlugin\.pm/, 'right output';
ok -e $plugin->rel_file(
  'lib/TestPlugin.pm'),
  'class exists';
ok -e $plugin->rel_file('t/test_plugin.t'), 'test exists';

chdir $cwd;

done_testing();

