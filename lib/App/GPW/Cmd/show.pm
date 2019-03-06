package MeetingWarrior::Cmd::show;

# ABSTRACT: add meeting to MeetingWarrior

use v5.22;

use Mojo::Base 'Mojolicious::Command', -signatures;
use Try::Tiny;

sub run ($self, @args) {
    my $app     = $self->app;
    my $meeting = shift @args;

    $meeting = $app->context->{meeting} if !$meeting;

    my $error;
    try {
        $app->mw->model->insert('meeting', {
            name      => $meeting,
            date_from => $from,
            date_to   => $to,
        });
    }
    catch {
        $error = $_;
        $app->log->warn( "Cannot add meeting: $_" );
    };

    return 0 if $error;
    return 1;
}

1;
