package App::GPW::Cmd::add;

# ABSTRACT: add workshop to App::GPW

use v5.22;

use Mojo::Base 'Mojolicious::Command', -signatures;
use Try::Tiny;

our $VERSION = '0.01';

has description => 'Adds a new workshop and its information';

sub run ($self, @args) {
    my $app  = $self->app;
    my $year = shift @args;

    $app->log->debug( "Add $year workshop" );

    my $error;
    try {
        $app->gpw->workshop( $year );
    }
    catch {
        $error = $_;
        $app->log->warn( "Cannot add gpw: $_" );
    };

    return 0 if $error;
    return 1;
}

1;

=head1 SYNOPSIS

    $ gpw add 2019

=head1 METHODS

=head2 run

__END__

gpw add 2019
gpw context 2019
gpw show
gpw show_talk
