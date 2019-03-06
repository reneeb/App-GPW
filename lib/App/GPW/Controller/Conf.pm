package App::GPW::Controller::Conf;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;

sub list ($c) {
    my $confs = $c->gpw->list;

    $c->stash( confs => $confs );
    return $c->render( 'index' );
}

sub add ($c) {
    my $year = $c->param('year');

    my $app = $c->app;
    my $success = $app->commands->run('add', $year);

    return $c->reply->exception if !$success;
    return $c->redirect_to( $c->url_for('conf-list') );
}

sub detail ($c) {
    my $year = $c->param('year');

    my $app = $c->app;
    $app->log->debug( "Get $year workshop" );

    my $error;
    try {
        my $info = $app->gpw->info( $year );
        $c->stash( info => $info );
    }
    catch {
        $error = $_;
        $app->log->warn( "Cannot get info about $year: $_" );
        $c->reply->exception;
    };

    return if $error;
    return $c->render( 'detail' );
}

sub talk ($c) {
    my $year = $c->param('year');
    my $talk = $c->param('talk-id');

    if ( $year !~ m{\A[0-9]{4}\z} || $year < 1999 || $year > 2099 ) {
        return $c->reply->exception;
    }

    if ( $talk !~ m{\A[0-9]+\z} ) {
        return $c->reply->exception;
    }

    my $app = $c->app;
    $app->log->debug( "Show talk ($talk/$year)" );

    my $error;
    try {
        $app->gpw->talk( $talk, $year );
    }
    catch {
        $error = $_;
        $app->log->warn( "Cannot get talk details: $_" );
        $c->reply->exception;
    };

    return if $error;
    return $c->render( 'talk' );
}

1;
