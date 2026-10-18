const {test}=require('node:test');const assert=require('node:assert/strict');const fs=require('node:fs');const path=require('node:path');const source=require('./support/read-dart-library.cjs')(path.join(__dirname,'../../lib/main.dart'));
for(const [start,end] of [['class _AutoSizeVideoState','class _PickedVideoTile'],['class _VideoSlideWidgetState','class SimpleFullscreenVideoViewer'],['  Future<void> _initSignedVideoAt','  Future<void> _initVideoAt']])test(start+' streams without awaiting complete download',()=>{const a=source.indexOf(start),b=source.indexOf(end,a+start.length);assert.ok(a>=0&&b>a);const body=source.slice(a,b);assert.doesNotMatch(body,/getSingleFile/);assert.match(body,/createVideoPlaybackController/);assert.match(body,/_readAuthorizedPostData/);assert.ok(body.indexOf('await initializeVideoPlayback(controller)')<body.indexOf('_readAuthorizedPostData'));});

test('late stream failures enable authorized retry in all three consumers',()=>{
 for(const [start,end] of [['class _AutoSizeVideoState','class _PickedVideoTile'],['class _VideoSlideWidgetState','class SimpleFullscreenVideoViewer'],['  Future<void> _initSignedVideoAt','  Future<void> _initVideoAt']]) {
  const a=source.indexOf(start),b=source.indexOf(end,a+start.length),body=source.slice(a,b);
  assert.match(body,/observeVideoPlaybackError/);
  assert.match(body,/identical\(/);
 }
 const pager=source.slice(source.indexOf('  Future<void> _initSignedVideoAt'),source.indexOf('  Future<void> _initVideoAt',source.indexOf('  Future<void> _initSignedVideoAt')));
 assert.match(pager,/_dropVideo\(index\)/);
 assert.match(pager,/_signedVideoErrors\.add\(index\)/);
});

test('fullscreen byte caching starts after native buffering and never blocks playback',()=>{
 const a=source.indexOf('  Future<void> _initSignedVideoAt');
 const pager=source.slice(a,source.indexOf('  Future<void> _initVideoAt',a));
 assert.match(pager,/await createAuthorizedCachedVideo/);
 assert.match(pager,/unawaited\(cacheAuthorizedVideo/);
 assert.ok(pager.indexOf('await initializeVideoPlayback(controller)')<pager.indexOf('unawaited(cacheAuthorizedVideo'));
 const cache=fs.readFileSync(path.join(__dirname,'../../lib/services/authorized_video_cache.dart'),'utf8');
 const startup=cache.slice(cache.indexOf('Future<VideoPlayerController> createAuthorizedCachedVideo'),cache.indexOf('/// Call unawaited'));
 assert.match(startup,/createVideoPlaybackController\(file\?\.path \?\? signedUrl\)/);
 assert.doesNotMatch(startup,/download|\.warm\(/);
});
