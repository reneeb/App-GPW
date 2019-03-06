package App::GPW;

# ABSTRACT: Module/App to manage all the gpw stuff

use Mojo::Base 'Mojolicious', -strict;

our $VERSION = '0.01';

sub startup {
    my $app = shift;
    $app->plugin( JSONConfig => {
        file => $ENV{GPW_JSON_CONFIG} // $app->home->child('conf', 'gpw.json'),
    });

    $app->plugins->namespaces(['App::GPW::Plugin']);
    $app->commands->namespaces(['App::GPW::Cmd']);

    $app->plugin( 'Utils' );

    my $r = $app->routes;
    $r->get('/')->to( 'conf#list' )->name('conf-list');
    $r->post('/new-conf')->to('conf#add')->name('conf-new');
    $r->get('/conf/:year')->to('conf#detail')->name('conf-detail');
    $r->get('/conf/:year/:talk-id')->to('conf#talk')->name('conf-talk');
}

1;

=head1 DESCRIPTION

This is a simple app that collects all information about a German Perl-Workshop.

It downloads the talk information from Act! and - if available - the slides and
the videos. It creates a directory tree that looks like this:

  /gpw
    + 2019
    |   + ...
    + 2018
    |   + ...
    + 2017
    |   + talks
    |       + <id>
    |           + info.json
    |           + slides
    |           + videos
    |   + talks.json
    |   + gpw.json

It uses

=head1 UI

C<App::GPW> provides two UIs:

=over 4

=item * CLI

There is a commandline tool called C<gpw>.

=item * Web

You can start C<gpw-web> to get the web UI.

=back

=head1 COMMANDS

The commandline tool provides these commands

=over 4

=item * C<< gpw add <year> >>

Creates the directory tree as described above and downloads all available information.

=item * C<< gpw update <year> >>

=item * C<< gpw show <year> >>

=item * C<< gpw talks <year> >>

=item * C<< gpw talk <talk_id> >>

=back

=cut

