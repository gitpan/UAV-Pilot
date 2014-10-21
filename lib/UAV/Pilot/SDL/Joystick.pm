package UAV::Pilot::SDL::Joystick;
use v5.14;
use Moose;
use namespace::autoclean;
use SDL;
use SDL::Joystick;
use File::HomeDir;
use YAML ();

SDL::init_sub_system( SDL_INIT_JOYSTICK );

use constant MAX_AXIS_INT      => 32767;
use constant TIMER_INTERVAL    => 1 / 60;
use constant DEFAULT_CONF_FILE => 'sdl_joystick.yml';
use constant DEFAULT_CONF      => {
    joystick_num        => 0,
    roll_axis           => 0,
    pitch_axis          => 1,
    yaw_axis            => 2,
    throttle_axis       => 3,
    takeoff_btn         => 0,
    roll_correction     => 1,
    pitch_correction    => 1,
    yaw_correction      => 1,
    throttle_correction => -1,
    btn_action_map      => {
        0 => 'takeoff_land',
        1 => 'flip_left',
        2 => 'flip_right',
    },
};
use constant BUTTON_ACTIONS => {
    # "takeoff_land" is handled as a special case, since we need to toggle between them
    #
    # 'action_name' => '$control->method_name',
    emergency   => 'emergency',
    wave        => 'wave',
    flip_ahead  => 'flip_ahead',
    flip_behind => 'flip_behind',
    flip_left   => 'flip_left',
    flip_right  => 'flip_right',
};


with 'UAV::Pilot::SDL::EventHandler';

has 'condvar' => (
    is  => 'ro',
    isa => 'AnyEvent::CondVar',
);
has 'joystick_num' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'roll_axis' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
);
has 'pitch_axis' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1,
);
has 'yaw_axis' => (
    is      => 'ro',
    isa     => 'Int',
    default => 2,
);
has 'throttle_axis' => (
    is      => 'ro',
    isa     => 'Int',
    default => 3,
);
has 'roll_correction' => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);
has 'pitch_correction' => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);
has 'yaw_correction' => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);
has 'throttle_correction' => (
    is      => 'ro',
    isa     => 'Num',
    default => -1,
);
has 'takeoff_btn' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0, 
);
has 'is_in_air' => (
    traits  => ['Bool'],
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
    handles => {
        toggle_is_in_air => 'toggle',
        set_is_in_air    => 'set',
        unset_is_in_air  => 'unset',
    },
);
has 'controller' => (
    is  => 'ro',
    isa => 'UAV::Pilot::Control',
);
has 'joystick' => (
    is  => 'ro',
    isa => 'SDL::Joystick',
);
has '_prev_takeoff_btn_status' => (
    is  => 'rw',
    isa => 'Bool',
);
has 'btn_action_map' => (
    is      => 'ro',
    isa     => 'HashRef[Str]',
    default => sub {{}},
);
has '_btn_prev_state' => (
    is      => 'rw',
    isa     => 'HashRef[Bool]',
    default => sub {{}},
);


sub BUILDARGS
{
    my ($self, $args) = @_;
    my $new_args = $self->_process_args( $args );

    my $joystick = SDL::Joystick->new( $new_args->{joystick_num} );
    die "Could not open joystick $$new_args{joystick_num}\n" unless $joystick;
    $new_args->{joystick} = $joystick;

    return $new_args;
}


sub process_events
{
    my ($self) = @_;
    SDL::Joystick::update();
    my $joystick = $self->joystick;
    my $dev = $self->controller;

    my $roll = $dev->convert_sdl_input( $joystick->get_axis(
        $self->roll_axis ) * $self->roll_correction );
    my $pitch = $dev->convert_sdl_input( $joystick->get_axis(
        $self->pitch_axis ) * $self->pitch_correction );
    my $yaw = $dev->convert_sdl_input( $joystick->get_axis(
        $self->yaw_axis ) * $self->yaw_correction );
    my $throttle = $dev->convert_sdl_input( $joystick->get_axis(
        $self->throttle_axis ) * $self->throttle_correction );
    my $takeoff_btn = $joystick->get_button( $self->takeoff_btn );

    # Only takeoff/land after we let off the button
    if( $self->_prev_takeoff_btn_status && ($takeoff_btn == 0) ) {
        if( $self->is_in_air ) {
            $self->unset_is_in_air;
            $dev->land;
        }
        else {
            $self->set_is_in_air;
            $dev->takeoff;
        }
    }
    $self->_prev_takeoff_btn_status( $takeoff_btn );

    $self->_process_action_buttons( $joystick, $dev );

    $dev->roll( $roll );
    $dev->pitch( $pitch );
    $dev->yaw( $yaw );
    $dev->vert_speed( $throttle );

    return 1;
}

