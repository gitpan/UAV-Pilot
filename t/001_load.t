use Test::More tests => 21;
use v5.14;

my $is_sdl_installed = do {
    eval "use SDL ()";
    $@ ? 0 : 1;
};

use_ok( 'UAV::Pilot' );
use_ok( 'UAV::Pilot::Exceptions' );
use_ok( 'UAV::Pilot::Driver' );
use_ok( 'UAV::Pilot::Driver::ARDrone' );
use_ok( 'UAV::Pilot::Driver::ARDrone::NavPacket' );
use_ok( 'UAV::Pilot::Driver::ARDrone::Mock' );
use_ok( 'UAV::Pilot::Driver::ARDrone::Video' );
use_ok( 'UAV::Pilot::Driver::ARDrone::Video::Mock' );
use_ok( 'UAV::Pilot::Driver::ARDrone::VideoHandler' );
use_ok( 'UAV::Pilot::Control' );
use_ok( 'UAV::Pilot::Control::ARDrone' );
use_ok( 'UAV::Pilot::Control::ARDrone::Event' );
use_ok( 'UAV::Pilot::Control::ARDrone::Video::FileDump' );
use_ok( 'UAV::Pilot::Commands' );
use_ok( 'UAV::Pilot::EasyEvent' );
use_ok( 'UAV::Pilot::SDL::NavFeeder' ); # OK to do this one without SDL installed
use_ok( 'UAV::Pilot::SDL::JoystickConverter' ); # This is OK, too

SKIP: {
    skip "SDL not installed", 4 unless $is_sdl_installed;
    use_ok( 'UAV::Pilot::Control::ARDrone::SDLNavOutput' );
    use_ok( 'UAV::Pilot::SDL::EventHandler' );
    use_ok( 'UAV::Pilot::SDL::Joystick' );
    use_ok( 'UAV::Pilot::SDL::Events' );
}