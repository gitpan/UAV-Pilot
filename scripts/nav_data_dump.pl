#!/usr/bin/perl
use v5.14;
use warnings;
use UAV::Pilot::ARDrone::NavPacket;


my $PACKET = pack 'H*',
'88776655f504800fb51700000100000000009400000003004c0000000000b8c20000dcc30030654616020000c73d86431d4143c300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000e53b7d3fd51816befe0733bb271d163e2f3a7d3fa356f13b01afd43a79dafbbbfafd7f3f65903544a9c4fec200808bc410004801000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffff0800e3230000';


my $packet = UAV::Pilot::ARDrone::NavPacket->new({
    packet => $PACKET,
});
say $packet->to_string;
