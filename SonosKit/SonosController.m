//
//  SonosController.m
//  SonosKit
//
//  Created by Nathan Borror on 12/31/12.
//  Copyright (c) 2012 Nathan Borror. All rights reserved.
//

#import "SonosController.h"
#import "SonosConnection.h"
#import "XMLReader.h"

@implementation SonosController {
  NSInteger _volumeLevel;
  NSMutableArray *_slaves;
}

- (instancetype)initWithIP:(NSString *)ip
{
  if (self = [super init]) {
    _volumeLevel = 0;
    _ip = ip;
    _slaves = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)request:(SonosRequestType)type action:(NSString *)action params:(NSDictionary *)params completion:(void (^)(id, NSError *))block
{
  NSURL *url;
  NSString *ns;

  switch (type) {
    case SonosRequestTypeAVTransport:
      // http://SPEAKER_IP:1400/xml/AVTransport1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/MediaRenderer/AVTransport/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:AVTransport:1";
      break;
    case SonosRequestTypeConnectionManager:
      // http://SPEAKER_IP:1400/xml/ConnectionManager1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/MediaServer/ConnectionManager/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:ConnectionManager:1";
      break;
    case SonosRequestTypeRenderingControl:
      // http://SPEAKER_IP:1400/xml/RenderingControl1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/MediaRenderer/RenderingControl/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:RenderingControl:1";
      break;
    case SonosRequestTypeContentDirectory:
      // http://SPEAKER_IP:1400/xml/ContentDirectory1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/MediaServer/ContentDirectory/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:ContentDirectory:1";
      break;
    case SonosRequestTypeQueue:
      // http://SPEAKER_IP:1400/xml/Queue1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/MediaRenderer/Queue/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:Queue:1";
      break;
    case SonosRequestTypeAlarmClock:
      // http://SPEAKER_IP:1400/xml/AlarmClock1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/AlarmClock/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:AlarmClock:1";
      break;
    case SonosRequestTypeMusicServices:
      // http://SPEAKER_IP:1400/xml/MusicServices1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/MusicServices/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:MusicServices:1";
      break;
    case SonosRequestTypeAudioIn:
      // http://SPEAKER_IP:1400/xml/AudioIn1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/AudioIn/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:AudioIn:1";
      break;
    case SonosRequestTypeDeviceProperties:
      // http://SPEAKER_IP:1400/xml/DeviceProperties1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/DeviceProperties/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:DeviceProperties:1";
      break;
    case SonosRequestTypeSystemProperties:
      // http://SPEAKER_IP:1400/xml/SystemProperties1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/SystemProperties/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:SystemProperties:1";
      break;
    case SonosRequestTypeZoneGroupTopology:
      // http://SPEAKER_IP:1400/xml/ZoneGroupTopology1.xml
      url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:1400/ZoneGroupTopology/Control", _ip]];
      ns = @"urn:schemas-upnp-org:service:ZoneGroupTopology:1";
      break;
    case SonosRequestTypeGroupManagement:
      break;
  }

  NSMutableString *requestParams = [[NSMutableString alloc] init];
  NSEnumerator *enumerator = [params keyEnumerator];
  NSString *key;
  while (key = [enumerator nextObject]) {
    requestParams = [NSMutableString stringWithFormat:@"<%@>%@</%@>%@", key, [params objectForKey:key], key, requestParams];
  }

  NSString *requestBody = [NSString stringWithFormat:@""
    "<s:Envelope xmlns:s='http://schemas.xmlsoap.org/soap/envelope/' s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>"
      "<s:Body>"
        "<u:%@ xmlns:u='%@'>%@</u:%@>"
      "</s:Body>"
    "</s:Envelope>", action, ns, requestParams, action];

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"POST"];
  [request addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
  [request addValue:[NSString stringWithFormat:@"%@#%@", ns, action] forHTTPHeaderField:@"SOAPACTION"];
  [request setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];

  SonosConnection *connection = [[SonosConnection alloc] initWithRequest:request completion:block];
  [connection start];
}

- (void)play:(NSString *)uri completion:(void (^)(NSDictionary *, NSError *))block
{
  if (uri) {
    NSDictionary *params = @{@"InstanceID": @0, @"CurrentURI":uri, @"CurrentURIMetaData": @""};
    [self request:SonosRequestTypeAVTransport action:@"SetAVTransportURI" params:params completion:^(id obj, NSError *error) {
      [self play:nil completion:block];
    }];
  } else {
    NSDictionary *params = @{@"InstanceID": @0, @"Speed":@1};
    [self request:SonosRequestTypeAVTransport action:@"Play" params:params completion:^(id obj, NSError *error) {
      if (block) block(obj, error);
    }];
  }
}

- (void)playbackStatus:(void (^)(BOOL, NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"InstanceID": @0};
  [self request:SonosRequestTypeAVTransport action:@"GetTransportInfo" params:params completion:^(NSDictionary *response, NSError *error) {
    if (error) {
      block(NO, nil, error);
    }

    if ([response[@"CurrentTransportState"] isEqualToString:@"PLAYING"]) {
      block(YES, response, nil);
    }

    block(NO, response, nil);
  }];
}

- (void)pause:(void (^)(NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"InstanceID": @0, @"Speed": @1};
  [self request:SonosRequestTypeAVTransport action:@"Pause" params:params completion:^(id obj, NSError *error) {
    if (block) block(obj, error);
  }];
}

- (void)stop:(void (^)(NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"InstanceID": @0, @"Speed": @1};
  [self request:SonosRequestTypeAVTransport action:@"Stop" params:params completion:^(id obj, NSError *error) {
    if (block) block(obj, error);
  }];
}

- (void)next:(void (^)(NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"InstanceID": @0, @"Speed": @1};
  [self request:SonosRequestTypeAVTransport action:@"Next" params:params completion:^(id obj, NSError *error) {
    if (block) block(obj, error);
  }];
}

- (void)previous:(void (^)(NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"InstanceID": @0, @"Speed": @1};
  [self request:SonosRequestTypeAVTransport action:@"Previous" params:params completion:^(id obj, NSError *error) {
    if (block) block(obj, error);
  }];
}

- (void)queue:(NSString *)track completion:(void (^)(NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"InstanceID": @0,
                           @"EnqueuedURI": track,
                           @"EnqueuedURIMetaData": @"",
                           @"DesiredFirstTrackNumberEnqueued": @0,
                           @"EnqueueAsNext": @1};
  [self request:SonosRequestTypeAVTransport action:@"AddURIToQueue" params:params completion:^(id obj, NSError *error) {
    [self play:nil completion:block];
  }];
}

- (void)lineIn:(void (^)(NSDictionary *, NSError *))block
{
  [self play:[NSString stringWithFormat:@"x-rincon-stream:%@", _uuid] completion:block];
}

- (void)getVolume:(void (^)(NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"InstanceID": @0, @"Channel":@"Master"};
  [self request:SonosRequestTypeRenderingControl action:@"GetVolume" params:params completion:block];
}

- (void)setVolume:(int)level completion:(void (^)(NSDictionary *, NSError *))block
{
  // This helps throttle requests so we're not flodding the speaker.
  if (_volumeLevel == level) return;

  NSDictionary *params = @{@"InstanceID": @0, @"Channel":@"Master", @"DesiredVolume":[NSNumber numberWithInt:level]};
  [self request:SonosRequestTypeRenderingControl action:@"SetVolume" params:params completion:^(id obj, NSError *error) {
    _volumeLevel = level;
    if (block) block(obj, error);
  }];
}

- (void)trackInfo:(void (^)(NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"InstanceID": @0};
  [self request:SonosRequestTypeAVTransport action:@"GetPositionInfo" params:params completion:block];
}

- (void)mediaInfo:(void (^)(NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"InstanceID": @0};
  [self request:SonosRequestTypeAVTransport action:@"GetMediaInfo" params:params completion:block];
}

- (void)status:(void (^)(NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"InstanceID": @0};
  [self request:SonosRequestTypeAVTransport action:@"GetTransportInfo" params:params completion:block];
}

- (void)browse:(void (^)(NSDictionary *, NSError *))block
{
  NSDictionary *params = @{@"ObjectID": @"A:ARTIST",
                           @"BrowseFlag": @"BrowseDirectChildren",
                           @"Filter": @"*",
                           @"StartingIndex": @0,
                           @"RequestedCount": @5,
                           @"SortCriteria": @"*"};
  [self request:SonosRequestTypeContentDirectory action:@"Browse" params:params completion:block];
}

- (NSArray *)slaves
{
  return (NSArray *)[_slaves copy];
}

- (void)addSlave:(SonosController *)slave
{
  [_slaves addObject:slave];
}

@end