package App::GPW::Plugin::Utils;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Mojo::File qw(path);
use Mojo::JSON qw(encode_json decode_json);
use Mojo::UserAgent;

use Carp;
use Config::Tiny;
use File::HomeDir;

has base_url   => sub { 'https://act.yapc.eu/' };
has github_url => sub { 'https://raw.githubusercontent.com/Act-Conferences/' };
has conference => sub { 'gpw' };
has talks_path => sub { '/talks' };
has talk_path  => sub { '/talk' };

sub register ( $self, $app, $config ) {
    for my $attr ( qw(base_url github_url conference talks_path talk_path) ) {
        next if !$config->{$attr};
        $self->$attr( $config->{$attr} );
    }

    $app->helper( 'gpw.directory' => sub { $self->_directory( @_ ); } );
    $app->helper( 'gpw.workshop'  => sub { $self->_new_workshop( @_ ); } );
    $app->helper( 'gpw.list'      => sub { $self->_list( @_ ); } );
    $app->helper( 'gpw.info'      => sub { $self->_info( @_ ); } );
    $app->helper( 'gpw.act_info'  => sub { } );
}

sub _info ( $self, $c, $year ) {
    my $dir  = $self->_directory( $c, $year );
    my $info = decode_json( $dir->child( 'conference.json' )->slurp );

    my $talks = $dir->list({ dir => 1 })
                    ->grep( sub { -d $_->to_string } )
                    ->map( sub{ $_->basename } )
                    ->to_array;
    $info->{talks} = $talks;

    return $info; 
}

sub _list ( $self, $c ) {
    my $dir = $self->_directory( $c );

    my $list = $dir->list({ dir => 1 })->grep( sub { -d $_->to_string } );
    return $list;
}

sub _directory ( $self, $c, $year = '' ) {
    return if !$c;

    my $directory = path(
        $c->app->config->{home_dir} // File::HomeDir->my_home
    )->child( $self->conference );

    return $directory if !$year;

    if ( $year !~ m{\A[0-9]{4}\z} || $year < 1999 || $year > 2099 ) {
        croak 'invalid year: ' . $year;
    }

    my $year_dir = $directory->child( $year );

    if ( !-d $year_dir->to_string ) {
        $c->app->log->debug( "Create directory for $year" );
        $year_dir->make_path;
    }

    return $year_dir;
}

sub _new_workshop ( $self, $c, $year ) {
    my $app  = $c->app;

    if ( $year !~ m{\A[0-9]{4}\z} || $year < 1999 || $year > 2099 ) {
        croak 'invalid year: ' . $year;
    }

    $self->_download_talk_info( $c, $year );
    $self->_get_act_info_from_github( $c, $year );

    return 1;
}

sub _get_act_info_from_github ($self, $c, $year ) {

    # download config
    my $url = sprintf "%s%s%s/master/actdocs/conf/act.ini", $self->github_url, $self->conference, $year;

    my $app = $c->app;
    $app->log->debug( "Get event info from github" );
    $app->log->debug( "URL: $url" );

    $app->ua->get(
        $url => {} => sub {
            my ($ua, $tx) = @_;

            return if $tx->res->is_error;

            # parse config file
            my ($config) = Config::Tiny->read_string( $tx->res->body );

            # get name, start, end
            my %info = (
                name  => $config->{general}->{name_de},
                start => $config->{talks}->{start_date},
                end   => $config->{talks}->{end_date},
            );

            $app->log->debug( $c->dumper( \%info ) );

            # save info as json file
            $self->_directory( $c, $year )->child( 'conference.json' )->spurt(
                encode_json \%info
            );
        },
    );

    return 1;
}

sub _download_talk_info ($self, $c, $year) {

    # download list of talks
    my $base     = sprintf "%s%s%s", $self->base_url, $self->conference, $year;
    my $url      = sprintf "%s%s", $base, $self->talks_path;
    my $talk_url = sprintf "%s%s", $base, $self->talk_path;

    my $app = $c->app;
    $app->log->debug( "Get list of talks..." );

    my $directory     = $self->_directory( $c, $year );
    my $talks_dir     = $directory->child('talks');
    my $href_selector = sprintf "/%s%s", $self->conference, $year;
    $app->log->debug( "Selector: $href_selector" );

    my $tx = $app->ua->get( $url );

    return if $tx->res->is_error;

    $tx->res->dom->find('td > a[href^="' . $href_selector . '/talk"]')->map( sub {
        $_->attr('href'),
    })->each( sub {
        my ($id) = $_ =~ m{talk/([0-9]+)};

        my $talk_dir = $talks_dir->child( $id )->make_path;
        $app->log->debug( "Get talk $id..." );
        $app->ua->get(
            $base . '/talk/' . $id => {} => sub {
                my ($ua, $tx) = @_;

                return if $tx->res->is_error;

                my $dom = $tx->res->dom;
                my %info = (
                    summary  => $dom->find('h2[itemprop="summary"]')->first->text,
                    abstract => $dom->find('#talk_abstract')->first->text,
                    speaker  => $dom->find('#talk_by > a')->first->text,
                );

                $talk_dir->child('info.json')->spurt( encode_json( \%info ) );
            }
        );
    });

    return 1;
}

1;