sub close
{
    my ($self) = @_;
    #$self->joystick->close;
    return 1;
}


sub _process_args
{
    my ($self, $args) = @_;
    my $conf_path = defined $args->{conf_path}
        ? $args->{conf_path}
        : do {
            my $conf_dir = UAV::Pilot->default_config_dir;
            my $conf_path = File::Spec->catfile( $conf_dir, $self->DEFAULT_CONF_FILE );
            YAML::DumpFile( $conf_path, $self->DEFAULT_CONF ) unless -e $conf_path;
            $conf_path;
        };
    UAV::Pilot::FileNotFoundException->throw({
        file  => $conf_path,
        error => "Could not find file $conf_path",
    }) unless -e $conf_path;
    my $conf_args = YAML::LoadFile( $conf_path );

    # Get the takeoff_land button special case
    foreach my $key (keys %{ $conf_args->{btn_action_map} }) {
        my $value = $conf_args->{btn_action_map}{$key};
        if( $value eq 'takeoff_land' ) {
            $conf_args->{takeoff_btn} = $key;
            delete $conf_args->{btn_action_map}{$key};
            last;
        }
    }

    my %new_args = (
        %$conf_args,
        condvar      => $args->{condvar},
        controller   => $args->{controller},
    );
    return \%new_args;
}

sub _process_action_buttons
{
    my ($self, $joystick, $dev) = @_;

    foreach my $btn (keys %{ $self->btn_action_map }) {
        my $cur_state = $joystick->get_button( $btn );
        # Only perform the action after we let off the button
        if( $self->_btn_prev_state->{$btn} && ($cur_state == 0) ) {
            my $action = $self->btn_action_map->{$btn};
            next unless exists $self->BUTTON_ACTIONS->{$action};
            my $method = $self->BUTTON_ACTIONS->{$action};
            $dev->$method;
        }

        $self->_btn_prev_state->{$btn} = $cur_state;
    }

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

    UAV::Pilot::SDL::Joystick

=head1 SYNOPSIS

    my $control = UAV::Pilot::Controller::ARDrone->new( ... );
    my $condvar = AnyEvent->condvar;
    my $joy = UAV::Pilot::SDL::Joystick->new({
        condvar    => $condvar,
        controller => $control,
        conf_path  => '/path/to/config.yml', # optional
    });
    
    my $sdl_events = UAV::Pilot::SDL::Events->new({
        condvar    => $condvar,
        controller => $control,
    });
    $sdl_events->register( $joy );

=head1 DESCRIPTION

Handles joystick control for SDL joysticks.  This does the role 
C<UAV::Pilot::SDL::EventHandler>, so it can be passed to 
C<<UAV::Pilot::SDL::Events->register()>>.

Joystick configuration will be loaded from a C<YAML> config file.  You can find the 
path with C<<UAV::Pilot->default_config_dir()>>.  If the file does not exist, it will 
be created automatically.

=head1 CONFIGURATION FILE

The config file is in C<YAML> format.  It contains the following keys:

=head2 joystick_num

The SDL joystick number to use

=head2 pitch_axis

Axis number of joystick to use for pitch.

=head2 roll_axis

Axis number of joystick to use for roll.

=head2 yaw_axis

Axis number of joystick to use for yaw.

=head2 throttle_axis

Axis number of joystick to use for throttle.

=head2 btn_action_map

This is a mapping of button numbers to some kind of action, such as takeoff/land or flip.  
The format is "btn_num: action".  Actions are:

=over 4

=item * takeoff_land

=item * emergency

=item * wave

=item * flip_ahead

=item * flip_behind

=item * flip_left

=item * flip_right

=back

=head2 Axis Corrections

These can be used to cut the inputs by a percentage.  All should be numbers between 1.0 and 
-1.0, with negative numbers reversing the axis.

=head3 roll_correction

=head3 pitch_correcton

=head3 yaw_correction

=head3 throttle_correction

=cut
