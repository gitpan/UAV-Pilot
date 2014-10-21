#!/usr/bin/perl
use v5.14;
use warnings;
use AnyEvent;
use Glib qw( TRUE FALSE );
use EV::Glib;
use EV;
use GStreamer;
use UAV::Pilot::Events;
use UAV::Pilot::Video::H264Decoder;
use UAV::Pilot::SDL::Events;
use UAV::Pilot::SDL::Window;
use UAV::Pilot::SDL::Video;


my $INPUT_FILE  = shift || die "Need input file\n";


sub bus_callback
{
    my ($bus, $msg, $loop) = @_;

    if( $msg->type & "error" ) {
        warn $msg->error;
        $loop->quit;
    }
    elsif( $msg->type & "eos" ) {
        warn "End of stream, quitting\n";
        $loop->quit;
    }

    return TRUE;
}

sub dump_file_callback
{
    my ($fakesink, $buf, $pad, $user_data) = @_;
    my $handler = $user_data->{handler};
    state $called = 0;

    warn "Calling dump_file_callback, call count: $called\n";
    $called++;

    warn "Buffer size: " . $buf->size . "\n";
    $handler->process_h264_frame( $buf->data,
        640, 360, 640, 360,
        # TODO fill in width/height params that we get from GStreamer
        #$display_width, $display_height, $encoded_width, $encoded_height
    );

    return 1;
}

sub setup_video_output
{
    my ($cv) = @_;

    my $window = UAV::Pilot::SDL::Window->new;

    my $vid_display = UAV::Pilot::SDL::Video->new;
    my $h264_handler = UAV::Pilot::Video::H264Decoder->new({
        displays => [ $vid_display ],
    });
    $vid_display->add_to_window( $window );

    my $sdl_events = UAV::Pilot::SDL::Events->new;
    my $events = UAV::Pilot::Events->new({
        condvar => $cv,
    });
    $events->register( $_ ) for $sdl_events, $window;
    $events->init_event_loop;

    return $h264_handler;
}


{
    my $cv = AnyEvent->condvar;

    GStreamer->init();
    my $loop = Glib::MainLoop->new( undef, FALSE );

    my $pipeline = GStreamer::Pipeline->new( 'pipeline' );
    my ($filesrc, $gdpdepay, $h264parse, $fakesink) =
        GStreamer::ElementFactory->make(
            filesrc   => 'and_who_are_you',
            gdpdepay  => 'the_proud_lord_said',
            h264parse => 'that_i_should_bow_so_low',
            fakesink  => 'only_a_cat_of_a_different_coat',
        );

    $filesrc->set(
        location => $INPUT_FILE,
    );

    $fakesink->set(
        'signal-handoffs' => TRUE,
    );
    my ($h264_handler) = setup_video_output( $cv );
    $fakesink->signal_connect(
        'handoff' => \&dump_file_callback,
        {
            handler => $h264_handler,
        },
    );

    $pipeline->add( $filesrc, $gdpdepay, $h264parse, $fakesink );
    $filesrc->link( $gdpdepay, $h264parse, $fakesink );

    $pipeline->get_bus->add_watch( \&bus_callback, $loop );

    $pipeline->set_state( 'playing' );
    #$loop->run;
    $cv->recv;

    # Cleanup
    $pipeline->set_state( 'null' );
}
