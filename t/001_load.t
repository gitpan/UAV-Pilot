use Test::More tests => 42;
use v5.14;

my $is_sdl_installed = do {
    eval "use SDL ()";
    $@ ? 0 : 1;
};
my $is_rpi_installed = do {
    eval "use HiPi ()";
    $@ ? 0 : 1;
};

use_ok( 'UAV::Pilot' );
use_ok( 'UAV::Pilot::Exceptions' );
use_ok( 'UAV::Pilot::Driver' );
use_ok( 'UAV::Pilot::ARDrone::Driver' );
use_ok( 'UAV::Pilot::ARDrone::NavPacket' );
use_ok( 'UAV::Pilot::ARDrone::Driver::Mock' );
use_ok( 'UAV::Pilot::ARDrone::Video' );
use_ok( 'UAV::Pilot::ARDrone::Video::Mock' );
use_ok( 'UAV::Pilot::Control' );
use_ok( 'UAV::Pilot::ControlHelicopter' );
use_ok( 'UAV::Pilot::ControlRover' );
use_ok( 'UAV::Pilot::Server' );
use_ok( 'UAV::Pilot::ARDrone::Control' );
use_ok( 'UAV::Pilot::ARDrone::Control' );
use_ok( 'UAV::Pilot::ARDrone::Control::Event' );
use_ok( 'UAV::Pilot::Commands' );
use_ok( 'UAV::Pilot::EasyEvent' );
use_ok( 'UAV::Pilot::EventHandler' );
use_ok( 'UAV::Pilot::Events' );
use_ok( 'UAV::Pilot::NavCollector' );
use_ok( 'UAV::Pilot::NavCollector::AckEvents' );
use_ok( 'UAV::Pilot::SDL::NavFeeder' ); # OK to do this one without SDL installed
use_ok( 'UAV::Pilot::SDL::Joystick' ); # Needs to be OK to do this one, too
use_ok( 'UAV::Pilot::Video::H264Handler' );
use_ok( 'UAV::Pilot::Video::FileDump' );
use_ok( 'UAV::Pilot::Video::RawHandler' );
use_ok( 'UAV::Pilot::Video::H264Decoder' );
use_ok( 'UAV::Pilot::Video::Mock::RawHandler' );
use_ok( 'UAV::Pilot::ControlRover' );
use_ok( 'UAV::Pilot::WumpusRover' );
use_ok( 'UAV::Pilot::WumpusRover::Driver' );
use_ok( 'UAV::Pilot::WumpusRover::Packet' );
use_ok( 'UAV::Pilot::WumpusRover::PacketFactory' );
use_ok( 'UAV::Pilot::WumpusRover::Server' );
use_ok( 'UAV::Pilot::WumpusRover::Control' );
use_ok( 'UAV::Pilot::WumpusRover::Control::Event' );

SKIP: {
    skip "SDL not installed", 6 unless $is_sdl_installed;
    use_ok( 'UAV::Pilot::ARDrone::SDLNavOutput' );
    use_ok( 'UAV::Pilot::SDL::Video' );
    use_ok( 'UAV::Pilot::SDL::VideoOverlay' );
    use_ok( 'UAV::Pilot::SDL::VideoOverlay::Reticle' );
    use_ok( 'UAV::Pilot::SDL::Window' );
}

SKIP: {
    skip "Raspberry Pi modules not installed", 1 unless $is_rpi_installed;
    use_ok( 'UAV::Pilot::WumpusRover::Server::Backend::RaspberryPiI2C' );
}
